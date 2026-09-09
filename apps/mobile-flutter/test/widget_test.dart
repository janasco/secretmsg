import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/main.dart';

import 'secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(clearStoredTokenMock);

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
