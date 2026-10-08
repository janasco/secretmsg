// NOT CRYPTOGRAPHICALLY REVIEWED. This code has not been reviewed by any
// cryptographer and no third party has audited the protocol it implements.
// Crypto bugs fail silently. See lib/crypto/README.md for the full list of
// unverified properties: protocol design, key-exchange authenticity, forward
// secrecy, and replay resistance. Do not claim more than that file claims.
//
// Message body encryption.
//
// Primitives come from package:cryptography (pure Dart, no native plugin and
// no Google Play Services dependency — the sideload track is de-Googled).
// Nothing in this file implements a cipher, curve, or KDF by hand.
//
// What this DOES provide: an anonymous sender can encrypt a body so that only
// a holder of the recipient device's X25519 private key can read it, and the
// server stores only ciphertext plus an ephemeral public key.
//
// What this DOES NOT provide:
//   * sender authentication — anyone who fetches the recipient's public key
//     can produce a valid envelope; the recipient cannot tell who sent it;
//   * forward secrecy — a later compromise of the device private key plus a
//     stored envelope yields the content key (no per-message ratchet);
//   * deniability beyond what the anonymous transport already gives;
//   * replay resistance — envelopes can be replayed by a malicious server;
//     dedup is only the existing client_msg_id window;
//   * protection against a malicious server that also serves the client
//     JavaScript/Dart code.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'crypto_constants.dart';
import 'crypto_encoding.dart';

/// One recipient device the content key is wrapped to.
class RecipientDeviceKey {
  /// Opaque server-side id for the device key row. Bound into the wrap AAD.
  final String kid;

  /// Raw 32-byte X25519 public key.
  final Uint8List publicKey;

  RecipientDeviceKey({required this.kid, required List<int> publicKey})
      : publicKey = Uint8List.fromList(publicKey) {
    if (publicKey.length != kX25519KeyLength) {
      throw ArgumentError.value(
        publicKey.length,
        'publicKey',
        'X25519 public key must be $kX25519KeyLength bytes',
      );
    }
  }
}

/// One wrapped copy of the content key inside an envelope.
class EnvelopeWrap {
  final String kid;
  final Uint8List ephemeralPublicKey;
  final Uint8List iv;
  final Uint8List cipherText; // wrapped key || 16-byte tag

  EnvelopeWrap({
    required this.kid,
    required List<int> ephemeralPublicKey,
    required List<int> iv,
    required List<int> cipherText,
  })  : ephemeralPublicKey = Uint8List.fromList(ephemeralPublicKey),
        iv = Uint8List.fromList(iv),
        cipherText = Uint8List.fromList(cipherText);
}

/// A parsed `enc:v1:` envelope.
class EncryptedEnvelope {
  final int version;
  final String alg;
  final Uint8List iv;
  final Uint8List cipherText; // ciphertext || 16-byte tag
  final List<EnvelopeWrap> wraps;

  EncryptedEnvelope({
    required this.version,
    required this.alg,
    required List<int> iv,
    required List<int> cipherText,
    this.wraps = const [],
  })  : iv = Uint8List.fromList(iv),
        cipherText = Uint8List.fromList(cipherText);
}

/// Thrown when a stored body claims to be encrypted but is malformed.
class EnvelopeFormatException implements Exception {
  final String message;
  EnvelopeFormatException([this.message = 'Malformed encrypted envelope']);
  @override
  String toString() => message;
}

/// Thrown when an envelope cannot be decrypted with the available keys.
/// Deliberately generic: callers must not surface which step failed.
class EnvelopeDecryptionException implements Exception {
  final String message;
  EnvelopeDecryptionException(
      [this.message = 'This message cannot be decrypted on this device']);
  @override
  String toString() => message;
}

class MessageCrypto {
  MessageCrypto._();

