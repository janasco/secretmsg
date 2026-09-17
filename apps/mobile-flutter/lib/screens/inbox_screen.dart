import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/models.dart';
import '../api/session.dart';
import '../data/vibe_templates.dart';
import '../ritual/daily_drop.dart';
import '../ritual/drop_store.dart';
import '../ritual/push.dart';
import '../ritual/reminders.dart';
import '../ritual/streak_store.dart';
import '../gamification/rank_up.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/drop_countdown.dart';
import 'daily_drop_screen.dart';
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
  List<AnonymousMessage> _tray = const [];
  StreakState? _streak;
  bool _dropDone = true; // Hidden until ritual state loads.
  bool _vibePrompted = false;

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
      // Tray loads alongside; failures stay silent (badge just hides).
      unawaited(_loadTray());
      // Ritual check-in rides the inbox refresh: streak rolls, tonight's
      // reminders refresh from real state, vibe prompt shows once per day.
      unawaited(_ritualCheckIn());
      // Rank-up check rides the inbox refresh: a fresh profile carries the
      // server-computed rank, celebrated at most once per tier per account.
      try {
        final me = await ApiClient.getMe();
        if (!mounted) return;
        await RankUp.maybeShow(context, me);
      } catch (_) {
        // Celebration is best-effort; the inbox already loaded.
      }
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

  String _todayPrompt() {
    final now = DateTime.now();
    return VIBE_TEMPLATES[dropIndexForDay(now, VIBE_TEMPLATES.length)].text;
  }

  /// Ritual check-in after a successful inbox load: rolls the streak
  /// (freeze/repair handled in the store), refreshes tonight's reminders
  /// from real state, and prompts the once-daily vibe check-in.
  Future<void> _ritualCheckIn() async {
    try {
      final now = DateTime.now();
      // Push token self-heals here too: fresh logins land on the inbox
      // without passing through cold-start routing.
      await registerPushTokenOnce();
      final checkIn = await StreakStore.checkIn(now);
      final done = await DropStore.isDone(now);
      if (!mounted) return;
      setState(() {
        _streak = checkIn.state;
        _dropDone = done;
      });
      if (checkIn.froze) {
        if (mounted) {
          showSuccessSnack(context,
              '🧊 Streak freeze saved your ${checkIn.state.count}-day streak');
        }
      } else if (checkIn.earnedFreeze) {
        if (mounted) showSuccessSnack(context, '🛡️ Milestone! Earned a streak freeze');
      }
      await rescheduleAll(
        now: now,
        dropAnswered: done,
        checkedInToday: true,
        streakCount: checkIn.state.count,
        dropPrompt: _todayPrompt(),
        filteredWeekCount: _trayWeekCount,
      );
      if (!mounted || _vibePrompted) return;
      if (!await VibeStore.isCheckedIn(now)) {
        _vibePrompted = true;
        _promptVibe();
      }
    } catch (_) {
      // Ritual is best-effort; the inbox already loaded.
    }
  }

  void _promptVibe() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('How are you vibing today?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final mood in vibeMoods)
              IconButton(
                onPressed: () async {
                  try {
                    await VibeStore.checkIn(DateTime.now(), mood);
                  } catch (_) {}
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) showSuccessSnack(context, 'Vibe saved $mood');
                },
                icon: Text(mood, style: const TextStyle(fontSize: 28)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDrop() async {
    final answered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyDropScreen()),
    );
    if (answered == true && mounted) {
      setState(() => _dropDone = true);
      try {
        final now = DateTime.now();
        await rescheduleAll(
          now: now,
          dropAnswered: true,
          checkedInToday: true,
          streakCount: _streak?.count ?? 0,
          dropPrompt: _todayPrompt(),
          filteredWeekCount: _trayWeekCount,
        );
      } catch (_) {}
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
      case 'filtered':
        return _tray;
      default:
        return all;
    }
  }

  /// Tray holds from the last 7 days (digest scope).
  int get _trayWeekCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _tray.where((m) {
      final at = DateTime.tryParse(m.createdAt);
      return at != null && !at.isBefore(cutoff);
    }).length;
  }

  Future<void> _loadTray() async {
    try {
      final tray = await ApiClient.getFilteredTray();
      if (!mounted) return;
      setState(() => _tray = tray);
    } catch (_) {
      // Tray is additive; the inbox already loaded.
    }
  }

  int get _unreadCount =>
      (_messages ?? const []).where((m) => m.isRead == 0).length;

  @override
  Widget build(BuildContext context) {
    final streak = _streak;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Secret Inbox',
        actions: [
          if (streak != null && streak.count > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: const Text('🔥', style: TextStyle(fontSize: 13)),
                label: Text('${streak.count}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                backgroundColor: context.colors.amber.withValues(alpha: 0.15),
                side: BorderSide(color: context.colors.amber.withValues(alpha: 0.4)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
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
            Icon(Icons.drafts_outlined, size: 56, color: context.colors.accent),
            const SizedBox(height: 16),
            Text(
              'Your anonymous inbox awaits',
              textAlign: TextAlign.center,
              style: context.type.titleSm.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in with your email to read messages, reply double-blind, and manage your secret link.',
              textAlign: TextAlign.center,
              style: context.type.bodySm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Sign in to your inbox', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => copyToClipboard(context, kPublicBaseUrl, message: 'Copy of share URL'),
              child: Text('Create your link', style: TextStyle(color: context.colors.accentSoft)),
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch header row: headline title with a filled count pill on the right.
  Widget _buildHeader() {
    final n = _unreadCount;
    // The app bar already says "Secret Inbox" — this row only renders the
    // unread pill, and collapses entirely when there is nothing new.
    if (n <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$n New',
              style: context.type.labelCaps.copyWith(color: Colors.white),
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
      ('filtered', 'Filtered', _tray.length),
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
                color: active ? context.colors.accent : context.colors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? context.colors.accent : context.colors.border,
                ),
              ),
              child: Text(
                '${f.$2} (${f.$3})',
                style: TextStyle(
                  color: active ? context.colors.textPrimary : context.colors.textSecondary,
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

  /// Moderation digest: nudges review when held mail piles up.
  Widget _buildDigestChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: InkWell(
        onTap: () => setState(() => _filter = 'filtered'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: context.colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: context.colors.amberLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_trayWeekCount ${_trayWeekCount == 1 ? 'message' : 'messages'} held this week — review',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
  /// Today's Drop banner: tappable card with live expiry countdown.
  Widget _buildDropBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: InkWell(
        onTap: _openDrop,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.accentDeep,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Drop is live",
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                    const SizedBox(height: 2),
                    const DropCountdown(),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textMuted),
            ],
          ),
        ),
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
        if (!_dropDone) _buildDropBanner(),
        if (_trayWeekCount > 0 && _filter != 'filtered') _buildDigestChip(),
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
      return Center(child: CircularProgressIndicator(color: context.colors.accent));
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.roseLight, fontSize: 13)),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }
    final items = _filtered;
    final isTray = _filter == 'filtered';
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 90),
          Icon(isTray ? Icons.shield_outlined : Icons.inbox_outlined,
              size: 52, color: context.colors.textFaint),
          const SizedBox(height: 12),
          Text(
            isTray ? 'Nothing held' : 'No messages yet',
            textAlign: TextAlign.center,
            style: context.type.bodyBase.copyWith(fontWeight: FontWeight.w700, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            isTray
                ? 'Messages your filters catch will wait here for review.'
                : (_filter == 'all'
                    ? 'Share your link and wait for the first anonymous message to arrive.'
                    : 'Nothing here in this filter.'),
            textAlign: TextAlign.center,
            style: context.type.bodySm,
          ),
          if (!isTray) ...[
            const SizedBox(height: 20),
            const Center(
              child: _ShareLinkButton(),
            ),
          ],
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
        if (isTray) {
          return _TrayCard(
            message: m,
            onApprove: () => _approveHeld(m),
            onDiscard: () => _discardHeld(m),
          );
        }
        return _MessageCard(message: m, onTap: () => _openMessage(m));
      },
    );
  }

  Future<void> _approveHeld(AnonymousMessage m) async {
    try {
      await ApiClient.approveMessage(m.id);
      if (!mounted) return;
      setState(() => _tray = _tray.where((x) => x.id != m.id).toList());
      showSuccessSnack(context, 'Released to your inbox');
      unawaited(_load());
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not release message');
    }
  }

  Future<void> _discardHeld(AnonymousMessage m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete this message?',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('It will be permanently removed. The sender is never told.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep', style: TextStyle(color: context.colors.accentSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: context.colors.roseLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.discardMessage(m.id);
      if (!mounted) return;
      setState(() => _tray = _tray.where((x) => x.id != m.id).toList());
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context, 'Could not delete message');
    }
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
        }, onBlocked: () {
          if (!mounted) return;
          setState(() {
            _messages?.removeWhere((x) => x.id == m.id);
          });
        }),
      ),
    );
  }
}

