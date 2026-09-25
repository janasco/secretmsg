import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/api/local_data_wipe.dart';
import 'package:secretmsg_mobile/api/session.dart';
import 'package:secretmsg_mobile/sync/cache.dart';
import 'package:secretmsg_mobile/sync/outbox.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureValues = <String, String>{};
  String? secureFailureKey;

  setUp(() async {
    secureValues.clear();
    secureFailureKey = null;
    SharedPreferences.setMockInitialValues({});
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
          if (key == secureFailureKey) {
            throw StateError('storage unavailable');
          }
          secureValues.remove(key);
          return null;
      }
      return null;
    });
    await Session.clearAccountData();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  test('wipes Session, cache, outbox, and ritual account state', () async {
    await Session.setToken('token');
    secureValues['secretmsg_user_profile'] = '{}';
    secureValues['secretmsg_last_seen_rank'] = 'u1|gold';
    await Session.getDeviceFingerprint();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secretmsg_streak', '{}');
    await prefs.setString('secretmsg_day_snapshot', '{}');
    await prefs.setString('secretmsg_badges', '{}');
    await prefs.setString('secretmsg_chdone_2026-09-25', '{}');
    await prefs.setString('streak_count', '3');
    await prefs.setString('streak_last_day', '2026-09-25');
    await prefs.setInt('streak_freezes', 2);
    await prefs.setString('streak_last_repair_iso', '2026-09-25');
    await prefs.setString('drop_done_day', '2026-09-25');
    await prefs.setString('vibe_day', '2026-09-25');
    await prefs.setString('vibe_mood', '🔥');
    await prefs.setBool('rem_drop', true);
    await prefs.setBool('rem_streak', true);
    await prefs.setBool('rem_milestone', true);
    await prefs.setBool('rem_digest', true);
    await InboxCache.save([], []);
    await Outbox.enqueue(
      OutboxKind.report,
      {'messageId': 'm1', 'reason': 'bad'},
      autoDrain: false,
    );

    final result = await AccountDataWipe.wipeAllLocalAccountData();

    expect(result.complete, true);
    expect(secureValues, isEmpty);
    expect(prefs.getString('cache_inbox_v1'), isNull);
    expect(prefs.getString('cache_tray_v1'), isNull);
    expect(prefs.getInt('cache_saved_at_v1'), isNull);
    expect(prefs.getString('outbox_ops_v1'), isNull);
    expect(prefs.getString('secretmsg_streak'), isNull);
    expect(prefs.getString('secretmsg_day_snapshot'), isNull);
    expect(prefs.getString('secretmsg_badges'), isNull);
    expect(prefs.getString('secretmsg_chdone_2026-09-25'), isNull);
    expect(prefs.getString('streak_count'), isNull);
    expect(prefs.getString('streak_last_day'), isNull);
    expect(prefs.getInt('streak_freezes'), isNull);
    expect(prefs.getString('streak_last_repair_iso'), isNull);
    expect(prefs.getString('drop_done_day'), isNull);
    expect(prefs.getString('vibe_day'), isNull);
    expect(prefs.getString('vibe_mood'), isNull);
    expect(prefs.getBool('rem_drop'), isNull);
    expect(prefs.getBool('rem_streak'), isNull);
    expect(prefs.getBool('rem_milestone'), isNull);
    expect(prefs.getBool('rem_digest'), isNull);
    expect(await Outbox.depth(), 0);
    expect(await InboxCache.load(), isNull);
  });

  test('does not throw when local storage is empty', () async {
    final result = await AccountDataWipe.wipeAllLocalAccountData();

    expect(result.complete, true);
  });

  test('collects a subsystem failure and continues wiping other data', () async {
    secureFailureKey = 'secretmsg_device_fingerprint';
    await Session.setToken('token');
    final fingerprint = await Session.getDeviceFingerprint();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('drop_done_day', '2026-09-25');
    await prefs.setString('secretmsg_streak', '{}');

    final result = await AccountDataWipe.wipeAllLocalAccountData();

    expect(result.complete, false);
    expect(result.failures, contains('secure storage'));
    expect(secureValues['secretmsg_device_fingerprint'], fingerprint);
    expect(prefs.getString('drop_done_day'), isNull);
    expect(prefs.getString('secretmsg_streak'), isNull);
  });

  test('sign-out preserves the device fingerprint and ritual preferences', () async {
    final fingerprint = await Session.getDeviceFingerprint();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secretmsg_streak', 'user-progress');
    await prefs.setString('streak_count', '3');
    await prefs.setString('drop_done_day', '2026-09-25');
    await prefs.setString('vibe_day', '2026-09-25');
    await prefs.setString('vibe_mood', 'fire');
    await prefs.setBool('rem_drop', true);
    await prefs.setBool('rem_streak', true);

    await Session.clear();

    expect(await Session.getDeviceFingerprint(), fingerprint);
    expect(prefs.getString('secretmsg_streak'), 'user-progress');
    expect(prefs.getString('streak_count'), '3');
    expect(prefs.getString('drop_done_day'), '2026-09-25');
    expect(prefs.getString('vibe_day'), '2026-09-25');
    expect(prefs.getString('vibe_mood'), 'fire');
    expect(prefs.getBool('rem_drop'), true);
    expect(prefs.getBool('rem_streak'), true);
  });
}
