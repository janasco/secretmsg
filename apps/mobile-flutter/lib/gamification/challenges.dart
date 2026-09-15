/// Daily challenges: rotating set drawn from lifetime + daily-delta metrics.
///
/// The server exposes lifetime counters (received/replies) on GET /api/me.
/// Daily deltas come from a per-account snapshot taken at the first refresh
/// of each calendar day: delta = current - snapshot. All evaluation here is
/// pure (unit-tested); persistence lives in Session.
library;

/// A challenge definition. [metric] selects the counter, [goal] the target.
class ChallengeDef {
  final String id;
  final String title;
  final String hint;
  final String emoji;
  final String metric; // 'received_today' | 'replies_today' | 'streak' | 'score'
  final int goal;

  const ChallengeDef({
    required this.id,
    required this.title,
    required this.hint,
    required this.emoji,
    required this.metric,
    required this.goal,
  });
}

const challengePool = <ChallengeDef>[
  ChallengeDef(id: 'magnet-3', title: 'Magnetism', hint: 'Receive 3 messages today', emoji: '🧲', metric: 'received_today', goal: 3),
  ChallengeDef(id: 'replier-2', title: 'Quick Replies', hint: 'Reply to 2 messages today', emoji: '⚡', metric: 'replies_today', goal: 2),
  ChallengeDef(id: 'streak-2', title: 'On a Roll', hint: 'Keep a 2-day check-in streak', emoji: '🔥', metric: 'streak', goal: 2),
  ChallengeDef(id: 'magnet-1', title: 'Open Doors', hint: 'Receive 1 message today', emoji: '🚪', metric: 'received_today', goal: 1),
  ChallengeDef(id: 'replier-5', title: 'Conversation Mode', hint: 'Reply to 5 messages today', emoji: '💬', metric: 'replies_today', goal: 5),
  ChallengeDef(id: 'streak-7', title: 'Weekly Rhythm', hint: 'Reach a 7-day check-in streak', emoji: '📅', metric: 'streak', goal: 7),
];

/// Deterministic daily rotation: 3 challenges picked by day number so every
/// install shows the same set on the same day. Pure (unit-tested).
List<ChallengeDef> challengesForDay(int dayNumber, {int count = 3}) {
  final out = <ChallengeDef>[];
  for (var i = 0; i < count; i++) {
    out.add(challengePool[(dayNumber + i * 2) % challengePool.length]);
  }
  return out;
}

/// Whole days since the Unix epoch for a calendar day (local time).
int dayNumber(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.difference(DateTime(1970, 1, 1)).inDays;
}

/// Lifetime + daily metric snapshot used to evaluate challenges.
class DayMetrics {
  final int receivedToday;
  final int repliesToday;
  final int streak;
  final int score;

  const DayMetrics({
    required this.receivedToday,
    required this.repliesToday,
    required this.streak,
    required this.score,
  });
}

int metricValue(ChallengeDef def, DayMetrics m) {
  switch (def.metric) {
    case 'received_today':
      return m.receivedToday;
    case 'replies_today':
      return m.repliesToday;
    case 'streak':
      return m.streak;
    case 'score':
      return m.score;
  }
  return 0;
}

/// Progress 0..1 for [def] given metrics (clamped, never divides by zero).
double challengeProgress(ChallengeDef def, DayMetrics m) {
  if (def.goal <= 0) return 1;
  return (metricValue(def, m) / def.goal).clamp(0.0, 1.0);
}

bool challengeDone(ChallengeDef def, DayMetrics m) =>
    metricValue(def, m) >= def.goal;

/// Computes today's deltas and the snapshot to persist. If the stored
/// snapshot is from a previous day (or missing), today's deltas start at
/// zero and the snapshot resets to current lifetime counts. Pure.
({int receivedToday, int repliesToday, String snapshotDate, int snapReceived, int snapReplies}) rollDayDeltas({
  required String? snapshotDate,
  required int snapReceived,
  required int snapReplies,
  required int currentReceived,
  required int currentReplies,
  required String today,
}) {
  if (snapshotDate != today) {
    return (
      receivedToday: 0,
      repliesToday: 0,
      snapshotDate: today,
      snapReceived: currentReceived,
      snapReplies: currentReplies,
    );
  }
  return (
    receivedToday: (currentReceived - snapReceived).clamp(0, 1 << 30),
    repliesToday: (currentReplies - snapReplies).clamp(0, 1 << 30),
    snapshotDate: today,
    snapReceived: snapReceived,
    snapReplies: snapReplies,
  );
}
