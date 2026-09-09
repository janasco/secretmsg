import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/screens/app_shell.dart';
import 'package:secretmsg_mobile/screens/inbox_screen.dart';
import 'package:secretmsg_mobile/screens/send_screen.dart';
import 'package:secretmsg_mobile/screens/settings_screen.dart';
import 'package:secretmsg_mobile/screens/supporters_screen.dart';

import 'secure_storage_mock.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// A tab label, matched only inside the navigation bar. Several screens use
/// the same word in their own app bar title.
Finder _tabLabel(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

/// Inactive IndexedStack children are offstage, so the default finders report
/// them as absent. Searching offstage too is what distinguishes "built and
/// kept alive" from "never built at all".
Finder _anywhere(Type type) => find.byType(type, skipOffstage: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Signed out keeps the inbox and settings tabs from making network calls.
    mockStoredToken(null);
  });

  tearDown(clearStoredTokenMock);

  testWidgets('shows all four destinations', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await _settle(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Inbox', 'Send', 'Supporters', 'My Link']) {
      expect(_tabLabel(label), findsOneWidget, reason: 'missing the $label tab');
    }
  });

  testWidgets('opens on the requested tab', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(initialTab: AppTab.send)));
    await _settle(tester);

    expect(find.byType(SendScreen), findsOneWidget);
    expect(_anywhere(InboxScreen), findsNothing);
  });

  testWidgets('unvisited tabs are never constructed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await _settle(tester);

    // Only the starting tab exists, so a cold start does not fire four
    // screens' worth of loading at once.
    expect(find.byType(InboxScreen), findsOneWidget);
    expect(_anywhere(SendScreen), findsNothing);
    expect(_anywhere(SupportersScreen), findsNothing);
    expect(_anywhere(SettingsScreen), findsNothing);
  });

  testWidgets('switching tabs keeps the previous one alive', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await _settle(tester);
    expect(find.byType(InboxScreen), findsOneWidget);

    await tester.tap(_tabLabel('Send'));
    await _settle(tester);

    // The composer is now the visible tab.
    expect(find.byType(SendScreen), findsOneWidget);
    // The inbox is still mounted, so its scroll position survives the switch.
    expect(_anywhere(InboxScreen), findsOneWidget);
    // A tab that was never opened still has not been built.
    expect(_anywhere(SupportersScreen), findsNothing);
  });

  testWidgets('back from a secondary tab returns to the inbox', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell(initialTab: AppTab.send)));
    await _settle(tester);
    expect(find.byType(SendScreen), findsOneWidget);

    // Simulate the Android back gesture.
    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.byType(InboxScreen), findsOneWidget);
  });
}
