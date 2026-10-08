// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Push preview generation, moved to the sending device.
//
// The Worker used to truncate the plaintext body to 140 characters before
// handing it to FCM (api/src/fcm.ts). It cannot do that for an encrypted body,
// so the sender generates the preview and sends it as a separate field.
//
// What changes and what does not:
//   * The server no longer derives the preview from the full body; it stores
//     and forwards only what the sender chose to preview (<= 140 chars).
//   * The preview itself is still visible to the server and to Google's push
//     infrastructure. It is content the sender opted to surface in a lock
//     screen notification. It must never contain the full body.
//   * An empty preview is allowed; the notification then says only that a
//     message arrived.
library;

import 'crypto_constants.dart';

class PushPreview {
  PushPreview._();

  /// Maximum preview length, in UTF-16 code units, matching the previous
  /// server truncation (`content.slice(0, 140)`) and the confirmation copy.
  static const int maxLength = kPushPreviewLength;

  /// Returns at most [maxLength] characters of [content], appending '…' when
  /// truncation happened. Mirrors `content.slice(0, 140) + '…'` exactly for
  /// ASCII and BMP text. A surrogate pair split by the code-unit cut would
  /// render as a replacement glyph, same as the server's old behaviour.
  static String fromContent(String content) {
    if (content.length > maxLength) {
      return '${content.substring(0, maxLength)}…';
    }
    return content;
  }
}
