import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/models.dart';
import '../api/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'app_shell.dart';
import 'blocked_senders_screen.dart';
import 'inbox_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'static_screen.dart';
import 'supporters_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _user;
  bool _loading = true;
  String? _error;

  final _wordCtrl = TextEditingController();
  List<String> _hiddenWords = const [];
  bool _savingWords = false;
  int? _pauseUntil;
  bool _savingPause = false;
  bool _permanentPause = false;
  bool _claimingUsername = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiClient.getMe();
      if (!mounted) return;
      setState(() {
        _user = user;
        _hiddenWords = List.of(user.hiddenWords);
        final paused = user.pausedUntil;
        if (paused == -1) {
          _permanentPause = true;
          _pauseUntil = 1440;
        } else if (paused != null && paused > DateTime.now().millisecondsSinceEpoch ~/ 1000) {
          _pauseUntil = ((paused - DateTime.now().millisecondsSinceEpoch ~/ 1000) / 60).ceil();
        } else {
          _pauseUntil = null;
          _permanentPause = false;
        }
        _loading = false;
      });
    } on UnauthorizedError {
      if (!mounted) return;
      setState(() => _loading = false);
      _showLoggedOut();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your profile.';
      });
    }
  }

  Future<void> _showLoggedOut() async {
    await Session.clear();
    if (!mounted) return;
    showErrorSnack(context, 'Session expired. Please log in again.');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _saveWords() async {
    setState(() => _savingWords = true);
    try {
      await ApiClient.updateMe(hiddenWords: _hiddenWords);
      if (!mounted) return;
      setState(() => _savingWords = false);
      showErrorSnack(context, 'Word filter saved.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingWords = false);
      showErrorSnack(context, 'Could not save word filter.');
    }
  }

  Future<void> _applyPause() async {
    setState(() => _savingPause = true);
    try {
      if (_permanentPause) {
        await ApiClient.updateMe(pausedUntil: -1);
      } else if (_pauseUntil == null) {
        await ApiClient.updateMe(clearPause: true);
      } else {
        final seconds =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + _pauseUntil! * 60;
        await ApiClient.updateMe(pausedUntil: seconds);
      }
      if (!mounted) return;
      setState(() => _savingPause = false);
      showErrorSnack(context,
          _permanentPause ? 'Link paused permanently.' : (_pauseUntil == null ? 'Link re-activated.' : 'Link muted for $_pauseUntil minutes.'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingPause = false);
      showErrorSnack(context, 'Could not update your link.');
    }
  }

  Future<void> _copyLink() async {
    final u = _user;
    if (u == null) return;
    copyToClipboard(context, shareUrlFor(u.username), message: 'Your secret link copied');
  }

  Future<void> _claimUsername() async {
    final u = _user;
    if (u == null) return;
    final ctrl = TextEditingController(text: u.username);
    final claimed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick your custom username', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your supporter perk. Choose a clean handle without numbers — this replaces your link.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'yourname',
                prefixText: '@ ',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '4–30 lowercase letters, numbers, dashes, underscores, or dots.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim().toLowerCase()),
            child: const Text('Claim', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (claimed == null || claimed.isEmpty) return;
    if (!RegExp(r'^[a-z0-9_\-\.]{4,30}$').hasMatch(claimed)) {
      if (!mounted) return;
      showErrorSnack(context, 'Use 4–30 lowercase letters, numbers, dashes, underscores, or dots.');
      return;
    }
    setState(() => _claimingUsername = true);
    try {
      await ApiClient.setUsername(claimed);
      await _load();
      if (!mounted) return;
      showErrorSnack(context, 'Your custom link is live: secretmsg.net/$claimed');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _claimingUsername = false);
      showErrorSnack(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _claimingUsername = false);
      showErrorSnack(context, 'Could not update your username. Try again.');
    }
  }

  Future<void> _shareLink() async {
    final u = _user;
    if (u == null) return;
    await Share.share('Send me anonymous messages — ${shareUrlFor(u.username)}');
  }

  Future<void> _signOut() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete your account?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'This permanently wipes your account, username, inbox, and settings. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.roseLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiClient.deleteAccount();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      } catch (_) {
        if (!mounted) return;
        showErrorSnack(context, 'Could not delete account. Sign out and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'My SecretLink'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _buildError()
              : _user == null
                  ? _buildLoggedOut()
                  : _buildSettings(),
    );
  }

  /// Switches tabs when this screen is inside the shell, and falls back to a
  /// push when it is not.
  void _openTab(AppTab tab, Widget standalone) {
    final shell = AppShellScope.maybeOf(context);
    if (shell != null) {
      shell.switchTo(tab);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => standalone));
  }

  Future<void> _showPairCode() async {
    try {
      final res = await ApiClient.createPairCode();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _PairCodeDialog(code: res.code, expiresIn: res.expiresIn),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.roseLight)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
      ],
    );
  }

  Widget _buildLoggedOut() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not signed in.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Sign in to manage your secret link.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    final u = _user!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(user: u, onOpenInbox: () => _openTab(AppTab.inbox, const InboxScreen())),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Your SecretLink',
                    icon: Icons.link,
                    children: [
                      _ActionTile(
                        icon: Icons.copy,
                        label: 'Copy my link',
                        onTap: _copyLink,
                      ),
                      _ActionTile(
                        icon: Icons.ios_share,
                        label: 'Share my link',
                        onTap: _shareLink,
                      ),
                      if (u.customSlugUnlocked == 1) ...[
                        const Divider(color: AppColors.border, height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supporter perk — your username',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            _ActionTile(
                              icon: Icons.badge_outlined,
                              label: _claimingUsername
                                  ? 'Claiming…'
                                  : 'Custom username: ${u.username}',
                              onTap: _claimingUsername ? null : _claimUsername,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Inbox moderation',
                    icon: Icons.filter_alt_outlined,
                    children: [
                      _buildWordFilter(),
                      const Divider(color: AppColors.border, height: 24),
                      _buildPause(),
                      const Divider(color: AppColors.border, height: 24),
                      _ActionTile(
                        icon: Icons.block_outlined,
                        label: 'Blocked senders',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BlockedSendersScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Support & legal',
                    icon: Icons.card_membership,
                    children: [
                      _ActionTile(
                        icon: Icons.emoji_events_outlined,
                        label: 'Supporters wall',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportersScreen())),
                      ),
                      _ActionTile(
                        icon: Icons.article_outlined,
                        label: 'Terms & safety center',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaticScreen(keyOf: 'about'))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'View on web',
                    icon: Icons.devices_outlined,
                    children: [
                      const Text(
                        'Read your inbox in a browser. The code lasts 5 minutes, works once, and gives view-only access - replies and settings stay here in the app.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
                      ),
                      const SizedBox(height: 6),
                      _ActionTile(
                        icon: Icons.qr_code_2,
                        label: 'Show pairing code',
                        onTap: _showPairCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Security',
                    icon: Icons.shield_outlined,
                    children: [
                      _ActionTile(
                        icon: Icons.lock_outline,
                        label: 'Change PIN',
                        onTap: () => _showChangePinDialog(context),
                      ),
                      _ActionTile(
                        icon: Icons.refresh,
                        label: 'Regenerate backup codes',
                        onTap: () => _showRefreshCodesDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Account',
                    icon: Icons.person_outline,
                    children: [
                      _ActionTile(
                        icon: Icons.logout,
                        label: 'Sign out',
                        danger: true,
                        onTap: _signOut,
                      ),
                      _ActionTile(
                        icon: Icons.delete_outline,
                        label: 'Delete my account',
                        danger: true,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All data stays on secure, encrypted infrastructure. You stay anonymous to your senders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hide messages containing words', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Messages matching these words are sent straight to moderation, not your inbox.', style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in _hiddenWords)
              InputChip(
                label: Text(w, style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: AppColors.accentDeep,
                side: const BorderSide(color: AppColors.accent),
                deleteIconColor: AppColors.textSecondary,
                onDeleted: () => setState(() => _hiddenWords = _hiddenWords.where((x) => x != w).toList()),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _wordCtrl,
                decoration: InputDecoration(
                  hintText: 'Add a word',
                  filled: true,
                  fillColor: AppColors.bg,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (v) {
                  final word = v.trim().toLowerCase();
                  if (word.isNotEmpty && !_hiddenWords.contains(word)) {
                    setState(() => _hiddenWords = [..._hiddenWords, word]);
                  }
                  _wordCtrl.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final word = _wordCtrl.text.trim().toLowerCase();
                if (word.isNotEmpty && !_hiddenWords.contains(word)) {
                  setState(() => _hiddenWords = [..._hiddenWords, word]);
                }
                _wordCtrl.clear();
              },
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          onPressed: _savingWords ? null : _saveWords,
          child: _savingWords
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save filter', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildPause() {
    final moodChips = [
      ('30 min', 30, false),
      ('1 hour', 60, false),
      ('24 hours', 1440, false),
      ('1 week', 10080, false),
      ('Permanent', 1440, true),
      ('Link active', null, false),
    ];
    bool selectedFor(int? minutes, bool permanent) {
      if (permanent) return _permanentPause;
      if (minutes == null) return !_permanentPause && _pauseUntil == null;
      if (_permanentPause) return false;
      return _pauseUntil == minutes;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pause submissions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('While paused, senders see your profile but cannot deliver new messages.', style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in moodChips)
              ChoiceChip(
                label: Text(chip.$1, style: const TextStyle(fontSize: 12)),
                selected: selectedFor(chip.$2, chip.$3),
                selectedColor: AppColors.accent.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selectedFor(chip.$2, chip.$3) ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: selectedFor(chip.$2, chip.$3) ? AppColors.accent : AppColors.border),
                onSelected: (_) => setState(() {
                  if (chip.$3) {
                    _permanentPause = true;
                  } else {
                    _permanentPause = false;
                    _pauseUntil = chip.$2;
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                _permanentPause || _pauseUntil != null ? AppColors.accent : AppColors.surface,
            side: BorderSide(
              color: _permanentPause || _pauseUntil != null ? AppColors.accent : AppColors.border,
            ),
            foregroundColor: _permanentPause || _pauseUntil != null ? Colors.white : AppColors.textSecondary,
          ),
          onPressed: _savingPause ? null : _applyPause,
          child: _savingPause
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_permanentPause || _pauseUntil != null ? 'Apply pause' : 'Link is active'),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onOpenInbox;
  const _ProfileCard({required this.user, required this.onOpenInbox});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarBadge(initials: user.initials, size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ),
                        if (user.hasVerifiedBadge == 1) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.accent, size: 16),
                        ],
                        if (user.isSupporter) ...[
                          const SizedBox(width: 6),
                          SupporterBadge(tier: user.badgeTitle ?? 'Supporter'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('@${user.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(user.email!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.accentSoft, size: 20),
                tooltip: 'Open inbox',
                onPressed: onOpenInbox,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.bio != null && user.bio!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(user.bio!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.accentFaint),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, size: 20, color: danger ? AppColors.roseLight : AppColors.accentSoft),
      title: Text(label, style: TextStyle(color: danger ? AppColors.roseLight : AppColors.textHigh, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
      onTap: onTap,
    );
  }
}

/// Shows a pairing code with a live countdown. The code is useless once it
/// expires or has been redeemed, so it is safe to display in full.
class _PairCodeDialog extends StatefulWidget {
  final String code;
  final int expiresIn;
  const _PairCodeDialog({required this.code, required this.expiresIn});

  @override
  State<_PairCodeDialog> createState() => _PairCodeDialogState();
}

class _PairCodeDialogState extends State<_PairCodeDialog> {
  late int _left = widget.expiresIn;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _left <= 0;
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Open your inbox on the web',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Go to secretmsg.net/login and enter this code:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              widget.code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: expired ? AppColors.textMuted : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expired
                ? 'Expired. Close this and generate a new code.'
                : 'Expires in $mm:$ss',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: expired ? AppColors.roseLight : AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: expired
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: widget.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pairing code copied')),
                  );
                },
          child: const Text('Copy', style: TextStyle(color: AppColors.accentSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done', style: TextStyle(color: AppColors.accentSoft)),
        ),
      ],
    );
  }
}