/// A held message awaiting review: content + reason, approve or discard.
/// The sender is never told either way.
class _TrayCard extends StatelessWidget {
  final AnonymousMessage message;
  final VoidCallback onApprove;
  final VoidCallback onDiscard;
  const _TrayCard({required this.message, required this.onApprove, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  message.quarantineReason == 'hidden-word' ? 'Held: filtered word' : 'Held for review',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.colors.amberLight),
                ),
              ),
              const Spacer(),
              Text(
                message.createdAt.length >= 10 ? message.createdAt.substring(0, 10) : message.createdAt,
                style: TextStyle(fontSize: 10.5, color: context.colors.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.content,
              style: TextStyle(fontSize: 13.5, height: 1.5, color: context.colors.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDiscard,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.roseLight,
                    side: BorderSide(color: context.colors.border),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.emerald,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareLinkButton extends StatelessWidget {  const _ShareLinkButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: Colors.white),
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
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? context.colors.accent.withValues(alpha: 0.45) : context.colors.border,
          ),
          boxShadow: unread
              ? [
                  BoxShadow(
                    color: context.colors.accent.withValues(alpha: 0.12),
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
                      color: context.colors.textPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.accent.withValues(alpha: 0.5),
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
                  Icon(Icons.push_pin, size: 13, color: context.colors.amber),
                  const SizedBox(width: 6),
                ],
                if (message.deviceHint != null && message.deviceHint!.isNotEmpty) ...[
                  StitchPill(message.deviceHint!),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  _formatTime(message.createdAt),
                  style: context.type.bodySm.copyWith(color: context.colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.type.bodyBase.copyWith(fontSize: 15, height: 1.5),
            ),
            if (replied) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.emerald.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 14, color: context.colors.emeraldSoft),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.replyContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.colors.emeraldLight, fontSize: 12),
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
  final VoidCallback? onBlocked;
  const _MessageDetailScreen({required this.message, required this.onReplied, this.onBlocked});

  @override
  State<_MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<_MessageDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  bool _reported = false;
  bool _blocking = false;

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

  Future<void> _block() async {
    if (_blocking) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Block this sender?', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'This sender''s device will no longer reach your inbox. Their identity stays anonymous to you — you are blocking the device, not a person. The message will be removed.',
          style: TextStyle(color: context.colors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.roseLight),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _blocking = true);
    try {
      await ApiClient.blockSender(widget.message.id);
      widget.onBlocked?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Sender blocked and message removed.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _blocking = false);
      showErrorSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    final replied = m.replyContent != null && m.replyContent!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('Message', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
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
                          Icon(Icons.person_outline, color: context.colors.accent, size: 18),
                          const SizedBox(width: 8),
                          Text('Anonymous Sender', style: context.type.bodySm),
                          const Spacer(),
                          if (m.deviceHint != null && m.deviceHint!.isNotEmpty)
                            StitchPill(m.deviceHint!),
                          if (m.isPinned == 1) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.push_pin, color: context.colors.amber, size: 15),
                          ],
                        ],
                      ),
                      Divider(color: context.colors.border, height: 24),
                      Text(m.content, style: context.type.bodyBase.copyWith(fontSize: 15, height: 1.55)),
                      const SizedBox(height: 12),
                      Text(_formatTime(m.createdAt), style: context.type.bodySm.copyWith(color: context.colors.textMuted)),
                    ],
                  ),
                ),
                if (replied) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.emerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.emerald.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.reply, color: context.colors.emeraldSoft, size: 16),
                            const SizedBox(width: 6),
                            Text('Your blind reply', style: TextStyle(color: context.colors.emeraldLight, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(m.replyContent!, style: context.type.bodySm.copyWith(color: context.colors.emeraldLight, height: 1.5)),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text('Reply double-blind', style: context.type.titleSm),
                  const SizedBox(height: 4),
                  Text(
                    'Your reply is shown back to the sender anonymously via their private claim link — your identity stays hidden.',
                    style: context.type.bodySm.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 5,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Write a blind reply…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _sending || _replyCtrl.text.trim().isEmpty ? null : _sendReply,
                    child: _sending
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
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
                      style: TextButton.styleFrom(foregroundColor: context.colors.roseLight),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _blocking ? null : _block,
                      icon: _blocking
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.block_outlined, size: 15),
                      label: Text(_blocking ? 'Blocking…' : 'Block sender'),
                      style: TextButton.styleFrom(foregroundColor: context.colors.roseLight),
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
