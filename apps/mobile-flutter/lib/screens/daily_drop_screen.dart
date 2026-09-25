import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api/config.dart';
import '../api/session.dart';
import '../data/vibe_templates.dart';
import '../ritual/daily_drop.dart';
import '../ritual/drop_store.dart';
import '../ritual/reminders.dart';
import '../ritual/streak_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/drop_countdown.dart';

/// Today's Drop: one prompt card, live expiry countdown, answer + share.
///
/// Answering marks the Drop done for the calendar day, refreshes tonight's
/// reminders, and pops `true` so the inbox can refresh its banner.
class DailyDropScreen extends StatefulWidget {
  const DailyDropScreen({super.key});

  @override
  State<DailyDropScreen> createState() => _DailyDropScreenState();
}

class _DailyDropScreenState extends State<DailyDropScreen> {
  late final String _prompt;
  bool _answering = false;

  @override
  void initState() {
    super.initState();
    _prompt =
        VIBE_TEMPLATES[dropIndexForDay(DateTime.now(), VIBE_TEMPLATES.length)].text;
  }

  Future<void> _answer() async {
    if (_answering) return;
    setState(() => _answering = true);
    try {
      final now = DateTime.now();
      await DropStore.markDone(now);
      final streak = await _streakCount();
      await rescheduleAll(
        now: now,
        dropAnswered: true,
        checkedInToday: true,
        streakCount: streak,
        dropPrompt: _prompt,
      );
    } catch (_) {
      // Best-effort refresh; the done-mark above is what matters.
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<int> _streakCount() async {
    final state = await StreakStore.load();
    return state.count;
  }

  Future<void> _shareLink() async {
    var handle = 'yourname';
    try {
      final user = await Session.getSavedUser();
      if (user != null && user.username.isNotEmpty) handle = user.username;
    } catch (_) {}
    final text = '$_prompt\n\nSend me yours anonymously — ${shareUrlFor(handle)}';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: const AppTopBar(title: "Today's Drop"),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2356), Color(0xFF151B26)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: context.colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '🔥 DAILY DROP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: context.colors.amberLight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const DropCountdown(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _prompt,
                  style: context.type.titleSm.copyWith(height: 1.45, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share it out and collect anonymous answers — or answer it yourself. Gone at midnight.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _answering ? null : _answer,
            icon: _answering
                ? SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
                : const Icon(Icons.check, size: 18),
            label: Text(_answering ? 'Saving…' : 'I answered it'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              minimumSize: const Size.fromHeight(50),
              side: BorderSide(color: context.colors.borderStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _shareLink,
            icon: const Icon(Icons.ios_share, size: 17),
            label: const Text('Share my link with this Drop'),
          ),
        ],
      ),
    );
  }
}
