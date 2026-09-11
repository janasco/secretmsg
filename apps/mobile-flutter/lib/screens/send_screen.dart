import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/models.dart';
import '../data/vibe_templates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/turnstile_widget.dart';
import 'login_screen.dart';

class SendScreen extends StatefulWidget {
  final String? initialUsername;
  const SendScreen({super.key, this.initialUsername});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _usernameCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  UserProfile? _profile;
  bool _lookingUp = false;
  String? _lookupError;

  String _activeCategory = 'friendly';
  String _activeTarget = 'all';
  bool _allowClue = false;
  bool _showInspiration = false;

  String? _turnstileToken;
  int _tsReset = 0;
  bool _sending = false;
  String? _sendError;

  bool _sent = false;
  String? _replyToken;

  static final _usernameRe = RegExp(r'^[a-z0-9_\-\.]{4,30}$');

  @override
  void initState() {
    super.initState();
    if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      _usernameCtrl.text = widget.initialUsername!;
      _performLookup();
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _performLookup() async {
    final raw = _usernameCtrl.text.trim().toLowerCase().replaceFirst('@', '');
    if (raw.isEmpty) return;
    if (!_usernameRe.hasMatch(raw)) {
      setState(() {
        _lookupError =
            'Use a username with 4–30 characters: lowercase letters, numbers, dashes, underscores, or dots.';
      });
      return;
    }
    setState(() {
      _lookingUp = true;
      _lookupError = null;
      _profile = null;
      _sent = false;
      _replyToken = null;
      _sendError = null;
    });
    try {
      final profile = await ApiClient.getRecipientProfile(raw);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _lookingUp = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _lookupError = e.statusCode == 404
            ? "This user doesn't have a SecretMsg inbox yet, or the link is currently paused."
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lookingUp = false;
        _lookupError = 'Could not reach SecretMsg. Check your connection and try again.';
      });
    }
  }

  Future<void> _send() async {
    final profile = _profile;
    if (profile == null || _sending) return;
    final content = _contentCtrl.text.trim();
    if (content.isEmpty || content.length > kMaxMessageLength) {
      setState(() => _sendError = 'Write a message between 1 and $kMaxMessageLength characters.');
      return;
    }
    if (_turnstileToken == null) {
      setState(() => _sendError = 'Please complete the verification challenge before sending.');
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final replyToken = await ApiClient.sendAnonymousMessage(
        username: profile.username,
        content: content,
        turnstileToken: _turnstileToken,
        allowClue: _allowClue,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
        _replyToken = replyToken;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (e.statusCode == 403 || e.statusCode == 400) {
        msg = 'Verification or content check failed. Please retry.';
      } else if (e.statusCode == 404) {
        msg = "This user doesn't have a SecretMsg inbox yet, or the link is currently paused.";
      }
      setState(() {
        _sending = false;
        _sendError = msg;
        _turnstileToken = null;
        _tsReset++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = 'Failed to send. Check your connection and try again.';
        _turnstileToken = null;
        _tsReset++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: _profile == null ? 'Send a message' : ''),
      body: _sent ? _buildSuccess() : _buildMain(),
    );
  }

  Widget _buildMain() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profile == null) _buildLookup(),
              if (_profile != null) ...[
                _buildRecipientCard(),
                const SizedBox(height: 16),
                _buildComposer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLookup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Send it to a friend',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Type their username to start composing an anonymous message.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _usernameCtrl,
          enabled: !_lookingUp,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'e.g. janasco',
            prefixIcon: const Icon(Icons.alternate_email, size: 18),
            filled: true,
            fillColor: const Color(0xFF0F1220),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onSubmitted: (_) => _performLookup(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _lookingUp ? null : _performLookup,
          child: _lookingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        if (_lookupError != null) ...[
          const SizedBox(height: 12),
          Text(
            _lookupError!,
            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.45),
          ),
        ],
        const SizedBox(height: 24),
        _SafeNote(),
      ],
    );
  }

  Widget _buildRecipientCard() {
    final p = _profile!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AvatarBadge(initials: p.initials, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (p.hasVerifiedBadge == 1)
                      const Icon(Icons.verified, size: 15, color: AppColors.accent),
                    if (p.isSupporter) ...[
                      const SizedBox(width: 6),
                      SupporterBadge(tier: p.badgeTitle ?? 'Supporter'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('@${p.username}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                if (p.bio != null && p.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(p.bio!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
                ],
              ],
            ),
          ),
          if (p.isPaused)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.pause_circle_filled, color: Color(0xFFF59E0B), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final remaining = kMaxMessageLength - _contentCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _contentCtrl,
          maxLines: 6,
          minLines: 4,
          maxLength: kMaxMessageLength,
          onChanged: (_) => setState(() {
            _sendError = null;
          }),
          decoration: InputDecoration(
            hintText: 'Write something real…',
            filled: true,
            fillColor: const Color(0xFF0F1220),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            counterText: remaining <= 20 ? '$remaining left' : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _showInspiration = !_showInspiration),
              icon: const Icon(Icons.auto_awesome, size: 15, color: Color(0xFFA5B4FC)),
              label: Text(
                _showInspiration ? 'Hide ideas' : 'Get inspired',
                style: const TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            Text('$remaining', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        if (_showInspiration) _buildInspiration(),
        const SizedBox(height: 6),
        SwitchListTile(
          value: _allowClue,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Allow device hint',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Lets the recipient see an anonymous device hint (e.g. Mobile / Android).',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.4),
          ),
          activeTrackColor: AppColors.accent,
          onChanged: (v) => setState(() => _allowClue = v),
        ),
        const SizedBox(height: 4),
        TurnstileWidget(
          resetCount: _tsReset,
          onToken: (token) => setState(() {
            _turnstileToken = token;
            _sendError = null;
          }),
          onError: (_) => setState(() => _turnstileToken = null),
        ),
        if (_sendError != null) ...[
          const SizedBox(height: 10),
          Text(_sendError!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.4)),
        ],
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            disabledBackgroundColor: AppColors.accent.withOpacity(0.3),
          ),
          onPressed: _sending || _turnstileToken == null ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send Anonymously', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Your identity is never shared with the recipient.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildInspiration() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in VIBE_TARGETS)
                ChoiceChip(
                  label: Text('${t.icon} ${t.label}', style: const TextStyle(fontSize: 11)),
                  selected: _activeTarget == t.id,
                  selectedColor: AppColors.accent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _activeTarget == t.id ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _activeTarget == t.id ? AppColors.accent : AppColors.border,
                  ),
                  onSelected: (_) => setState(() => _activeTarget = _activeTarget == t.id ? 'all' : t.id),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final c in VIBE_CATEGORIES) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeCategory = c.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeCategory == c.id
                            ? AppColors.accent.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(c.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(c.label, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
            onPressed: () {
              final pool = _activeTarget == 'all'
                  ? VIBE_TEMPLATES
                  : VIBE_TEMPLATES.where((t) => t.target == _activeTarget).toList();
              final pick = pool[DateTime.now().millisecondsSinceEpoch % pool.length];
              setState(() {
                _contentCtrl.text = pick.text;
                _activeCategory = pick.category;
              });
            },
            icon: const Icon(Icons.casino, size: 16),
            label: const Text('Shuffle an idea', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          for (final t in VIBE_TEMPLATES.where(
              (t) => t.category == _activeCategory && (_activeTarget == 'all' || t.target == _activeTarget))) ...[
            _TemplateTile(text: t.text, onPick: () => setState(() => _contentCtrl.text = t.text)),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final username = _profile!.username;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 40),
              ),
              const SizedBox(height: 18),
              const Text('Sent Anonymously!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Your message was delivered safely to @$username without any trace of your identity.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
              ),
              if (_replyToken != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1220),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Private Reply Link (Double-Blind)',
                        style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'If they reply, you can view their response anonymously using this private link:',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => copyToClipboard(context, '$kPublicBaseUrl/reply/$_replyToken', message: 'Reply link copied'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF090A0F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$kPublicBaseUrl/reply/$_replyToken',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontFamily: 'monospace'),
                                ),
                              ),
                              const Icon(Icons.copy, size: 15, color: Color(0xFFA5B4FC)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _profile = null;
                    _sent = false;
                    _replyToken = null;
                    _contentCtrl.clear();
                    _turnstileToken = null;
                    _tsReset++;
                  });
                },
                child: const Text('Send another message', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                ),
                child: const Text('Create your own SecretMsg link', style: TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final String text;
  final VoidCallback onPick;
  const _TemplateTile({required this.text, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF090A0F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4)),
      ),
    );
  }
}

class _SafeNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Built for safe, honest connection', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        SizedBox(height: 8),
        _Bullet(icon: Icons.visibility_off, text: 'Zero IP tracking, zero ad surveillance, zero profile mining.'),
        _Bullet(icon: Icons.filter_list, text: 'Automated moderation scans every message before it reaches the inbox.'),
        _Bullet(icon: Icons.auto_awesome, text: 'Blind reply link keeps identities private on both ends.'),
        _Bullet(icon: Icons.pause_circle_outline, text: 'Recipients can pause, filter, or wipe their inbox anytime.'),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF818CF8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.45)),
          ),
        ],
      ),
    );
  }
}