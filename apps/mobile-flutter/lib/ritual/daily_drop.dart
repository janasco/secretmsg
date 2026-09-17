/// Daily Drop: pure pick/expiry logic (unit-tested).
///
/// One prompt card per calendar day, picked deterministically from the local
/// template pool so it works fully offline: `index = dayNumber % poolLength`.
/// Server-driven pools (v2.0) will replace the pool, not this math.
library;

import '../gamification/streaks.dart' show dayKey;

/// Season epoch for day numbering. All Drop math uses local calendar days,
/// never durations, so DST shifts can't corrupt the pick or the countdown.
DateTime get dropEpoch => DateTime(2026, 1, 1);

/// Local calendar days since [dropEpoch] for [date] (can be negative for
/// pre-epoch dates; callers normalize with the pool length).
int dayNumber(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.difference(dropEpoch).inDays;
}

/// Deterministic pool index for [date]. Always in `0 .. poolLength-1`.
int dropIndexForDay(DateTime date, int poolLength) {
  if (poolLength <= 0) throw ArgumentError.value(poolLength, 'poolLength', 'must be positive');
  final n = dayNumber(date);
  return ((n % poolLength) + poolLength) % poolLength;
}

/// Local midnight ending the Drop day containing [now].
DateTime dropExpiresAt(DateTime now) {
  return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
}

/// Time left on today's Drop. Always positive (next midnight is ahead).
Duration dropTimeLeft(DateTime now) => dropExpiresAt(now).difference(now);

/// Whether the Drop for [now]'s calendar day is done. [doneDay] is the
/// stored `dayKey` of the last answered Drop (null/empty = not done).
bool isDropDone(String? doneDay, DateTime now) =>
    doneDay != null && doneDay.isNotEmpty && doneDay == dayKey(now);

/// Human countdown label: "4h 12m", "38m", "52s".
String dropCountdownLabel(Duration left) {
  if (left.isNegative) return '0s';
  final h = left.inHours;
  final m = left.inMinutes.remainder(60);
  final s = left.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}
