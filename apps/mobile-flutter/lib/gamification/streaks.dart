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
