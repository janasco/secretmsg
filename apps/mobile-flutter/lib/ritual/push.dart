/// Remote push: FCM token lifecycle + message notifications with inline reply.
///
/// Server contract (see `secretmsg-private/api`): data-only messages shaped
/// `{type: 'message:new', message_id, preview, inbox_count}`. The preview is
/// server-truncated — full bodies never travel through FCM. Taps route into
/// the app via the shared [pendingRoute] mechanism from reminders.dart.
///
/// Token registration (`POST /api/push/register`) is best-effort and runs on
/// every cold start while signed in plus on token refresh, so stale tokens
/// self-heal without user action.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import 'reminders.dart' show pendingRoute;

const String _channelPush = 'push_messages';
const int _pushIdBase = 2000;

final FlutterLocalNotificationsPlugin _pushPlugin =
    FlutterLocalNotificationsPlugin();

bool _pushReady = false;

/// Background-isolate entrypoint for FCM data messages received while the
/// app is dead. Re-inits Firebase + a notification plugin (isolates share
/// no plugin state) and renders the message notification.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _pushPlugin.initialize(const InitializationSettings(android: androidInit));
    await showMessageNotification(message);
  } catch (_) {
    // A missed background render is acceptable; the inbox still has it.
  }
}

/// Renders a `message:new` data message as a high-priority notification with
/// an inline Reply action. No-op for unknown types.
Future<void> showMessageNotification(RemoteMessage message) async {
  final data = message.data;
  if (data['type'] != 'message:new') return;
  final messageId = (data['message_id'] ?? '').toString();
  if (messageId.isEmpty) return;
  final preview = (data['preview'] ?? 'Someone sent you a message').toString();
  final count = int.tryParse((data['inbox_count'] ?? '').toString()) ?? 0;

  const person = Person(name: 'Anonymous', key: 'anonymous');
  await _pushPlugin.show(
    _pushIdBase + (messageId.hashCode % 100),
    count > 1 ? 'SecretMsg ($count new)' : 'New secret message',
    preview,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channelPush,
        'Messages',
        channelDescription: 'New anonymous messages with quick reply',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        styleInformation: MessagingStyleInformation(
          person,
          groupConversation: false,
          messages: [Message(preview, DateTime.now(), person)],
        ),
        actions: [
          const AndroidNotificationAction(
            'reply',
            'Reply',
            inputs: [AndroidNotificationActionInput(label: 'Reply anonymously')],
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    ),
    payload: 'msg:$messageId',
  );
}

/// Handles a notification response: reply actions post through the API,
/// plain taps stash a route for `main()` to open.
Future<void> handlePushResponse(NotificationResponse resp) async {
  final payload = resp.payload ?? '';
  if (resp.actionId == 'reply' && payload.startsWith('msg:')) {
    final text = (resp.input ?? '').trim();
    if (text.isEmpty) return;
    try {
      await ApiClient.replyMessage(payload.substring(4), text);
      await _pushPlugin.show(
        _pushIdBase + 99,
        'Reply sent',
        'Your anonymous reply was delivered.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelPush,
            'Messages',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
    } catch (_) {
      await _pushPlugin.show(
        _pushIdBase + 99,
        'Reply failed',
        'Open the app to retry your reply.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelPush,
            'Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    }
    return;
  }
  if (payload.isNotEmpty) pendingRoute = payload.startsWith('msg:') ? '/inbox' : payload;
}

/// One-time init: Firebase, channel, tap handlers, foreground listener.
/// Safe to call while signed out (token registration is skipped then).
Future<void> initPush() async {
  if (_pushReady) return;
  await Firebase.initializeApp();

  const channel = AndroidNotificationChannel(
    _channelPush,
    'Messages',
    description: 'New anonymous messages with quick reply',
    importance: Importance.high,
  );
  final android = _pushPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(channel);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _pushPlugin.initialize(
    const InitializationSettings(android: androidInit),
    onDidReceiveNotificationResponse: handlePushResponse,
    onDidReceiveBackgroundNotificationResponse: pushResponseBackgroundHandler,
  );
  FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);

  FirebaseMessaging.onMessage.listen((msg) async {
    try {
      await showMessageNotification(msg);
    } catch (_) {}
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    try {
      await registerPushToken(token);
    } catch (_) {}
  });

  _pushReady = true;
}

/// Background-isolate entrypoint for notification *action* taps (e.g. the
/// inline reply typed while the app is dead).
@pragma('vm:entry-point')
Future<void> pushResponseBackgroundHandler(NotificationResponse resp) async {
  try {
    await handlePushResponse(resp);
  } catch (_) {}
}

/// Sends the current FCM token to the backend. No-op while signed out.
/// Best-effort by design — callers must not surface failures.
Future<void> registerPushToken([String? token]) async {
  try {
    final saved = await Session.getToken();
    if (saved == null || saved.isEmpty) return;
    final t = token ?? await FirebaseMessaging.instance.getToken();
    if (t == null || t.isEmpty) return;
    await ApiClient.registerPushToken(t);
  } catch (_) {}
}

bool _registeredThisProcess = false;

/// Idempotent registration for hot paths (e.g. inbox load after a fresh
/// login, which never passes through cold-start routing).
Future<void> registerPushTokenOnce() async {
  if (_registeredThisProcess) return;
  _registeredThisProcess = true;
  await registerPushToken();
}

/// Android 13+ prompt is handled by the reminders permission flow; this
/// covers the FCM side (harmless on Android, required on iOS).
Future<void> requestPushPermission() async {
  try {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  } catch (_) {}
}
