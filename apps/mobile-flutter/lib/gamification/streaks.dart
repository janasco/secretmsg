/// Daily check-in streaks: pure date-roll logic (unit-tested).
///
/// A "check-in" is any successful authenticated refresh (inbox or profile
/// load). Consecutive calendar days grow the streak; a missed day resets it
/// to 1. All date math uses calendar days (yyyy-MM-dd), never durations, so
/// DST shifts can't corrupt the count.
library;

/// Calendar-day key for [date] (local time): `2026-09-15`.
String dayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// Rolls a streak forward given the stored last check-in day. Returns
/// `(count, lastDay)`. Pure: pass explicit days in tests, `dayKey(now)` live.
({int count, String lastDay}) rollStreak({
  required String? storedLastDay,
  required int storedCount,
  required String today,
}) {
  if (storedLastDay == null || storedLastDay.isEmpty) {
    return (count: 1, lastDay: today);
  }
  if (storedLastDay == today) {
    return (count: storedCount < 1 ? 1 : storedCount, lastDay: today);
  }
  DateTime? last;
  DateTime? now;
  try {
    last = DateTime.parse(storedLastDay);
    now = DateTime.parse(today);
  } catch (_) {
    return (count: 1, lastDay: today);
  }
  final lastDayOnly = DateTime(last.year, last.month, last.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  final gap = todayOnly.difference(lastDayOnly).inDays;
  if (gap == 1) {
    return (count: storedCount + 1, lastDay: today);
  }
  if (gap <= 0) {
    // Clock moved backwards: keep the streak, adopt today.
    return (count: storedCount < 1 ? 1 : storedCount, lastDay: today);
  }
  return (count: 1, lastDay: today);
}

/// Applies a missed day to a streak that supports freezes.
///
/// A freeze pauses the count instead of resetting it (the missed day is not
/// counted, and `lastDay` is left for the caller to advance on next
/// check-in). Without a freeze the streak resets to 1, matching [rollStreak].
/// Pure: the caller persists the returned count/freezes.
({int count, int freezes, bool froze}) applyMiss({
  required int storedCount,
  required int freezes,
}) {
  final safe = storedCount < 1 ? 1 : storedCount;
  if (freezes > 0) {
    return (count: safe, freezes: freezes - 1, froze: true);
  }
  return (count: 1, freezes: freezes, froze: false);
}

/// Streaks earn one freeze, holding at most [maxFreezes]. Call on every
/// 7-day milestone (caller tracks the milestone, this just caps).
int earnFreeze(int freezes, {int maxFreezes = 1}) =>
    freezes >= maxFreezes ? maxFreezes : freezes + 1;

/// Whether a broken streak may be repaired (supporter perk): within 48 h of
/// the break and at most once per 30 days. Pure: the caller persists the
/// restored count and the repair timestamp.
bool canRepair({
  required DateTime brokenAt,
  required DateTime now,
  required DateTime? lastRepairAt,
}) {
  if (now.isBefore(brokenAt)) return false;
  if (now.difference(brokenAt) > const Duration(hours: 48)) return false;
  if (lastRepairAt != null && now.difference(lastRepairAt) < const Duration(days: 30)) {
    return false;
  }
  return true;
}
