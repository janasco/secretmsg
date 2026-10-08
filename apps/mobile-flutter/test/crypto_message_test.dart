// NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
// protocol; passing these tests does not make it secure. Crypto bugs fail
// silently, and a passing suite is not a substitute for review.
//
// Tests for the message envelope primitives. These run without a device and
// without the network. The cross-language vector is also decrypted by the API
// test suite (secretmsg-private/api/test/crypto.test.mjs) with WebCrypto, so a
// format drift between Dart and the Worker fails in two places.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/crypto/crypto_constants.dart';
import 'package:secretmsg_mobile/crypto/message_crypto.dart';

List<int> bytes(int start, int length) =>
    List<int>.generate(length, (i) => start + i);

void main() {
  group('body round trip', () {
    test('encrypts and decrypts for a single device', () async {
      final x = X25519();
      final device = await x.newKeyPair();
      final devicePub = await device.extractPublicKey();
      final devicePriv = await device.extractPrivateKeyBytes();

      final key = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptBody(
        plaintext: 'hello from a device-free test',
        contentKey: key,
        recipients: [
          RecipientDeviceKey(kid: 'dev-1', publicKey: devicePub.bytes),
        ],
      );

      expect(MessageCrypto.isEncrypted(envelope), isTrue);
      final clear = await MessageCrypto.decryptBody(
        envelope: envelope,
        privateKey: devicePriv,
        publicKey: devicePub.bytes,
      );
      expect(clear, 'hello from a device-free test');
    });

    test('wraps to every listed device and only those devices', () async {
      final x = X25519();
      final alice = await x.newKeyPair();
      final bob = await x.newKeyPair();
      final mallory = await x.newKeyPair();
      final alicePub = await alice.extractPublicKey();
      final bobPub = await bob.extractPublicKey();
      final malloryPub = await mallory.extractPublicKey();
      final alicePriv = await alice.extractPrivateKeyBytes();
      final bobPriv = await bob.extractPrivateKeyBytes();
      final malloryPriv = await mallory.extractPrivateKeyBytes();

      final key = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptBody(
        plaintext: 'two recipients',
        contentKey: key,
        recipients: [
          RecipientDeviceKey(kid: 'alice', publicKey: alicePub.bytes),
          RecipientDeviceKey(kid: 'bob', publicKey: bobPub.bytes),
        ],
      );

      expect(
        await MessageCrypto.decryptBody(
            envelope: envelope, privateKey: alicePriv, publicKey: alicePub.bytes),
        'two recipients',
      );
      expect(
        await MessageCrypto.decryptBody(
            envelope: envelope, privateKey: bobPriv, publicKey: bobPub.bytes),
        'two recipients',
      );
      await expectLater(
        MessageCrypto.decryptBody(
            envelope: envelope,
            privateKey: malloryPriv,
            publicKey: malloryPub.bytes),
        throwsA(isA<EnvelopeDecryptionException>()),
      );
    });

    test('refuses to encrypt when nobody can receive the key', () async {
      final key = await MessageCrypto.generateContentKey();
      await expectLater(
        MessageCrypto.encryptBody(
          plaintext: 'message to nobody',
          contentKey: key,
          recipients: const [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('authentication failures are hard failures', () {
    test('a flipped body byte is rejected, not decoded', () async {
      final x = X25519();
      final device = await x.newKeyPair();
      final pub = await device.extractPublicKey();
      final priv = await device.extractPrivateKeyBytes();

      final key = List<int>.filled(32, 7);
      final envelope = await MessageCrypto.encryptBody(
        plaintext: 'do not tamper',
        contentKey: key,
        recipients: [RecipientDeviceKey(kid: 'd', publicKey: pub.bytes)],
      );

      // Flip one bit of the body ciphertext inside the JSON.
      final parsed = MessageCrypto.decodeEnvelope(envelope);
      final tamperedCt = Uint8List.fromList(parsed.cipherText);
      tamperedCt[0] ^= 0x01;
      final tampered = MessageCrypto.encodeEnvelope(EncryptedEnvelope(
        version: parsed.version,
        alg: parsed.alg,
        iv: parsed.iv,
        cipherText: tamperedCt,
        wraps: parsed.wraps,
      ));

      await expectLater(
        MessageCrypto.decryptBody(
            envelope: tampered, privateKey: priv, publicKey: pub.bytes),
        throwsA(isA<EnvelopeDecryptionException>()),
      );
    });

    test('a reply encrypted under another key is rejected', () async {
      final key = await MessageCrypto.generateContentKey();
      final other = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptReply(
        plaintext: 'reply text',
        contentKey: key,
      );
      expect(
        await MessageCrypto.decryptReply(envelope: envelope, contentKey: key),
        'reply text',
      );
      await expectLater(
        MessageCrypto.decryptReply(envelope: envelope, contentKey: other),
        throwsA(isA<EnvelopeDecryptionException>()),
      );
    });
  });

  group('envelope parsing is strict', () {
    test('plaintext is not mistaken for an envelope', () {
      expect(MessageCrypto.isEncrypted('just a normal message'), isFalse);
      expect(
        () => MessageCrypto.decodeEnvelope('just a normal message'),
        throwsA(isA<EnvelopeFormatException>()),
      );
    });

    test('rejects bad prefixes, versions, and field sizes', () async {
      final x = X25519();
      final device = await x.newKeyPair();
      final pub = await device.extractPublicKey();
      final key = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptBody(
        plaintext: 'shape check',
        contentKey: key,
        recipients: [RecipientDeviceKey(kid: 'd', publicKey: pub.bytes)],
      );

      final body = jsonDecode(
        utf8.decode(CryptoEncodingShim.b64urlDecode(
            envelope.substring(kEnvelopePrefix.length))),
      ) as Map<String, dynamic>;
      String encodeWith(Map<String, dynamic> mutated) =>
          '$kEnvelopePrefix${CryptoEncodingShim.b64url(utf8.encode(jsonEncode(mutated)))}';

      expect(
        () => MessageCrypto.decodeEnvelope(
            encodeWith({...body, 'v': 2})),
        throwsA(isA<EnvelopeFormatException>()),
      );
      expect(
        () => MessageCrypto.decodeEnvelope(
            encodeWith({...body, 'alg': 'A128GCM'})),
        throwsA(isA<EnvelopeFormatException>()),
      );
      expect(
        () => MessageCrypto.decodeEnvelope(encodeWith({...body, 'iv': 'AA'})),
        throwsA(isA<EnvelopeFormatException>()),
      );
      expect(
        () => MessageCrypto.decodeEnvelope(
            encodeWith({...body, 'ct': 'AAAA'})),
        throwsA(isA<EnvelopeFormatException>()),
      );
      expect(
        () => MessageCrypto.decodeEnvelope(
            '$kEnvelopePrefix!!!not-base64!!!'),
        throwsA(isA<EnvelopeFormatException>()),
      );
      // requireWraps is enforced when a send path demands a recipient wrap.
      expect(
        () => MessageCrypto.decodeEnvelope(
            MessageCrypto.encodeEnvelope(EncryptedEnvelope(
              version: kEnvelopeVersion,
              alg: kEnvelopeAlg,
              iv: List<int>.filled(12, 1),
              cipherText: List<int>.filled(32, 2),
            )),
            requireWraps: true),
        throwsA(isA<EnvelopeFormatException>()),
      );
    });
  });

  group('format', () {
    test('replies carry no wraps and bodies carry at least one', () async {
      final key = await MessageCrypto.generateContentKey();
      final reply = await MessageCrypto.encryptReply(
        plaintext: 'r',
        contentKey: key,
        nonce: bytes(0, 12),
      );
      expect(MessageCrypto.decodeEnvelope(reply).wraps, isEmpty);

      final x = X25519();
      final device = await x.newKeyPair();
      final pub = await device.extractPublicKey();
      final body = await MessageCrypto.encryptBody(
        plaintext: 'b',
        contentKey: key,
        recipients: [RecipientDeviceKey(kid: 'd', publicKey: pub.bytes)],
        nonce: bytes(0, 12),
      );
      expect(MessageCrypto.decodeEnvelope(body).wraps.length, 1);
    });
  });

  group('cross-language vector', () {
    test('fixed inputs produce the published envelope and round-trip', () async {
      final x = X25519();
      final recipient = await x.newKeyPairFromSeed(List<int>.filled(32, 0x11));
      final pub = await recipient.extractPublicKey();

      final envelope = await MessageCrypto.encryptBody(
        plaintext: 'vector-check: hello SecretMsg',
        contentKey: bytes(0, 32),
        recipients: [RecipientDeviceKey(kid: 'vec-1', publicKey: pub.bytes)],
        nonce: bytes(0xA0, 12),
        ephemeralSeeds: [List<int>.filled(32, 0x22)],
        wrapNonces: [bytes(0xB0, 12)],
      );

      // If this changes, the Worker's WebCrypto decrypt (api/test/crypto.test.mjs)
      // must change in the same commit.
      expect(
        envelope,
        'enc:v1:eyJ2IjoxLCJhbGciOiJBMjU2R0NNIiwiaXYiOiJvS0dpbzZTbHBxZW9xYXFyIiwiY3QiOiJrSDBmV1NxNUw5d0tBT1M0UFZxb3V4ekFOakRCMGlFZS1YcHI5UmpoVm8xM1cyV1ZhUnZXejI2MHRvZlQiLCJ3cmFwcyI6W3sia2lkIjoidmVjLTEiLCJlcGsiOiJENnBvVHRLSVo3bF9TbW90N2wzNHpwZE9kcmNCamo4aW9jVFBKbmhYRHlBIiwiaXYiOiJzTEd5czdTMXRyZTR1YnE3IiwiY3QiOiJibW9OQ0taZktweXpkWlFlMGRGejFoUlBWb0ZXTXJUWDVwbjVUMTFSdzNmWVR0LVgwd05QWkptd1Y3TjdTbmloIn1dfQ',
      );
      expect(
        CryptoEncodingShim.b64url(pub.bytes),
        'e06Qm75__kTEZaIgA31gjuNYl9Me-XLwf3SJLLD3PxM',
      );

      expect(
        await MessageCrypto.decryptBody(
          envelope: envelope,
          privateKey: List<int>.filled(32, 0x11),
          publicKey: pub.bytes,
        ),
        'vector-check: hello SecretMsg',
      );
    });
  });
}

/// Local shim so the test does not depend on the library's own helper.
class CryptoEncodingShim {
  static String b64url(List<int> data) =>
      base64UrlEncode(data).replaceAll('=', '');

  static Uint8List b64urlDecode(String input) {
    final normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final pad = (4 - normalized.length % 4) % 4;
    return base64Url.decode(normalized + ('=' * pad));
  }
}
