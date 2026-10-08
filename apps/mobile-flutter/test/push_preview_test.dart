// NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
// protocol; passing these tests does not make it secure.
//
// Tests for device-generated push previews. Mirrors the truncation rule the
// Worker used at api/src/fcm.ts:163 before the body became unreadable to it.

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/crypto/push_preview.dart';

void main() {
  test('short content passes through unchanged', () {
    expect(PushPreview.fromContent('hello'), 'hello');
  });

  test('exactly 140 characters is not truncated', () {
    final content = 'a' * 140;
    expect(PushPreview.fromContent(content), content);
  });

  test('141 characters truncates to 140 plus the ellipsis', () {
    final content = 'a' * 141;
    final preview = PushPreview.fromContent(content);
    expect(preview.length, 141);
    expect(preview, '${'a' * 140}…');
  });

  test('the ellipsis is U+2026, matching the server implementation', () {
    final preview = PushPreview.fromContent('x' * 500);
    expect(preview.codeUnitAt(140), 0x2026);
    expect(preview.substring(0, 140), 'x' * 140);
  });

  test('empty content stays empty', () {
    expect(PushPreview.fromContent(''), '');
  });
}
