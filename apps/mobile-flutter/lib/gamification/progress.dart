/// Progress orchestration: rolls streaks + daily snapshots, evaluates
/// badges and challenges, and reports what to persist and celebrate.
///
/// Split into a pure core ([evaluateProgress], unit-tested) and a thin I/O
/// shell ([refreshProgress]) that reads/writes Session. All stored docs are
/// scoped by account: a different login starts fresh instead of inheriting
/// another account's streaks, badges, or snapshots.
library;

import '../api/models.dart';
import '../api/session.dart';
import 'badges.dart';
import 'challenges.dart';
import 'streaks.dart';

class ProgressUpdate {
  final int streak;
  final DayMetrics metrics;
  final List<ChallengeDef> todaysChallenges;
  final Set<String> unlockedBadgeIds;
  final List<BadgeDef> freshBadges;
  final List<ChallengeDef> freshChallenges;
  final Map<String, dynamic> streakDoc;
  final Map<String, dynamic> dayDoc;
  final Map<String, dynamic> badgesDoc;
  final List<String> doneIds;

  const ProgressUpdate({
    required this.streak,
    required this.metrics,
    required this.todaysChallenges,
    required this.unlockedBadgeIds,
    required this.freshBadges,
    required this.freshChallenges,
    required this.streakDoc,
    required this.dayDoc,
    required this.badgesDoc,
    required this.doneIds,
  });
}

ProgressUpdate evaluateProgress({
  required UserProfile user,
  required String today,
  required int dayNumber,
  Map<String, dynamic>? streakDoc,
  Map<String, dynamic>? dayDoc,
  Map<String, dynamic>? badgesDoc,
  List<String> seenDoneIds = const [],
}) {
  final uid = user.id;

  // --- Streak (scoped: foreign doc resets) ---
  final ownStreak = streakDoc != null && streakDoc['userId'] == uid;
  final rolled = rollStreak(
    storedLastDay: ownStreak ? streakDoc['last']?.toString() : null,
    storedCount: ownStreak ? (streakDoc['count'] as num?)?.toInt() ?? 0 : 0,
    today: today,
  );
  final newStreakDoc = {'userId': uid, 'count': rolled.count, 'last': rolled.lastDay};

  // --- Daily deltas (scoped the same way) ---
  final ownDay = dayDoc != null && dayDoc['userId'] == uid;
  final deltas = rollDayDeltas(
    snapshotDate: ownDay ? dayDoc['date']?.toString() : null,
    snapReceived: ownDay ? (dayDoc['received'] as num?)?.toInt() ?? 0 : 0,
    snapReplies: ownDay ? (dayDoc['replies'] as num?)?.toInt() ?? 0 : 0,
    currentReceived: user.receivedCount,
    currentReplies: user.repliesCount,
    today: today,
  );
  final newDayDoc = {
    'userId': uid,
    'date': deltas.snapshotDate,
    'received': deltas.snapReceived,
    'replies': deltas.snapReplies,
  };

  final metrics = DayMetrics(
    receivedToday: deltas.receivedToday,
    repliesToday: deltas.repliesToday,
    streak: rolled.count,
    score: user.rank.score,
  );

  // --- Badges ---
  final lifetime = LifetimeMetrics(
    received: user.receivedCount,
    replies: user.repliesCount,
    streak: rolled.count,
    rankTier: user.rank.tier,
    isSupporter: user.isSupporter,
  );
  final unlocked = evaluateBadges(lifetime);
  final ownBadges = badgesDoc != null && badgesDoc['userId'] == uid;
  final stored = ownBadges
      ? ((badgesDoc['ids'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{})
      : <String>{};
  final freshBadges = newUnlocks(unlocked, stored);
  final newBadgesDoc = {'userId': uid, 'ids': unlocked.toList()};

  // --- Challenges ---
  final todays = challengesForDay(dayNumber);
  final doneNow = [for (final c in todays) if (challengeDone(c, metrics)) c.id];
  final seen = seenDoneIds.toSet();
  final freshChallenges = [for (final c in todays) if (doneNow.contains(c.id) && !seen.contains(c.id)) c];
  final doneIds = {...seen, ...doneNow}.toList();

  return ProgressUpdate(
    streak: rolled.count,
    metrics: metrics,
    todaysChallenges: todays,
    unlockedBadgeIds: unlocked,
    freshBadges: freshBadges,
    freshChallenges: freshChallenges,
    streakDoc: newStreakDoc,
    dayDoc: newDayDoc,
    badgesDoc: newBadgesDoc,
    doneIds: doneIds,
  );
}

/// I/O shell: loads stored docs, evaluates, persists, and returns the update.
/// [today]/[dayNumber] default to now; tests inject fixed values via
/// [evaluateProgress] instead.
Future<ProgressUpdate> refreshProgress(UserProfile user, {String? today, int? dayNum}) async {
  final now = DateTime.now();
  final day = today ?? dayKey(now);
  final num = dayNum ?? dayNumber(now);
  final update = evaluateProgress(
    user: user,
    today: day,
    dayNumber: num,
    streakDoc: await Session.getStreak(),
    dayDoc: await Session.getDaySnapshot(),
    badgesDoc: await Session.getBadges(),
    seenDoneIds: await Session.getDoneChallenges(day),
  );
  await Session.setStreak(update.streakDoc);
  await Session.setDaySnapshot(update.dayDoc);
  await Session.setBadges(update.badgesDoc);
  await Session.setDoneChallenges(day, update.doneIds);
  return update;
}
