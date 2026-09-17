/// Ritual reminders: Daily Drop + streak nudges via local notifications.
///
/// Local-first (no server needed): every cold start calls [rescheduleAll],
/// which recomputes today's 9:00 / 20:00 / 21:30 local reminders from the
/// current ritual state and replaces any pending ones. Stale reminders can
/// never survive because scheduling is always derived from now + state.
///
/// Guardrails (from the v2.0 guide): max 2 pushes/day, quiet hours
/// 22:00–08:00, per-type Settings toggles, auto-cancel when the underlying
/// action completes.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const String _channelDrop = 'ritual_drop';
const String _channelStreak = 'ritual_streak';
const String _channelMilestone = 'ritual_milestone';
const String _channelDigest = 'ritual_digest';

const int _idDropMorning = 1001;
const int _idDropEvening = 1002;
const int _idStreakNight = 1003;
const int _idDigestWeekly = 1004;

/// Max pushes per calendar day (guide §2.4).
const int maxPushesPerDay = 2;

const String prefDropEnabled = 'rem_drop';
const String prefStreakEnabled = 'rem_streak';
const String prefMilestoneEnabled = 'rem_milestone';
const String prefDigestEnabled = 'rem_digest';

/// Route payload the app should open when launched from a notification tap.
/// Written by the tap handler, consumed once by `main()` after init.
String? pendingRoute;

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

bool _ready = false;

/// Computes today's candidate reminder times (local wall clock).
/// Pure: the service filters these by state, caps, and quiet hours.
List<({int id, int hour, int minute, String channel})> reminderSlots() => const [
      (id: _idDropMorning, hour: 9, minute: 0, channel: _channelDrop),
      (id: _idDropEvening, hour: 20, minute: 0, channel: _channelDrop),
      (id: _idStreakNight, hour: 21, minute: 30, channel: _channelStreak),
    ];

/// Quiet hours 22:00–08:00: no reminder may fire inside.
bool inQuietHours(DateTime t) => t.hour >= 22 || t.hour < 8;

/// Next Saturday 10:00 local (today if still ahead). Weekly digest day.
DateTime nextSaturday10(DateTime now) {
  var d = DateTime(now.year, now.month, now.day, 10, 0);
  var delta = (DateTime.saturday - d.weekday) % 7;
  if (delta == 0 && !d.isAfter(now)) delta = 7;
  return d.add(Duration(days: delta));
}

/// Next local wall-clock occurrence of [hour]:[minute] strictly after [now].
DateTime nextOccurrence(DateTime now, int hour, int minute) {
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  return next;
}

Future<void> initReminders() async {
  if (_ready) return;
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (_) {
    // Unknown zone: fall back to UTC rather than crashing boot.
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _plugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      final payload = resp.payload;
      if (payload != null && payload.isNotEmpty) pendingRoute = payload;
    },
  );

  const dropChannel = AndroidNotificationChannel(
    _channelDrop, 'Daily Drop',
    description: 'Your daily prompt card and its expiry nudge',
    importance: Importance.defaultImportance,
  );
  const streakChannel = AndroidNotificationChannel(
    _channelStreak, 'Streaks',
    description: 'Nightly nudge to keep your check-in streak alive',
    importance: Importance.defaultImportance,
  );
  const digestChannel = AndroidNotificationChannel(
    _channelDigest, 'Weekly review',
    description: 'Saturday roundup of held messages waiting for review',
    importance: Importance.defaultImportance,
  );
  const milestoneChannel = AndroidNotificationChannel(
    _channelMilestone, 'Milestones',
    description: 'Rank-ups and streak milestones',
    importance: Importance.high,
  );
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(dropChannel);
  await android?.createNotificationChannel(streakChannel);
  await android?.createNotificationChannel(digestChannel);
  await android?.createNotificationChannel(milestoneChannel);

  // Cold start from a notification tap: capture the payload route.
  final launch = await _plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    final payload = launch!.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) pendingRoute = payload;
  }
  _ready = true;
}

/// Android 13+ runtime permission. Returns true when notifications allowed.
Future<bool> requestReminderPermission() async {
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  return await android?.requestNotificationsPermission() ?? false;
}

