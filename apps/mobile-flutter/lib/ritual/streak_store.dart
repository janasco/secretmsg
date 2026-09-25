/// Persisted check-in streak state (SharedPreferences).
///
/// Wraps the pure date math in `gamification/streaks.dart`: this layer owns
/// loading, saving, milestone freeze earning (every new 7-day multiple), and
/// supporter repairs. Moods/credentials live elsewhere — counts and day keys
/// are not sensitive.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../gamification/streaks.dart';

const String _kCount = 'streak_count';
const String _kLastDay = 'streak_last_day';
const String _kFreezes = 'streak_freezes';
const String _kLastRepair = 'streak_last_repair_iso';

class StreakState {
  final int count;
  final String lastDay;
  final int freezes;
  final DateTime? lastRepairAt;

  const StreakState({
    required this.count,
    required this.lastDay,
    required this.freezes,
    required this.lastRepairAt,
  });

  const StreakState.empty()
      : count = 0,
        lastDay = '',
        freezes = 0,
        lastRepairAt = null;
}

class StreakCheckIn {
  final StreakState state;
  final bool froze;
  final bool earnedFreeze;

  const StreakCheckIn({
    required this.state,
    required this.froze,
    required this.earnedFreeze,
  });
}

class StreakStore {
  StreakStore._();

  static Future<StreakState> load() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? repair;
    final rawRepair = prefs.getString(_kLastRepair);
    if (rawRepair != null && rawRepair.isNotEmpty) {
      repair = DateTime.tryParse(rawRepair);
    }
    return StreakState(
      count: prefs.getInt(_kCount) ?? 0,
      lastDay: prefs.getString(_kLastDay) ?? '',
      freezes: prefs.getInt(_kFreezes) ?? 0,
      lastRepairAt: repair,
    );
  }

  static Future<void> _save(StreakState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCount, s.count);
    await prefs.setString(_kLastDay, s.lastDay);
    await prefs.setInt(_kFreezes, s.freezes);
    if (s.lastRepairAt != null) {
      await prefs.setString(_kLastRepair, s.lastRepairAt!.toIso8601String());
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCount);
    await prefs.remove(_kLastDay);
    await prefs.remove(_kFreezes);
    await prefs.remove(_kLastRepair);
  }

  /// Records a check-in for [now]. Returns the new state plus whether a
  /// freeze absorbed a missed day and whether a 7-day milestone earned one.
  static Future<StreakCheckIn> checkIn(DateTime now) async {
    final today = dayKey(now);
    final prev = await load();

    int count = prev.count;
    int freezes = prev.freezes;
    var froze = false;

    if (prev.lastDay.isEmpty) {
      count = 1;
    } else if (prev.lastDay == today) {
      if (count < 1) count = 1;
    } else {
      DateTime? last;
      try {
        last = DateTime.parse(prev.lastDay);
      } catch (_) {}
      final gap = last == null
          ? 99
          : DateTime(now.year, now.month, now.day)
              .difference(DateTime(last.year, last.month, last.day))
              .inDays;
      if (gap == 1) {
        count = count + 1;
      } else if (gap > 1) {
        final miss = applyMiss(storedCount: count, freezes: freezes);
        count = miss.count;
        freezes = miss.freezes;
        froze = miss.froze;
      }
      // gap <= 0 (clock moved back): keep count, adopt today.
    }

    // Milestone: a freeze for every newly reached 7-day multiple, earned
    // only when the count actually advanced to it today.
    var earned = false;
    if (count > 0 && count % 7 == 0 && count != prev.count) {
      final capped = earnFreeze(freezes);
      earned = capped != freezes;
      freezes = capped;
    }

    final state = StreakState(
      count: count < 1 ? 1 : count,
      lastDay: today,
      freezes: freezes,
      lastRepairAt: prev.lastRepairAt,
    );
    await _save(state);
    return StreakCheckIn(state: state, froze: froze, earnedFreeze: earned);
  }

  /// Supporter repair: restores the pre-break count when [canRepair] allows.
  /// Returns true when a repair was applied.
  static Future<bool> repair(DateTime now, {required bool isSupporter}) async {
    if (!isSupporter) return false;
    final prev = await load();
    if (prev.count < 1 || prev.lastDay.isEmpty) return false;
    DateTime brokenAt;
    try {
      brokenAt = DateTime.parse(prev.lastDay).add(const Duration(days: 1));
    } catch (_) {
      brokenAt = now.subtract(const Duration(days: 1));
    }
    if (!canRepair(brokenAt: brokenAt, now: now, lastRepairAt: prev.lastRepairAt)) {
      return false;
    }
    await _save(StreakState(
      count: prev.count,
      lastDay: dayKey(now),
      freezes: prev.freezes,
      lastRepairAt: now,
    ));
    return true;
  }
}
