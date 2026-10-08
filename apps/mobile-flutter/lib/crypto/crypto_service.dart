// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Orchestration layer: turns the primitives in this directory into the flows
// a screen actually needs (register keys, prepare a send, decrypt an inbox
// row, decrypt a claim-link thread, wipe keys).
//
// The transport is injected so tests can run without a network. Production
// uses CryptoApi, which talks to the routes documented in
// secretmsg-private/api/src/CRYPTO-WIRING.md.
//
// Fallback rule, stated plainly because it is a product decision, not a
// cryptographic one: if the recipient has no registered device key, there is
// nobody to encrypt to. The send falls back to the legacy plaintext route and
// [SendPreparation.e2e] is false; the UI must label it. Sending an envelope
// whose key is wrapped to nobody would be an unrecoverable message.
library;

import 'dart:typed_data';

import 'claim_link.dart';
import 'crypto_encoding.dart';
import 'device_key_store.dart';
import 'filtered_words.dart';
import 'message_crypto.dart';
import 'push_preview.dart';
import 'reinstall_policy.dart';

/// A recipient's registered device keys plus the filter manifest the sender's
/// client must apply before encryption.
class RecipientCrypto {
  final bool e2e;
  final List<RecipientDeviceKey> keys;
  final String filterMode;
  final List<String> hiddenWords;

  const RecipientCrypto({
    required this.e2e,
    this.keys = const [],
    this.filterMode = 'standard',
    this.hiddenWords = const [],
  });
}

/// Everything the send path needs after local preparation.
class SendPreparation {
  /// True when [content] is an encrypted envelope for this transport.
  final bool e2e;

  /// Envelope when [e2e], plaintext otherwise.
  final String content;

  /// Device-generated notification preview (always plaintext-ish and short).
  final String preview;

  /// Whether the local filter matched (advisory flag sent to the server).
  final bool filterMatched;

  /// Strict mode: the client refuses the send locally, same as the server did.
  final bool shouldReject;

  /// Content key when [e2e]; the caller stores it against the reply token so
  /// the claim link can be rebuilt later. Null in legacy mode.
  final Uint8List? contentKey;

  /// Recipient handle echoed for convenience.
  final String username;

  const SendPreparation({
    required this.e2e,
    required this.content,
    required this.preview,
    required this.filterMatched,
    required this.shouldReject,
    required this.username,
    this.contentKey,
  });
}

/// Readability of one stored body on this device.
class DecryptedMessage {
  final HistoryReadability readability;
  final String? text;

  const DecryptedMessage({required this.readability, this.text});
}

/// Contract the service needs from the network. Implemented by CryptoApi.
abstract class CryptoTransport {
  Future<void> registerDeviceKey({
    required String deviceId,
    required String publicKeyB64,
  });

  Future<RecipientCrypto> fetchRecipientCrypto(String username);
}

/// In-memory transport for tests and for builds where the crypto routes are
/// not deployed yet. It never pretends a recipient is encrypted: e2e is false,
/// so sends stay on the legacy path.
class NoCryptoTransport implements CryptoTransport {
  /// When true, [fetchRecipientCrypto] reports e2e with the provided key so
  /// tests can exercise the encrypted path without a server.
  final bool e2e;
  final String? placeholderKid;
  final List<int>? placeholderPublicKey;

  const NoCryptoTransport({
    this.e2e = false,
    this.placeholderKid,
    this.placeholderPublicKey,
  });

  @override
  Future<void> registerDeviceKey({
    required String deviceId,
    required String publicKeyB64,
  }) async {}

  @override
  Future<RecipientCrypto> fetchRecipientCrypto(String username) async {
    if (!e2e || placeholderKid == null || placeholderPublicKey == null) {
      return const RecipientCrypto(e2e: false);
    }
    return RecipientCrypto(
      e2e: true,
      keys: [
        RecipientDeviceKey(kid: placeholderKid!, publicKey: placeholderPublicKey!)
      ],
    );
  }
}

class CryptoService {
  final DeviceKeyStore keyStore;
  final CryptoTransport transport;
  final DeviceSecretStore claimKeyStore;

  CryptoService({
    DeviceKeyStore? keyStore,
    CryptoTransport? transport,
    DeviceSecretStore? claimKeyStore,
  })  : keyStore = keyStore ?? DeviceKeyStore(),
        transport = transport ?? const NoCryptoTransport(),
        claimKeyStore = claimKeyStore ?? const SecureDeviceSecretStore();

  /// Keypair for this install, generating and registering it on first use.
  Future<DeviceKey> ensureDeviceKey() async {
    final key = await keyStore.loadOrCreate();
    await transport.registerDeviceKey(
      deviceId: key.deviceId,
      publicKeyB64: key.publicKeyB64,
    );
    return key;
  }