  static final X25519 _x25519 = X25519();
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: kContentKeyLength);

  /// Fresh 32-byte per-message content key.
  static Future<Uint8List> generateContentKey() async {
    final key = await _aesGcm.newSecretKey();
    return Uint8List.fromList(await key.extractBytes());
  }

  /// Fresh 12-byte AES-GCM nonce.
  static Uint8List generateNonce() => Uint8List.fromList(_aesGcm.newNonce());

  /// True when a stored body is an end-to-end encrypted envelope. Legacy
  /// plaintext (pre-1.8 rows) does not match, which is what keeps old messages
  /// readable during the migration.
  static bool isEncrypted(String stored) => stored.startsWith(kEnvelopePrefix);

  /// Encrypts [plaintext] under [contentKey] and wraps that key to every
  /// recipient device in [recipients].
  ///
  /// [nonce], [wrapNonces], and [ephemeralSeeds] are test-only injection
  /// points; production callers must leave them null so nonces and ephemeral
  /// keys come from the platform CSPRNG. [ephemeralSeeds] must have one
  /// 32-byte seed per recipient when provided; [wrapNonces] must match too.
  ///
  /// Throws [ArgumentError] when [recipients] is empty: a body whose key is
  /// wrapped to nobody would be permanently unreadable, and silently storing
  /// one is worse than failing the send.
  static Future<String> encryptBody({
    required String plaintext,
    required List<int> contentKey,
    required List<RecipientDeviceKey> recipients,
    List<int>? nonce,
    List<List<int>>? ephemeralSeeds,
    List<List<int>>? wrapNonces,
  }) async {
    if (contentKey.length != kContentKeyLength) {
      throw ArgumentError.value(
          contentKey.length, 'contentKey', 'Content key must be 32 bytes');
    }
    if (recipients.isEmpty) {
      throw ArgumentError('Refusing to encrypt a body with no recipient keys');
    }
    if (recipients.length > kMaxWraps) {
      throw ArgumentError('Too many recipient keys (max $kMaxWraps)');
    }
    if (ephemeralSeeds != null && ephemeralSeeds.length != recipients.length) {
      throw ArgumentError('ephemeralSeeds must match recipients one-for-one');
    }
    if (wrapNonces != null && wrapNonces.length != recipients.length) {
      throw ArgumentError('wrapNonces must match recipients one-for-one');
    }

    final bodyIv = nonce ?? generateNonce();
    final body = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(contentKey),
      nonce: bodyIv,
      aad: utf8.encode(kBodyAad),
    );

    final wraps = <EnvelopeWrap>[];
    for (var i = 0; i < recipients.length; i++) {
      final recipient = recipients[i];
      final seed = ephemeralSeeds?[i];
      final ephemeral = seed == null
          ? await _x25519.newKeyPair()
          : await _x25519.newKeyPairFromSeed(seed);
      wraps.add(await _wrapKey(
        contentKey: contentKey,
        recipient: recipient,
        ephemeralKeyPair: ephemeral,
        nonce: wrapNonces?[i],
      ));
    }

    return encodeEnvelope(EncryptedEnvelope(
      version: kEnvelopeVersion,
      alg: kEnvelopeAlg,
      iv: bodyIv,
      cipherText: body.concatenation(nonce: false),
      wraps: wraps,
    ));
  }

  /// Encrypts a reply under the same content key the original message used.
  /// The sender of the original message holds that key via the claim-link
  /// fragment; no new key material is generated.
  static Future<String> encryptReply({
    required String plaintext,
    required List<int> contentKey,
    List<int>? nonce,
  }) async {
    if (contentKey.length != kContentKeyLength) {
      throw ArgumentError.value(
          contentKey.length, 'contentKey', 'Content key must be 32 bytes');
    }
    final iv = nonce ?? generateNonce();
    final box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(contentKey),
      nonce: iv,
      aad: utf8.encode(kBodyAad),
    );
    return encodeEnvelope(EncryptedEnvelope(
      version: kEnvelopeVersion,
      alg: kEnvelopeAlg,
      iv: iv,
      cipherText: box.concatenation(nonce: false),
    ));
  }

  /// Decrypts an envelope that has at least one wrap for this device.
  ///
  /// [privateKey] and [publicKey] are the raw 32-byte device keypair. Tries
  /// every wrap in order; the first one that authenticates wins. A failed
  /// attempt is not distinguished from a missing one on purpose.
  static Future<String> decryptBody({
    required String envelope,
    required List<int> privateKey,
    required List<int> publicKey,
  }) async {
    final parsed = decodeEnvelope(envelope, requireWraps: true);
    for (final wrap in parsed.wraps) {
      final key = await tryUnwrapContentKey(
        wrap: wrap,
        privateKey: privateKey,
        publicKey: publicKey,
      );
      if (key != null) {
        return _decryptWithContentKey(parsed, key);
      }
    }
    throw EnvelopeDecryptionException();
  }

  /// Decrypts a reply envelope with a content key obtained from a claim-link
  /// fragment or from unwrapping the original message.
  static Future<String> decryptReply({
    required String envelope,
    required List<int> contentKey,
  }) {
    return decryptWithContentKey(envelope: envelope, contentKey: contentKey);
  }

  /// Decrypts any envelope (body with wraps, or reply without) using an
  /// already-unwrapped content key. Used by the report-disclosure flow, where
  /// the reporter's device proves it can read the message before handing the
  /// key over.
  static Future<String> decryptWithContentKey({
    required String envelope,
    required List<int> contentKey,
  }) {
    return _decryptWithContentKey(
      decodeEnvelope(envelope, requireWraps: false),
      contentKey,
    );
  }

  /// Attempts to unwrap the content key from one wrap. Returns null on any
  /// authentication failure — a wrong device key must look exactly like a
  /// corrupted wrap.
  static Future<Uint8List?> tryUnwrapContentKey({
    required EnvelopeWrap wrap,
    required List<int> privateKey,
    required List<int> publicKey,
  }) async {
    try {
      final keyPair = SimpleKeyPairData(
        Uint8List.fromList(privateKey),
        publicKey: SimplePublicKey(
          Uint8List.fromList(publicKey),
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );
      final shared = await _x25519.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: SimplePublicKey(
          wrap.ephemeralPublicKey,
          type: KeyPairType.x25519,
        ),
      );
      final wrapKey = await _deriveWrapKey(shared, wrap.kid);
      final box = SecretBox(
        wrap.cipherText.sublist(0, wrap.cipherText.length - kTagLength),
        nonce: wrap.iv,
        mac: Mac(wrap.cipherText.sublist(wrap.cipherText.length - kTagLength)),
      );
      final clear = await _aesGcm.decrypt(
        box,
        secretKey: wrapKey,
        aad: utf8.encode('$kWrapInfoPrefix${wrap.kid}'),
      );
      return Uint8List.fromList(clear);
    } catch (_) {
      return null;
    }
  }

  /// Serializes an envelope into the `enc:v1:` storage string.
  static String encodeEnvelope(EncryptedEnvelope envelope) {
    final json = <String, dynamic>{
      'v': envelope.version,
      'alg': envelope.alg,
      'iv': CryptoEncoding.b64url(envelope.iv),
      'ct': CryptoEncoding.b64url(envelope.cipherText),
      if (envelope.wraps.isNotEmpty)
        'wraps': [
          for (final wrap in envelope.wraps)
            {
              'kid': wrap.kid,
              'epk': CryptoEncoding.b64url(wrap.ephemeralPublicKey),
              'iv': CryptoEncoding.b64url(wrap.iv),
              'ct': CryptoEncoding.b64url(wrap.cipherText),
            }
        ],
    };
    return '$kEnvelopePrefix${CryptoEncoding.b64url(utf8.encode(jsonEncode(json)))}';
  }

  /// Parses an `enc:v1:` storage string.
  ///
  /// Throws [EnvelopeFormatException] for anything malformed. This function
  /// is deliberately strict: a partially-understood envelope must never be
  /// treated as plaintext, because rendering ciphertext as if it were a
  /// message is a silent failure users cannot detect.
  static EncryptedEnvelope decodeEnvelope(
    String stored, {
    bool requireWraps = false,
  }) {
    if (stored.length > kMaxEnvelopeLength) {
      throw EnvelopeFormatException('Envelope too large');
    }
    if (!stored.startsWith(kEnvelopePrefix)) {
      throw EnvelopeFormatException('Not an encrypted envelope');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(
        utf8.decode(CryptoEncoding.b64urlDecode(
          stored.substring(kEnvelopePrefix.length),
        )),
      );
    } catch (_) {
      throw EnvelopeFormatException('Envelope is not valid base64url JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw EnvelopeFormatException('Envelope must be a JSON object');
    }
    if (decoded['v'] != kEnvelopeVersion || decoded['alg'] != kEnvelopeAlg) {
      throw EnvelopeFormatException('Unsupported envelope version or algorithm');
    }
    final iv = _decodeField(decoded['iv']);
    final ct = _decodeField(decoded['ct']);
    if (iv.length != kNonceLength) {
      throw EnvelopeFormatException('Bad nonce length');
    }
    if (ct.length < kTagLength) {
      throw EnvelopeFormatException('Ciphertext shorter than its tag');
    }

    final wraps = <EnvelopeWrap>[];
    final rawWraps = decoded['wraps'];
    if (rawWraps != null) {
      if (rawWraps is! List || rawWraps.length > kMaxWraps) {
        throw EnvelopeFormatException('Bad wraps');
      }
      for (final raw in rawWraps) {
        if (raw is! Map<String, dynamic>) {
          throw EnvelopeFormatException('Bad wrap entry');
        }
        final kid = raw['kid'];
        if (kid is! String || kid.isEmpty || kid.length > 64) {
          throw EnvelopeFormatException('Bad wrap key id');
        }
        final epk = _decodeField(raw['epk']);
        final wrapIv = _decodeField(raw['iv']);
        final wrapCt = _decodeField(raw['ct']);
        if (epk.length != kX25519KeyLength ||
            wrapIv.length != kNonceLength ||
            wrapCt.length != kContentKeyLength + kTagLength) {
          throw EnvelopeFormatException('Bad wrap material');
        }
        wraps.add(EnvelopeWrap(
          kid: kid,
          ephemeralPublicKey: epk,
          iv: wrapIv,
          cipherText: wrapCt,
        ));
      }
    }
    if (requireWraps && wraps.isEmpty) {
      throw EnvelopeFormatException('Envelope carries no key for any device');
    }
    return EncryptedEnvelope(
      version: kEnvelopeVersion,
      alg: kEnvelopeAlg,
      iv: iv,
      cipherText: ct,
      wraps: wraps,
    );
  }

  // ---- internals ----

  static Future<String> _decryptWithContentKey(
    EncryptedEnvelope envelope,
    List<int> contentKey,
  ) async {
    try {
      final clear = await _aesGcm.decrypt(
        SecretBox(
          envelope.cipherText.sublist(0, envelope.cipherText.length - kTagLength),
          nonce: envelope.iv,
          mac: Mac(
              envelope.cipherText.sublist(envelope.cipherText.length - kTagLength)),
        ),
        secretKey: SecretKey(contentKey),
        aad: utf8.encode(kBodyAad),
      );
      return utf8.decode(clear);
    } catch (_) {
      throw EnvelopeDecryptionException();
    }
  }

  static Future<EnvelopeWrap> _wrapKey({
    required List<int> contentKey,
    required RecipientDeviceKey recipient,
    required SimpleKeyPair ephemeralKeyPair,
    List<int>? nonce,
  }) async {
    final ephemeralPublic = await ephemeralKeyPair.extractPublicKey();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: SimplePublicKey(
        recipient.publicKey,
        type: KeyPairType.x25519,
      ),
    );
    final wrapKey = await _deriveWrapKey(shared, recipient.kid);
    final iv = nonce ?? generateNonce();
    final box = await _aesGcm.encrypt(
      contentKey,
      secretKey: wrapKey,
      nonce: iv,
      aad: utf8.encode('$kWrapInfoPrefix${recipient.kid}'),
    );
    return EnvelopeWrap(
      kid: recipient.kid,
      ephemeralPublicKey: ephemeralPublic.bytes,
      iv: iv,
      cipherText: box.concatenation(nonce: false),
    );
  }

  static Future<SecretKey> _deriveWrapKey(
    SecretKey shared,
    String kid,
  ) async {
    final derived = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(kWrapSalt),
      info: utf8.encode('$kWrapInfoPrefix$kid'),
    );
    return derived;
  }

  static Uint8List _decodeField(dynamic value) {
    if (value is! String || value.isEmpty) {
      throw EnvelopeFormatException('Missing envelope field');
    }
    try {
      return CryptoEncoding.b64urlDecode(value);
    } on FormatException {
      throw EnvelopeFormatException('Bad base64url in envelope');
    }
  }
}
