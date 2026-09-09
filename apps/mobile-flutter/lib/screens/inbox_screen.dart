import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/models.dart';
import '../api/session.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<AnonymousMessage>? _messages;
  bool _loading = false;
  String? _error;
  String _filter = 'all';
  bool _isAuthed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await Session.getToken();
    if (!mounted) return;
    setState(() => _isAuthed = token != null);
    if (token == null) return;
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await ApiClient.getInbox();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } on UnauthorizedError catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAuthed = false;
        _messages = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your inbox.';
      });
    }
  }

  List<AnonymousMessage> get _filtered {
    final all = _messages ?? const [];
    switch (_filter) {
      case 'unread':
        return all.where((m) => m.isRead == 0).toList();
      case 'replied':
        return all.where((m) => m.replyContent != null && m.replyContent!.isNotEmpty).toList();
      case 'pinned':
        return all.where((m) => m.isPinned == 1).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Inbox'),
      body: !_isAuthed ? _buildSignIn() : _buildInbox(),
    );
  }

  Widget _buildSignIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drafts_outlined, size: 56, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            const Text(
              'Your anonymous inbox awaits',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in with your email to read messages, reply double-blind, and manage your secret link.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Sign in to your inbox', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => copyToClipboard(context, kPublicBaseUrl, message: 'Copy of share URL'),
              child: const Text('Create your link', style: TextStyle(color: Color(0xFFA5B4FC))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInbox() {
    return Column(
      children: [
        if (_error == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All'),
                  ('unread', 'Unread'),
                  ('pinned', 'Pinned'),
                  ('replied', 'Replies'),
                ]) ...[
                  ChoiceChip(
                    label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                    selected: _filter == f.$1,
                    selectedColor: AppColors.accent.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _filter == f.$1 ? Colors.white : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: _filter == f.$1 ? AppColors.accent : AppColors.border),
                    onSelected: (_) => setState(() => _filter = f.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _messages == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF3B3F52)),
          const SizedBox(height: 12),
          const Text(
            'No messages yet',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _filter == 'all'
                ? 'Share your link and wait for the first anonymous message to arrive.'
                : 'Nothing here in this filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 20),
          Center(
            child: _ShareLinkButton(),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = items[i];
        return _MessageCard(message: m, onTap: () => _openMessage(m));
      },
    );
  }

  void _openMessage(AnonymousMessage m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MessageDetailScreen(message: m, onReplied: (reply) {
          if (!mounted) return;
          setState(() {
            final idx = _messages?.indexWhere((x) => x.id == m.id);
            if (idx != null && idx >= 0 && _messages != null) {
              final updated = AnonymousMessage(
                id: m.id,
                content: m.content,
                replyContent: reply,
                replyAt: DateTime.now().toIso8601String(),
                isPinned: m.isPinned,
                isRead: 1,
                deviceHint: m.deviceHint,
                createdAt: m.createdAt,
              );
              _messages![idx] = updated;
            }
          });
        }),
      ),
    );
  }
}

class _ShareLinkButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
      onPressed: () => copyToClipboard(context, kPublicBaseUrl, message: 'Link copied'),
      icon: const Icon(Icons.link, size: 17),
      label: const Text('Copy my link'),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AnonymousMessage message;
  final VoidCallback onTap;
  const _MessageCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final replied = message.replyContent != null && message.replyContent!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: message.isRead == 0 ? AppColors.accent.withOpacity(0.45) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (message.isRead == 0)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  )
                else
                  const SizedBox(width: 8),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ),
                if (message.isPinned == 1) const Icon(Icons.push_pin, size: 14, color: Color(0xFFF59E0B)),
                if (message.deviceHint != null) ...[
                  const SizedBox(width: 6),
                  Text(message.deviceHint!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
            ),
            if (replied) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF090A0F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Color(0xFF34D399)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.replyContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTime(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (now.difference(t).inHours < 24) {
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      }
      return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _MessageDetailScreen extends StatefulWidget {
  final AnonymousMessage message;
  final void Function(String reply) onReplied;
  const _MessageDetailScreen({required this.message, required this.onReplied});

  @override
  State<_MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<_MessageDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  bool _reported = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || text.length > 500 || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.replyMessage(widget.message.id, text);
      if (!mounted) return;
      widget.onReplied(text);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showErrorSnack(context, e.toString());
    }
  }

  Future<void> _report() async {
    setState(() => _reported = true);
    try {
      await ApiClient.reportMessage(widget.message.id, 'Reported by recipient from Android app');
    } catch (_) {}
    if (!mounted) return;
    showErrorSnack(context, 'Message reported. Our team will review it shortly.');
    setState(() => _reported = false);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final replied = m.replyContent != null && m.replyContent!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1220),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: Color(0xFF6366F1), size: 18),
                          const SizedBox(width: 8),
                          const Text('Anonymous Sender', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const Spacer(),
                          if (m.deviceHint != null)
                            Text(m.deviceHint!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                          const SizedBox(width: 8),
                          if (m.isPinned == 1) const Icon(Icons.push_pin, color: Color(0xFFF59E0B), size: 15),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      Text(m.content, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                      const SizedBox(height: 12),
                      Text(_formatTime(m.createdAt), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
                if (replied) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06281D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.reply, color: Color(0xFF34D399), size: 16),
                            SizedBox(width: 6),
                            Text('Your blind reply', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(m.replyContent!, style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text('Reply double-blind', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'Your reply is shown back to the sender anonymously via their private claim link — your identity stays hidden.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 5,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Write a blind reply…',
                      filled: true,
                      fillColor: const Color(0xFF0F1220),
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
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _sending || _replyCtrl.text.trim().isEmpty ? null : _sendReply,
                    child: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Blind Reply', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _reported ? null : _report,
                      icon: const Icon(Icons.flag_outlined, size: 15),
                      label: Text(_reported ? 'Reporting…' : 'Report this message'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFF87171)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}