/// Android 12+ exact-alarm gate. When false, reminders fall back to
/// inexact scheduling (still delivered, timing approximate).
Future<bool> exactAlarmAllowed() async {
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  return await android?.canScheduleExactNotifications() ?? false;
}

Future<bool> _toggle(String key, bool fallback) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key) ?? fallback;
}

/// Recomputes and replaces today's reminders from current ritual state.
/// Call on every cold start and after drop-answer / check-in events.
Future<void> rescheduleAll({
  required DateTime now,
  required bool dropAnswered,
  required bool checkedInToday,
  required int streakCount,
  required String dropPrompt,
  int filteredWeekCount = 0,
}) async {
  if (!_ready) return;
  final prefs = await SharedPreferences.getInstance();
  final dropOn = prefs.getBool(prefDropEnabled) ?? true;
  final streakOn = prefs.getBool(prefStreakEnabled) ?? true;
  final digestOn = prefs.getBool(prefDigestEnabled) ?? true;

  await _plugin.cancel(_idDropMorning);
  await _plugin.cancel(_idDropEvening);
  await _plugin.cancel(_idStreakNight);
  await _plugin.cancel(_idDigestWeekly);

  final exact = await exactAlarmAllowed();
  final mode = exact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  final candidates = <({int id, DateTime at, String title, String body, String channel, String payload})>[];
  if (dropOn && !dropAnswered) {
    candidates.add((
      id: _idDropMorning,
      at: nextOccurrence(now, 9, 0),
      title: "Today's Drop is live 🔥",
      body: dropPrompt,
      channel: _channelDrop,
      payload: '/drop',
    ));
    candidates.add((
      id: _idDropEvening,
      at: nextOccurrence(now, 20, 0),
      title: "Today's Drop expires soon ⏳",
      body: 'A few hours left — answer before midnight.',
      channel: _channelDrop,
      payload: '/drop',
    ));
  }
  if (streakOn && !checkedInToday && streakCount > 0) {
    candidates.add((
      id: _idStreakNight,
      at: nextOccurrence(now, 21, 30),
      title: 'Keep your $streakCount-day streak alive 🔥',
      body: 'One quick check-in before bed.',
      channel: _channelStreak,
      payload: '/inbox',
    ));
  }

  // Weekly moderation digest: only when something actually waits, outside
  // the daily cap (at most one per week by construction).
  if (digestOn && filteredWeekCount > 0) {
    final at = nextSaturday10(now);
    await _plugin.zonedSchedule(
      _idDigestWeekly,
      'Your filtered tray is waiting 🛡️',
      '$filteredWeekCount ${filteredWeekCount == 1 ? 'message needs' : 'messages need'} your review.',
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(_channelDigest, _channelDigest,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority),
      ),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/inbox',
    );
  }

  // Only today's occurrences count; cap at [maxPushesPerDay], earliest first.
  final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  candidates.retainWhere((c) => c.at.isBefore(tomorrow) && !inQuietHours(c.at));
  candidates.sort((a, b) => a.at.compareTo(b.at));
  final picked = candidates.take(maxPushesPerDay).toList();

  for (final c in picked) {
    await _plugin.zonedSchedule(
      c.id,
      c.title,
      c.body,
      tz.TZDateTime.from(c.at, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(c.channel, c.channel,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority),
      ),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: c.payload,
    );
  }
}

/// Cancels every ritual reminder (logout / toggles all off).
Future<void> cancelAllReminders() async {
  await _plugin.cancel(_idDropMorning);
  await _plugin.cancel(_idDropEvening);
  await _plugin.cancel(_idStreakNight);
  await _plugin.cancel(_idDigestWeekly);
}

/// Immediate milestone push (rank-up). Respects its toggle.
Future<void> showMilestone(String title, String body) async {
  if (!_ready) return;
  if (!await _toggle(prefMilestoneEnabled, true)) return;
  await _plugin.show(
    1100,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(_channelMilestone, _channelMilestone,
          importance: Importance.high, priority: Priority.high),
    ),
    payload: '/inbox',
  );
}
