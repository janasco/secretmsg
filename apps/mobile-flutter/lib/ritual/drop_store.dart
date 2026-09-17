/// Persisted Daily Drop + vibe check-in state (SharedPreferences).
///
/// Day keys (`yyyy-MM-dd`) and a mood emoji — not credentials, so plain
/// preferences (not secure storage) are the right home.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../gamification/streaks.dart' show dayKey;

const String _kDropDoneDay = 'drop_done_day';
const String _kVibeDay = 'vibe_day';
const String _kVibeMood = 'vibe_mood';

/// The five vibe check-in moods.
const List<String> vibeMoods = ['😭', '😐', '🙂', '🤩', '🔥'];

class DropStore {
  DropStore._();

  static Future<bool> isDone(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_kDropDoneDay) ?? '') == dayKey(now);
  }

  static Future<void> markDone(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDropDoneDay, dayKey(now));
  }
}

class VibeStore {
  VibeStore._();

  /// True when today's mood was already tapped.
  static Future<bool> isCheckedIn(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_kVibeDay) ?? '') == dayKey(now);
  }

  static Future<void> checkIn(DateTime now, String mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVibeDay, dayKey(now));
    await prefs.setString(_kVibeMood, mood);
  }
}
