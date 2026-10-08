import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/moderation/crypto/p256_ecdsa.dart';
import 'package:secretmsg_mobile/moderation/crypto/sha256.dart';

import 'fixtures.dart';

void main() {
  group('Sha256 (FIPS 180-4)', () {
    test('empty string', () {
      expect(
        Sha256.hex(const <int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('abc', () {
      expect(
        Sha256.hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('448-bit two-block message', () {
      expect(
        Sha256.hex(
          utf8.encode(
            'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
          ),
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('one million a characters', () {
      expect(
        Sha256.hex(List<int>.filled(1000000, 0x61)),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
      );
    });

    test('streaming update matches one-shot across chunk boundaries', () {
      final data = utf8.encode(
        'The quick brown fox jumps over the lazy dog, repeatedly and in chunks.',
      );
      final expected = Sha256.hex(data);
      for (final chunkSize in <int>[1, 2, 3, 7, 31, 63, 64, 65, 200]) {
        final sha = Sha256();
        for (var i = 0; i < data.length; i += chunkSize) {
          sha.update(data.sublist(i, min(i + chunkSize, data.length)));
        }
        expect(Sha256.toHex(sha.digest()), expected,
            reason: 'chunk size $chunkSize');
      }
    });

    test('digest is one-shot and update after digest throws', () {
      final sha = Sha256()..update(utf8.encode('abc'));
      sha.digest();
      expect(sha.digest, throwsStateError);
      expect(() => sha.update(const <int>[1]), throwsStateError);
    });
  });

  group('P256Ecdsa', () {
    test('verifies the OpenSSL ES256 signature', () {
      final signature = P256Ecdsa.parseSignature(kFixtureSigV120);
      expect(signature.length, 64);
      expect(
        P256Ecdsa.verify(
          publicKey: fixtureKey(),
          digest: Sha256.hash(utf8.encode(kFixtureManifestV120)),
          signature: signature,
        ),
        isTrue,
      );
    });

    test('rejects a tampered message', () {
      final tampered = utf8.encode('$kFixtureManifestV120 ');
      expect(
        P256Ecdsa.verify(
          publicKey: fixtureKey(),
          digest: Sha256.hash(tampered),
          signature: P256Ecdsa.parseSignature(kFixtureSigV120),
        ),
        isFalse,
      );
    });

    test('rejects a flipped signature bit', () {
      final signature =
          Uint8List.fromList(P256Ecdsa.parseSignature(kFixtureSigV120));
      signature[10] ^= 0x01;
      expect(
        P256Ecdsa.verify(
          publicKey: fixtureKey(),
          digest: Sha256.hash(utf8.encode(kFixtureManifestV120)),
          signature: signature,
        ),
        isFalse,
      );
    });

    test('rejects a key that is not on the curve', () {
      final key = fixtureKey();
      final offCurve = P256PublicKey(key.x + BigInt.one, key.y);
      expect(P256Ecdsa.isOnCurve(offCurve), isFalse);
      expect(
        P256Ecdsa.verify(
          publicKey: offCurve,
          digest: Sha256.hash(utf8.encode(kFixtureManifestV120)),
          signature: P256Ecdsa.parseSignature(kFixtureSigV120),
        ),
        isFalse,
      );
    });

    test('rejects malformed signatures and digests, fail closed', () {
      expect(
        () => P256Ecdsa.parseSignature('AAAA'),
        throwsFormatException,
      );
      expect(
        P256Ecdsa.verify(
          publicKey: fixtureKey(),
          digest: const <int>[1, 2, 3],
          signature: P256Ecdsa.parseSignature(kFixtureSigV120),
        ),
        isFalse,
      );
      expect(
        P256Ecdsa.verify(
          publicKey: fixtureKey(),
          digest: Sha256.hash(utf8.encode(kFixtureManifestV120)),
          signature: Uint8List(64),
        ),
        isFalse,
      );
    });

    test('parses 128-char and SEC1 hex forms identically', () {
      final raw = P256PublicKey.fromHex('$kFixtureKeyX$kFixtureKeyY');
      final sec1 = P256PublicKey.fromHex('04$kFixtureKeyX$kFixtureKeyY');
      expect(raw.x, sec1.x);
      expect(raw.y, sec1.y);
      expect(raw.isOnCurve, isTrue);
    });

    test('rejects malformed public key hex', () {
      expect(() => P256PublicKey.fromHex('abcd'), throwsFormatException);
      expect(() => P256PublicKey.fromHex('zz'), throwsFormatException);
    });
  });
}
