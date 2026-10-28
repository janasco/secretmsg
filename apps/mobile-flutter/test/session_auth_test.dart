import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/api/api_client.dart';
import 'package:secretmsg_mobile/api/session.dart';
import 'package:secretmsg_mobile/ritual/push.dart';
import 'package:secretmsg_mobile/sync/outbox.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureValues = <String, String>{};

  setUp(() async {
    secureValues.clear();
    SharedPreferences.setMockInitialValues({});
    Session.onSessionCleared = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      final arguments = call.arguments as Map;
      final key = arguments['key'] as String?;
      switch (call.method) {
        case 'write':
          secureValues[key!] = arguments['value'] as String;
          return null;
        case 'read':
          return secureValues[key];
        case 'delete':
          secureValues.remove(key);
          return null;
      }
      return null;
    });
    await Outbox.clearAll();
  });

  tearDown(() {
    Session.onSessionCleared = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  Future<void> signedInWithCaches() async {
    await Session.setToken('live-token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_inbox_v1', '[]');
    await prefs.setString('cache_tray_v1', '[]');
    await prefs.setInt('cache_saved_at_v1', 1);
    await Outbox.enqueue(
      OutboxKind.reply,
      {'messageId': 'm1', 'reply': 'hello'},
      autoDrain: false,
    );
  }

  test('a wrong current PIN is an API error, not a dead session', () async {
    await signedInWithCaches();

    await expectLater(
      ApiClient.decodeResponseForTest(
        http.Response('{"error":"Current PIN incorrect"}', 401),
        authenticated: true,
        credentialCheck: true,
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.message, 'message', 'Current PIN incorrect')),
    );

    expect(await Session.getToken(), 'live-token');
    expect(secureValues['secretmsg_auth_token'], 'live-token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cache_inbox_v1'), '[]');
    expect(await Outbox.depth(), 1);
  });

  test('a 401 without a bearer token never clears a live session', () async {
    await signedInWithCaches();

    await expectLater(
      ApiClient.decodeResponseForTest(
        http.Response('{"error":"Invalid handle or PIN"}', 401),
        credentialCheck: true,
      ),
      throwsA(isA<ApiException>()),
    );

    expect(await Session.getToken(), 'live-token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cache_inbox_v1'), '[]');
    expect(await Outbox.depth(), 1);
  });

  test('a dead bearer session clears token, caches, queue, and push', () async {
    await signedInWithCaches();
    var pushCleared = 0;
    Session.onSessionCleared = () async => pushCleared++;

    await expectLater(
      ApiClient.decodeResponseForTest(
        http.Response('{"error":"Unauthorized"}', 401),
        authenticated: true,
      ),
      throwsA(isA<UnauthorizedError>()),
    );

    expect(await Session.getToken(), isNull);
    expect(secureValues['secretmsg_auth_token'], isNull);
    expect(secureValues['secretmsg_user_profile'], isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cache_inbox_v1'), isNull);
    expect(prefs.getString('cache_tray_v1'), isNull);
    expect(prefs.getInt('cache_saved_at_v1'), isNull);
    expect(await Outbox.depth(), 0);
    expect(pushCleared, 1);
  });

  test('Session.clear removes account caches and invokes the push hook', () async {
    await signedInWithCaches();
    var pushCleared = 0;
    Session.onSessionCleared = () async => pushCleared++;

    await Session.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cache_inbox_v1'), isNull);
    expect(prefs.getString('cache_tray_v1'), isNull);
    expect(prefs.getInt('cache_saved_at_v1'), isNull);
    expect(await Outbox.depth(), 0);
    expect(pushCleared, 1);
  });

  test('push previews are dropped when there is no live session', () {
    expect(pushSessionActive('token'), true);
    expect(pushSessionActive(null), false);
    expect(pushSessionActive(''), false);
  });
}
