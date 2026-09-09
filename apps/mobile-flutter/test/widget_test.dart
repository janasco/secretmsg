import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/main.dart';

/// flutter_secure_storage talks over a platform channel that does not exist in
/// a test binding. Mocking it keeps the startup path deterministic instead of
/// depending on a MissingPluginException being thrown and swallowed.
const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void mockStoredToken(String? token) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async {
    if (call.method == 'read') return token;
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  testWidgets('signed-out launch lands on the marketing screen', (tester) async {
    mockStoredToken(null);

    await tester.pumpWidget(const SecretMsgApp());
    // The app shows a brief boot state while it reads the stored session.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('SecretMsg'), findsOneWidget);
    expect(find.text('The messenger that keeps your secrets'), findsOneWidget);
  });
}
