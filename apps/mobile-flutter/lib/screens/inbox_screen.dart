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

  int get _unreadCount =>
      (_messages ?? const []).where((m) => m.isRead == 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Secret Inbox'),
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
            const Icon(Icons.drafts_outlined, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Your anonymous inbox awaits',
              textAlign: TextAlign.center,
              style: AppType.titleSm.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your email to read messages, reply double-blind, and manage your secret link.',
              textAlign: TextAlign.center,
              style: AppType.bodySm.copyWith(height: 1.5),
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
              child: const Text('Create your link', style: TextStyle(color: AppColors.accentSoft)),
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch header row: headline title with a filled count pill on the right.
  Widget _buildHeader() {
    final n = _unreadCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(child: Text('Secret Inbox', style: AppType.headlineMd)),
          if (n > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$n New',
                style: AppType.labelCaps.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Stitch filter tabs: filled for the active filter, glass pills otherwise,
  /// each with its live count.
  Widget _buildFilters() {
    final all = _messages ?? const [];
    final unread = all.where((m) => m.isRead == 0).length;
    final replied =
        all.where((m) => m.replyContent != null && m.replyContent!.isNotEmpty).length;
    final pinned = all.where((m) => m.isPinned == 1).length;
    final filters = [
      ('all', 'All', all.length),
      ('unread', 'Unread', unread),
      ('replied', 'Replies', replied),
      ('pinned', 'Pinned', pinned),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final active = _filter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = f.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                '${f.$2} (${f.$3})',
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Stitch KPI row: three stat cards over the message stream.
  Widget _buildStats() {
    final all = _messages ?? const [];
    final unread = all.where((m) => m.isRead == 0).length;
    final replied =
        all.where((m) => m.replyContent != null && m.replyContent!.isNotEmpty).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(child: StatCard(label: 'Total', value: '${all.length}')),
          const SizedBox(width: 8),
          Expanded(child: StatCard(label: 'Unread', value: '$unread')),
          const SizedBox(width: 8),
          Expanded(child: StatCard(label: 'Replied', value: '$replied')),
        ],
      ),
    );
  }

  Widget _buildInbox() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildFilters(),
        _buildStats(),
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
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.roseLight, fontSize: 13)),
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
          const Icon(Icons.inbox_outlined, size: 52, color: AppColors.textFaint),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            textAlign: TextAlign.center,
            style: AppType.bodyBase.copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            _filter == 'all'
                ? 'Share your link and wait for the first anonymous message to arrive.'
                : 'Nothing here in this filter.',
            textAlign: TextAlign.center,
            style: AppType.bodySm,
          ),
          const SizedBox(height: 20),
          const Center(
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
  const _ShareLinkButton();

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

/// Stitch message card: glass panel, glow dot on unread cards, context pill,
/// relative time, body-lg text.
class _MessageCard extends StatelessWidget {
  final AnonymousMessage message;
  final VoidCallback onTap;
  const _MessageCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final replied = message.replyContent != null && message.replyContent!.isNotEmpty;
    final unread = message.isRead == 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? AppColors.accent.withOpacity(0.45) : AppColors.border,
          ),
          boxShadow: unread
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (unread) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 2),
                if (message.isPinned == 1) ...[
                  const Icon(Icons.push_pin, size: 13, color: AppColors.amber),
                  const SizedBox(width: 6),
                ],
                if (message.deviceHint != null && message.deviceHint!.isNotEmpty) ...[
                  StitchPill(message.deviceHint!),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  _formatTime(message.createdAt),
                  style: AppType.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppType.bodyBase.copyWith(fontSize: 15, height: 1.5),
            ),
            if (replied) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: AppColors.emeraldSoft),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.replyContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.emeraldLight, fontSize: 12),
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

  /// Stitch-style relative time: 10m, 42m, 2d, then a date.
  static String _formatTime(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
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
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: AppColors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text('Anonymous Sender', style: AppType.bodySm),
                          const Spacer(),
                          if (m.deviceHint != null && m.deviceHint!.isNotEmpty)
                            StitchPill(m.deviceHint!),
                          if (m.isPinned == 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.push_pin, color: AppColors.amber, size: 15),
                          ],
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 24),
                      Text(m.content, style: AppType.bodyBase.copyWith(fontSize: 15, height: 1.55)),
                      const SizedBox(height: 12),
                      Text(_formatTime(m.createdAt), style: AppType.bodySm.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                if (replied) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.reply, color: AppColors.emeraldSoft, size: 16),
                            SizedBox(width: 6),
                            Text('Your blind reply', style: TextStyle(color: AppColors.emeraldLight, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(m.replyContent!, style: AppType.bodySm.copyWith(color: AppColors.emeraldLight, height: 1.5)),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text('Reply double-blind', style: AppType.titleSm),
                  const SizedBox(height: 4),
                  Text(
                    'Your reply is shown back to the sender anonymously via their private claim link — your identity stays hidden.',
                    style: AppType.bodySm.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 5,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Write a blind reply…',
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
                      style: TextButton.styleFrom(foregroundColor: AppColors.roseLight),
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
