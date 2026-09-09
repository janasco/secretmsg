import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/main.dart';

void main() {
  testWidgets('Landing screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecretMsgApp());
    await tester.pump();

    expect(find.text('SecretMsg'), findsOneWidget);
    expect(find.text('The messenger that keeps your secrets'), findsOneWidget);
  });
}