  /// Prepares a send: filter check first, then encryption, then preview.
  ///
  /// The order is load-bearing. Filtering must happen on plaintext, so it runs
  /// before [MessageCrypto.encryptBody]; the preview is derived from plaintext
  /// for the same reason.
  Future<SendPreparation> prepareSend({
    required String username,
    required String plaintext,
  }) async {
    final recipient = await transport.fetchRecipientCrypto(username);
    final filter = FilteredWords.evaluate(
      content: plaintext,
      mode: recipient.filterMode,
      words: recipient.hiddenWords,
    );
    final preview = PushPreview.fromContent(plaintext);

    // Strict mode refuses the send, exactly as the server did before bodies
    // became unreadable. Refuse before spending a key or an envelope; the
    // `content` field is empty and callers must check `shouldReject` first.
    if (filter.shouldReject) {
      return SendPreparation(
        e2e: recipient.e2e,
        content: '',
        preview: preview,
        filterMatched: true,
        shouldReject: true,
        username: username,
      );
    }

    if (!recipient.e2e || recipient.keys.isEmpty) {
      // Legacy lane: the server will still run its own hidden-word check, so
      // the local decision is only used to short-circuit strict hits early.
      return SendPreparation(
        e2e: false,
        content: plaintext,
        preview: preview,
        filterMatched: filter.matched,
        shouldReject: filter.shouldReject,
        username: username,
      );
    }

    final contentKey = await MessageCrypto.generateContentKey();
    final envelope = await MessageCrypto.encryptBody(
      plaintext: plaintext,
      contentKey: contentKey,
      recipients: recipient.keys,
    );
    return SendPreparation(
      e2e: true,
      content: envelope,
      preview: preview,
      filterMatched: filter.shouldQuarantine,
      shouldReject: filter.shouldReject,
      username: username,
      contentKey: contentKey,
    );
  }

  /// Decrypts one stored body for display.
  ///
  /// Never throws: an unreadable message is a first-class state the UI must
  /// render, not an error that turns the inbox into a crash.
  Future<DecryptedMessage> decryptStoredBody(String stored) async {
    if (!MessageCrypto.isEncrypted(stored)) {
      return DecryptedMessage(
        readability: HistoryReadability.legacyPlaintext,
        text: stored,
      );
    }
    final key = await keyStore.load();
    if (key == null) {
      return const DecryptedMessage(
        readability: HistoryReadability.unreadableAfterReinstallKeyLoss,
      );
    }
    try {
      final text = await MessageCrypto.decryptBody(
        envelope: stored,
        privateKey: key.privateKeyBytes,
        publicKey: key.publicKeyBytes,
      );
      return DecryptedMessage(
        readability: HistoryReadability.readable,
        text: text,
      );
    } catch (_) {
      // Two causes share this branch on purpose: this device's key is not in
      // the wraps, or authentication failed. Distinguishing them would help
      // an attacker map which devices a message was wrapped to.
      return const DecryptedMessage(
        readability: HistoryReadability.unreadableAfterReinstallKeyLoss,
      );
    }
  }

  /// Decrypts a claim-link reply thread. [claimUrl] carries the key fragment.
  Future<DecryptedMessage> decryptThread({
    required String storedContent,
    required String? storedReply,
    required String claimUrl,
  }) async {
    final key = ClaimLink.extractKey(claimUrl);
    if (key == null) {
      return const DecryptedMessage(
        readability: HistoryReadability.unreadableAfterReinstallKeyLoss,
      );
    }
    try {
      final content = await MessageCrypto.decryptWithContentKey(
        envelope: storedContent,
        contentKey: key,
      );
      String? reply;
      if (storedReply != null && storedReply.isNotEmpty) {
        reply = await MessageCrypto.decryptWithContentKey(
          envelope: storedReply,
          contentKey: key,
        );
      }
      return DecryptedMessage(
        readability: HistoryReadability.readable,
        text: reply == null ? content : '$content\n---\n$reply',
      );
    } catch (_) {
      return const DecryptedMessage(
        readability: HistoryReadability.decryptionFailed,
      );
    }
  }

  /// Persists the content key for a sent message so the claim link can be
  /// rebuilt after the success screen is gone. Keyed by reply token.
  Future<void> rememberClaimKey(String replyToken, List<int> contentKey) async {
    if (replyToken.isEmpty || contentKey.length != 32) return;
    await claimKeyStore.write(
      'secretmsg_e2e_claim_$replyToken',
      CryptoEncoding.b64url(contentKey),
    );
  }

  /// Rebuilds the claim link for [replyToken], or null when this install has
  /// no stored key (different install, or a legacy plaintext send).
  Future<String?> claimLinkFor({
    required String baseUrl,
    required String replyToken,
  }) async {
    final stored = await claimKeyStore.read('secretmsg_e2e_claim_$replyToken');
    if (stored == null || stored.isEmpty) return null;
    try {
      final key = CryptoEncoding.b64urlDecode(stored);
      if (key.length != 32) return null;
      return ClaimLink.build(
        baseUrl: baseUrl,
        replyToken: replyToken,
        contentKey: key,
      );
    } catch (_) {
      return null;
    }
  }

  /// Wipes this device's key and all stored claim keys (account wipe/logout
  /// with data deletion). Old envelopes become unreadable, as documented.
  Future<void> wipeKeys(Iterable<String> claimTokens) async {
    await keyStore.clear();
    for (final token in claimTokens) {
      await claimKeyStore.delete('secretmsg_e2e_claim_$token');
    }
  }

  /// The user-facing explanation for a message's readability state.
  static String explain(HistoryReadability state) =>
      ReinstallPolicy.explanation(state);
}
