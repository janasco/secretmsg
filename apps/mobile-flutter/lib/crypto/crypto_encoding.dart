// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// base64url helpers (RFC 4648 §5, no padding) shared by every crypto file.
// `dart:convert`'s base64Url emits padding; these helpers strip it on encode
// and restore it on decode so Dart, the Worker, and the browser all produce
// identical strings.
library;

import 'dart:convert';
import 'dart:typed_data';

class CryptoEncoding {
  CryptoEncoding._();

  /// Encodes [bytes] as unpadded base64url.
  static String b64url(List<int> bytes) {
    final encoded = base64UrlEncode(bytes);
    return encoded.replaceAll('=', '');
  }

  /// Decodes unpadded (or padded) base64url to bytes.
  ///
  /// Throws [FormatException] on invalid input rather than returning partial
  /// data; callers treat a malformed key or envelope as a hard failure.
  static Uint8List b64urlDecode(String input) {
    final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final padLength = (4 - normalized.length % 4) % 4;
    final padded = normalized + ('=' * padLength);
    return base64Url.decode(padded);
  }

  /// True when [input] is exactly a 32-byte unpadded base64url value. Used to
  /// validate device public keys and handed-over content keys.
  static bool isB64url32(String input) {
    if (input.length != 43 || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(input)) {
      return false;
    }
    try {
      return b64urlDecode(input).length == 32;
    } on FormatException {
      return false;
    }
  }

  /// Constant-time byte comparison for secrets. Dart's List equality returns
  /// early on the first mismatch; this does not.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
