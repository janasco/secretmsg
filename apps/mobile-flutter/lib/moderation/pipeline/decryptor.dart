import 'dart:typed_data';

/// A stored E2E envelope, exactly as it comes from the server. The moderation
/// pipeline never sees ciphertext internals; it delegates to a
/// [MessageDecryptor] and refuses to proceed on failure.
class EncryptedEnvelope {
  final String messageId;
  final Uint8List payload;

  const EncryptedEnvelope({required this.messageId, required this.payload});
}

/// Plaintext after envelope verification and decryption.
class DecryptedMessage {
  final String messageId;

  /// Verified plaintext. This value is the only form moderation ever touches.
  final String content;

  /// Optional per-message language hint (for example from a reply thread);
  /// the pipeline still runs script detection on the text itself.
  final String? languageHint;

  const DecryptedMessage({
    required this.messageId,
    required this.content,
    this.languageHint,
  });
}

/// Seam for Brief 1's envelope work. The moderation pipeline is defined
/// against this interface so the fixed order (`decrypt -> ... -> render`)
/// is executable and testable before the crypto lands, and so no stage can
/// accidentally run on ciphertext.
abstract interface class MessageDecryptor {
  Future<DecryptedMessage> decrypt(EncryptedEnvelope envelope);
}

/// A decryption or verification failure. Carries no plaintext, no key
/// material and no ciphertext; the message stays unavailable.
class DecryptionFailure implements Exception {
  final String messageId;
  final String reason;

  const DecryptionFailure(this.messageId, this.reason);

  @override
  String toString() => 'DecryptionFailure($messageId): $reason';
}
