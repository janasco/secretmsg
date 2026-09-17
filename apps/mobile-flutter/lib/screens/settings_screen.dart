import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/models.dart';
import '../api/session.dart';
import '../data/vibe_templates.dart';
import '../gamification/badges.dart';
import '../gamification/celebration.dart';
import '../gamification/challenges.dart';
import '../gamification/progress.dart';
import '../gamification/rank_up.dart';
import '../gamification/ranks.dart';
import '../ritual/daily_drop.dart';
import '../ritual/reminders.dart';
import '../ritual/update_check.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/update_dialog.dart';
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
  ProgressUpdate? _progress;
  bool _remDrop = true;
  bool _remStreak = true;
  bool _remMilestone = true;
  String _appVersion = '';

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
      final prefs = await SharedPreferences.getInstance();
      final pkg = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _remDrop = prefs.getBool(prefDropEnabled) ?? true;
        _remStreak = prefs.getBool(prefStreakEnabled) ?? true;
        _remMilestone = prefs.getBool(prefMilestoneEnabled) ?? true;
        _appVersion = 'v${pkg.version} (${pkg.buildNumber})';
      });
    } catch (_) {
      // Toggles fall back to on; the API load below is what matters.
    }
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
      await RankUp.maybeShow(context, user);
      if (!mounted) return;
      try {
        final progress = await refreshProgress(user);
        if (!mounted) return;
        setState(() => _progress = progress);
        await maybeShowUnlocks(
          context,
          badges: progress.freshBadges,
          challenges: progress.freshChallenges,
        );
      } catch (_) {
        // Gamification is best-effort; the profile already loaded.
      }
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
        backgroundColor: context.colors.surface,
        title: Text('Pick your custom username', style: TextStyle(color: context.colors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your supporter perk. Choose a clean handle without numbers — this replaces your link.',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.5),
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
                fillColor: context.colors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.border),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '4–30 lowercase letters, numbers, dashes, underscores, or dots.',
              style: TextStyle(color: context.colors.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.colors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim().toLowerCase()),
            child: Text('Claim', style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.w700)),
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

  Future<void> _showChangePinDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Current PIN')),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'New PIN (4-6 digits)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            try {
              await ApiClient.authChangePin(currentPin: currentCtrl.text, newPin: newCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
            }
          }, child: const Text('Save')),
        ],
      ),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
    }
  }

  Future<void> _showRefreshCodesDialog(BuildContext context) async {
    final pinCtrl = TextEditingController();
    final result = await showDialog<List<String>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Backup Codes'),
        content: TextField(controller: pinCtrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Enter your PIN')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            try {
              final codes = await ApiClient.authRefreshBackupCodes(currentPin: pinCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx, codes);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
            }
          }, child: const Text('Generate')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New Backup Codes'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Save these codes. Old codes are now invalid.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            for (final code in result)
              Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
    }
  }

  Widget _buildReminderToggle({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.colors.accent,
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.colors.textMuted)),
    );
  }

  Future<void> _setReminderToggle(String key, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      final now = DateTime.now();
      final dropOn = key == prefDropEnabled ? value : _remDrop;
      final streakOn = key == prefStreakEnabled ? value : _remStreak;
      if (!dropOn && !streakOn) {
        await cancelAllReminders();
        return;
      }
      final prompt = VIBE_TEMPLATES[dropIndexForDay(now, VIBE_TEMPLATES.length)].text;
      await rescheduleAll(
        now: now,
        dropAnswered: false,
        checkedInToday: false,
        streakCount: 0,
        dropPrompt: prompt,
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not update reminder setting.');
    }
  }

  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        Widget chip(ThemeMode m, IconData icon, String label) {
          final selected = mode == m;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: selected ? Colors.white : context.colors.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : context.colors.textSecondary,
                    )),
              ],
            ),
            selected: selected,
            onSelected: (_) => ThemeController.instance.setMode(m),
            selectedColor: context.colors.accent,
            backgroundColor: context.colors.surfaceLight,
            side: BorderSide(color: selected ? context.colors.accent : context.colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            showCheckmark: false,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
            const SizedBox(height: 4),
            Text('System follows your phone (default).',
                style: TextStyle(fontSize: 11.5, color: context.colors.textMuted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip(ThemeMode.system, Icons.settings_suggest_outlined, 'System'),
                chip(ThemeMode.light, Icons.light_mode_outlined, 'Light'),
                chip(ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkUpdates() async {
    try {
      final info = await checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        showErrorSnack(context, 'Could not reach the update server. Try again later.');
      } else if (!info.behind) {
        showSuccessSnack(context, 'You are on the latest version (v${info.current}).');
      } else {
        await showUpdateDialog(context, info);
      }
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not check for updates.');
    }
  }

  Future<void> _requestReminderAccess() async {
    try {
      final granted = await requestReminderPermission();
      final exact = await exactAlarmAllowed();
      if (!mounted) return;
      if (granted && exact) {
        showSuccessSnack(context, 'Notifications on — reminders scheduled.');
      } else if (granted) {
        showSuccessSnack(context, 'Notifications on. For exact timing, allow alarms in system settings.');
      } else {
        showErrorSnack(context, 'Notifications blocked. Enable them in system settings to get reminders.');
      }
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not open notification settings.');
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign out?',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'You will need your handle, PIN or a backup code to get back in. Reminders on this device stop.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Stay', style: TextStyle(color: context.colors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign out', style: TextStyle(color: context.colors.roseLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.unregisterPushToken();
    } catch (_) {}
    await Session.clear();
    try {
      await cancelAllReminders();
    } catch (_) {}
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
        backgroundColor: context.colors.surface,
        title: Text('Delete your account?', style: TextStyle(color: context.colors.textPrimary, fontSize: 16)),
        content: Text(
          'This permanently wipes your account, username, inbox, and settings. This cannot be undone.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: context.colors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: context.colors.roseLight, fontWeight: FontWeight.w700)),
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
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
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
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.roseLight)),
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
            Text('You are not signed in.', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Sign in to manage your secret link.', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: Colors.white),
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
                  _RankCard(rank: u.rank),
                  const SizedBox(height: 16),
                  if (_progress != null) ...[
                    _ChallengesCard(
                      challenges: _progress!.todaysChallenges,
                      metrics: _progress!.metrics,
                      streak: _progress!.streak,
                    ),
                    const SizedBox(height: 16),
                    _BadgeShelf(unlockedIds: _progress!.unlockedBadgeIds),
                    const SizedBox(height: 16),
                  ],
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
                        Divider(color: context.colors.border, height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supporter perk — your username',
                              style: TextStyle(color: context.colors.textMuted, fontSize: 11),
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
                      Divider(color: context.colors.border, height: 24),
                      _buildPause(),
                      Divider(color: context.colors.border, height: 24),
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
                    title: 'Ritual & notifications',
                    icon: Icons.notifications_outlined,
                    children: [
                      _buildReminderToggle(
                        value: _remDrop,
                        title: 'Daily Drop reminders',
                        subtitle: 'Morning card + evening expiry nudge',
                        onChanged: (v) => _setReminderToggle(prefDropEnabled, v, (x) => _remDrop = x),
                      ),
                      _buildReminderToggle(
                        value: _remStreak,
                        title: 'Streak reminder',
                        subtitle: 'Nightly nudge to keep your flame alive',
                        onChanged: (v) => _setReminderToggle(prefStreakEnabled, v, (x) => _remStreak = x),
                      ),
                      _buildReminderToggle(
                        value: _remMilestone,
                        title: 'Milestones',
                        subtitle: 'Rank-ups and streak records',
                        onChanged: (v) => _setReminderToggle(prefMilestoneEnabled, v, (x) => _remMilestone = x),
                      ),
                      Divider(color: context.colors.border, height: 24),
                      _ActionTile(
                        icon: Icons.notification_important_outlined,
                        label: 'Allow notifications',
                        onTap: _requestReminderAccess,
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
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StaticScreen(keyOf: 'about'))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'View on web',
                    icon: Icons.devices_outlined,
                    children: [
                      Text(
                        'Read your inbox in a browser. The code lasts 5 minutes, works once, and gives view-only access - replies and settings stay here in the app.',
                        style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
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
                    title: 'App',
                    icon: Icons.smartphone_outlined,
                    children: [
                      _ActionTile(
                        icon: Icons.info_outline,
                        label: _appVersion.isEmpty ? 'Version…' : 'Version $_appVersion',
                        onTap: null,
                      ),
                      _ActionTile(
                        icon: Icons.system_update_outlined,
                        label: 'Check for updates',
                        onTap: _checkUpdates,
                      ),
                      Divider(color: context.colors.border, height: 24),
                      _buildThemeSelector(),
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
                  Text(
                    'All data stays on secure, encrypted infrastructure. You stay anonymous to your senders.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
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
        Text('Hide messages containing words', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Messages matching these words are sent straight to moderation, not your inbox.', style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in _hiddenWords)
              InputChip(
                label: Text(w, style: TextStyle(color: context.colors.accentSoft, fontSize: 12)),
                backgroundColor: context.colors.accentDeep,
                side: BorderSide(color: context.colors.accent),
                deleteIconColor: context.colors.textSecondary,
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
                  fillColor: context.colors.bg,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
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
          style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: Colors.white),
          onPressed: _savingWords ? null : _saveWords,
          child: _savingWords
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
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
        Text('Pause submissions', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('While paused, senders see your profile but cannot deliver new messages.', style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in moodChips)
              ChoiceChip(
                label: Text(chip.$1, style: const TextStyle(fontSize: 12)),
                selected: selectedFor(chip.$2, chip.$3),
                selectedColor: context.colors.accent.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selectedFor(chip.$2, chip.$3) ? context.colors.textPrimary : context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: selectedFor(chip.$2, chip.$3) ? context.colors.accent : context.colors.border),
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
                _permanentPause || _pauseUntil != null ? context.colors.accent : context.colors.surface,
            side: BorderSide(
              color: _permanentPause || _pauseUntil != null ? context.colors.accent : context.colors.border,
            ),
            foregroundColor: _permanentPause || _pauseUntil != null ? Colors.white : context.colors.textSecondary,
          ),
          onPressed: _savingPause ? null : _applyPause,
          child: _savingPause
              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
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
                            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ),
                        if (user.hasVerifiedBadge == 1) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified, color: context.colors.accent, size: 16),
                        ],
                        if (user.isSupporter) ...[
                          const SizedBox(width: 6),
                          SupporterBadge(tier: user.badgeTitle ?? 'Supporter'),
                        ],
                        const SizedBox(width: 6),
                        RankBadge(emoji: user.rank.emoji, name: user.rank.name),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('@${user.username}', style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(user.email!, style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.mark_email_read_outlined, color: context.colors.accentSoft, size: 20),
                tooltip: 'Open inbox',
                onPressed: onOpenInbox,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.bio != null && user.bio!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(user.bio!, style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.5)),
            ),
        ],
      ),
    );
  }
}

/// Activity rank with progress toward the next tier. Score = messages
/// received + 2 per reply (+25 supporter bonus), computed server-side.
class _RankCard extends StatelessWidget {
  final RankInfo rank;

  const _RankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    final toNext = rank.pointsToNext;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rank.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rank: ${rank.name}',
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${rank.score} activity points',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RankProgressBar(progress: rank.progress),
          const SizedBox(height: 6),
          Text(
            toNext == null
                ? 'Max rank reached — icon status.'
                : '$toNext points to ${rank.nextName ?? 'the next rank'}',
            style: TextStyle(color: context.colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Today's rotating challenges with live progress. Completing one fires a
/// one-time celebration via the unlocks dialog in _load.
class _ChallengesCard extends StatelessWidget {
  final List<ChallengeDef> challenges;
  final DayMetrics metrics;
  final int streak;

  const _ChallengesCard({
    required this.challenges,
    required this.metrics,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Today's Challenges",
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '🔥 $streak day${streak == 1 ? '' : 's'}',
                  style: TextStyle(color: context.colors.accentSoft, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in challenges) ...[
            _ChallengeRow(def: c, metrics: metrics),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final ChallengeDef def;
  final DayMetrics metrics;

  const _ChallengeRow({required this.def, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final done = challengeDone(def, metrics);
    final have = metricValue(def, metrics);
    return Row(
      children: [
        Text(def.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      def.title,
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    done ? '✓' : '$have/${def.goal}',
                    style: TextStyle(
                      color: done ? context.colors.accentSoft : context.colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(def.hint, style: TextStyle(color: context.colors.textSecondary, fontSize: 11)),
              const SizedBox(height: 6),
              RankProgressBar(progress: challengeProgress(def, metrics)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full badge shelf: unlocked badges in color, locked ones dimmed.
class _BadgeShelf extends StatelessWidget {
  final Set<String> unlockedIds;

  const _BadgeShelf({required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    final catalog = badgeCatalog;
    final unlockedCount = catalog.where((b) => unlockedIds.contains(b.id)).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Badge Shelf',
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$unlockedCount/${catalog.length}',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: catalog.length,
            itemBuilder: (context, i) {
              final b = catalog[i];
              final unlocked = unlockedIds.contains(b.id);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? context.colors.amber.withValues(alpha: 0.15)
                          : context.colors.surface,
                      border: Border.all(
                        color: unlocked
                            ? context.colors.amber.withValues(alpha: 0.4)
                            : context.colors.border,
                      ),
                    ),
                    child: Text(
                      unlocked ? b.emoji : '🔒',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? context.colors.textPrimary : context.colors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: context.colors.accentFaint),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
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
      leading: Icon(icon, size: 20, color: danger ? context.colors.roseLight : context.colors.accentSoft),
      title: Text(label, style: TextStyle(color: danger ? context.colors.roseLight : context.colors.textHigh, fontSize: 14)),
      trailing: Icon(Icons.chevron_right, size: 18, color: context.colors.textFaint),
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
      backgroundColor: context.colors.surface,
      title: Text(
        'Open your inbox on the web',
        style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Go to secretmsg.net/login and enter this code:',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: context.colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.border),
            ),
            child: SelectableText(
              widget.code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: expired ? context.colors.textMuted : context.colors.textPrimary,
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
              color: expired ? context.colors.roseLight : context.colors.textMuted,
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
          child: Text('Copy', style: TextStyle(color: context.colors.accentSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Done', style: TextStyle(color: context.colors.accentSoft)),
        ),
      ],
    );
  }
}
