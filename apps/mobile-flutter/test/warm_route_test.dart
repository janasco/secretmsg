import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/main.dart';
import 'package:secretmsg_mobile/ritual/reminders.dart';
import 'package:secretmsg_mobile/screens/daily_drop_screen.dart';
import 'package:secretmsg_mobile/screens/send_screen.dart';

import 'secure_storage_mock.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStoredToken(null);
    pendingRoute.value = null;
  });

  tearDown(() {
    pendingRoute.value = null;
    clearStoredTokenMock();
  });

  test('the drop route opens Daily Drop, not the inbox', () {
    expect(DeepLinkRouter.routeFor('/drop'), isA<DailyDropScreen>());
  });

  testWidgets('a cold notification launch opens its screen', (tester) async {
    pendingRoute.value = '/drop';
    await tester.pumpWidget(const SecretMsgApp());
    await _settle(tester);

    expect(find.byType(DailyDropScreen), findsOneWidget);
  });

  testWidgets('a notification tap while running opens its screen', (tester) async {
    await tester.pumpWidget(const SecretMsgApp());
    await _settle(tester);

    pendingRoute.value = '/drop';
    await tester.pump();
    await tester.pump();
    await _settle(tester);

    expect(find.byType(DailyDropScreen), findsOneWidget);
  });

  testWidgets('a shared link while running reaches the route generator',
      (tester) async {
    await tester.pumpWidget(const SecretMsgApp());
    await _settle(tester);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/janasco');
    await _settle(tester);

    expect(find.byType(SendScreen), findsOneWidget);
    expect((tester.widget<SendScreen>(find.byType(SendScreen))).initialUsername,
        'janasco');
  });
}
