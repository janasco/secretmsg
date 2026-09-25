import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/screens/inbox_screen.dart';
import 'package:secretmsg_mobile/screens/sticker_studio_screen.dart';
import 'package:secretmsg_mobile/theme.dart';
import 'package:secretmsg_mobile/widgets/share_export.dart';
import 'package:secretmsg_mobile/widgets/turnstile_widget.dart';

import 'secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(clearStoredTokenMock);

  testWidgets('inbox bootstrap future completing after disposal is ignored',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final token = Completer<String?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return token.future;
      return null;
    });

    await tester.pumpWidget(const MaterialApp(home: InboxScreen()));
    await tester.pumpWidget(const SizedBox.shrink());

    token.complete('token');
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Turnstile error callback is ignored after disposal',
      (tester) async {
    var errors = 0;
    await tester.pumpWidget(MaterialApp(
      home: TurnstileWidget(
        siteKey: '',
        onError: (_) => errors++,
      ),
    ));
    expect(errors, 1);
    final state = tester.state<TurnstileWidgetState>(
      find.byType(TurnstileWidget),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    state.handleError('late');
    expect(errors, 1);
  });

  testWidgets('sticker studio disposes its text controllers', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockStoredToken(null);
    final directory = Directory.systemTemp.createTempSync('sticker-test');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async => directory.path);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const StickerStudioScreen(),
    ));
    await tester.pump();

    final controllers = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller)
        .whereType<TextEditingController>()
        .toList();
    expect(controllers, hasLength(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    directory.deleteSync(recursive: true);
  });

  testWidgets('shared capture is deleted after sharing', (tester) async {
    final directory = Directory.systemTemp.createTempSync('share-test');
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    String? capturedPath;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async => directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      capturedPath = (args['paths'] as List<dynamic>).single as String;
      return 'shared';
    });

    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
              width: 100, height: 100, child: ColoredBox(color: Colors.indigo)),
        ),
      ),
    ));

    final shared = await tester.runAsync(() => sharePng(key));
    expect(shared, true);
    expect(capturedPath, isNotNull);
    expect(File(capturedPath!).existsSync(), false);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
    directory.deleteSync(recursive: true);
  });
}
