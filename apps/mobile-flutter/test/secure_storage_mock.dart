import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_secure_storage talks over a platform channel that does not exist in
/// a test binding. Mocking it keeps startup deterministic instead of depending
/// on a MissingPluginException being thrown and swallowed.
const secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Makes `Session.getToken()` resolve to [token]. Pass null for signed out.
void mockStoredToken(String? token) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async {
    if (call.method == 'read') return token;
    return null;
  });
}

void clearStoredTokenMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, null);
}
