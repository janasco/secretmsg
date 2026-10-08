// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Opt-in report disclosure.
//
// The moderation model keeps reports useful without letting the server read
// every body. When the recipient chooses to hand a message to moderators:
//
//   1. The client re-decrypts the stored envelope with the content key it
//      already holds. If that fails, nothing is disclosed and nothing is
//      sent — a reporter cannot accidentally submit the wrong key.
//   2. The client sends the content key to POST /api/crypto/report.
//   3. The server decrypts the stored envelope with the handed-over key.
//      Only if AES-GCM authentication succeeds does it store any plaintext,
//      in report_disclosures, next to the report row. On failure it rejects
//      and stores nothing.
//
// The opt-in is per report and per message. Decline (or omit the key) and the
// report is still filed, reviewed on metadata only. Once disclosed, the
// plaintext is visible to whoever can review reports and is covered by the
// service's data-retention commitments — the client copy must say so before
// the user confirms.
library;

import 'dart:convert';

import 'message_crypto.dart';
import 'crypto_encoding.dart';

/// Result of the local pre-check. A payload is only produced when the key
/// actually decrypts the stored envelope on this device.
class DisclosureResult {
  final bool verified;
  final Map<String, dynamic>? payload;
  final String? error;

  const DisclosureResult._({required this.verified, this.payload, this.error});

  static const DisclosureResult failed = DisclosureResult._(
    verified: false,
    error: 'This device cannot decrypt that message, so no key was shared.',
  );
}

class ReportDisclosure {
  ReportDisclosure._();

  /// Shown next to the opt-in toggle before any key is sent.
  static const String optInTitle = 'Share this message with moderators';
  static const String optInBody =
      'Only do this if you are comfortable with the message text being '
      'stored and reviewed by the moderation team. If you skip it, your '
      'report is still filed and reviewed using timestamps and metadata, '
      'but nobody can read the message itself.';
  static const String optInConfirmLabel = 'Share message text';

  /// Verifies that [contentKey] decrypts [bodyEnvelope] and, only then,
  /// builds the JSON payload for `POST /api/crypto/report`.
  ///
  /// The server performs the same verification; the local check exists so a
  /// user never hands over a key that cannot be used, but it is not a
  /// substitute for the server's check.
  static Future<DisclosureResult> build({
    required String messageId,
    required String reason,
    required List<int> contentKey,
    required String bodyEnvelope,
  }) async {
    if (contentKey.length != 32 || messageId.isEmpty || reason.trim().isEmpty) {
      return DisclosureResult.failed;
    }
    try {
      final plaintext = await MessageCrypto.decryptWithContentKey(
        envelope: bodyEnvelope,
        contentKey: contentKey,
      );
      if (plaintext.isEmpty) return DisclosureResult.failed;
    } catch (_) {
      // Wrong key, tampered ciphertext, or a legacy plaintext body: refuse to
      // disclose. The failure is intentionally not distinguished.
      return DisclosureResult.failed;
    }
    return DisclosureResult._(
      verified: true,
      payload: <String, dynamic>{
        'messageId': messageId,
        'reason': reason.trim(),
        'contentKey': CryptoEncoding.b64url(contentKey),
        'disclosure': 'plaintext-on-verify-v1',
      },
    );
  }

  /// Debugging helper: a short, non-reversible fingerprint of a disclosed key.
  /// Never render this as if it were the key.
  static String keyFingerprint(List<int> contentKey) {
    if (contentKey.length != 32) return '<invalid>';
    // Not a security boundary; just makes logs distinguishable.
    final encoded = base64Url.encode(contentKey);
    return encoded.substring(0, 6);
  }
}
