// NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
// protocol; passing these tests does not make it secure.
//
// Tests for claim-link key transport. Verifies that the key lives only in the
// fragment, that parsing is strict, and that redaction never leaks it.

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/crypto/claim_link.dart';
import 'package:secretmsg_mobile/crypto/crypto_encoding.dart';

void main() {
  final key = List<int>.generate(32, (i) => i);

  group('building', () {
    test('places the key in the fragment and nowhere else', () {
      final link = ClaimLink.build(
        baseUrl: 'https://secretmsg.net',
        replyToken: 'rep_abc123',
        contentKey: key,
      );
      final uri = Uri.parse(link);
      expect(uri.path, '/reply/rep_abc123');
      expect(uri.query, isEmpty);
      expect(uri.fragment, 'k=${CryptoEncoding.b64url(key)}');
    });

    test('strips trailing slashes and percent-encodes the token', () {
      final link = ClaimLink.build(
        baseUrl: 'https://secretmsg.net/',
        replyToken: 'rep_a/b',
        contentKey: key,
      );
      expect(link, startsWith('https://secretmsg.net/reply/rep_a%2Fb#k='));
    });

    test('rejects the wrong key size', () {
      expect(
        () => ClaimLink.build(
          baseUrl: 'https://secretmsg.net',
          replyToken: 't',
          contentKey: List<int>.filled(16, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('parsing', () {
    test('round-trips a full link', () {
      final link = ClaimLink.build(
        baseUrl: 'https://secretmsg.net',
        replyToken: 'rep_abc123',
        contentKey: key,
      );
      expect(ClaimLink.extractKey(link), key);
      expect(ClaimLink.hasKey(link), isTrue);
    });

    test('accepts a bare fragment', () {
      final fragment = '#k=${CryptoEncoding.b64url(key)}';
      expect(ClaimLink.extractKey(fragment), key);
    });

    test('a key in the query or path is not honoured', () {
      final b64 = CryptoEncoding.b64url(key);
      expect(
        ClaimLink.extractKey('https://secretmsg.net/reply/t?k=$b64'),
        isNull,
      );
      expect(
        ClaimLink.extractKey('https://secretmsg.net/reply/t/$b64'),
        isNull,
      );
    });

    test('rejects malformed, short, and wrong-size keys', () {
      expect(ClaimLink.extractKey('https://secretmsg.net/reply/t'), isNull);
      expect(ClaimLink.extractKey('https://secretmsg.net/reply/t#'), isNull);
      expect(ClaimLink.extractKey('https://secretmsg.net/reply/t#k='), isNull);
      expect(
        ClaimLink.extractKey('https://secretmsg.net/reply/t#k=AAAA'),
        isNull,
      );
      expect(
        ClaimLink.extractKey(
            'https://secretmsg.net/reply/t#k=${CryptoEncoding.b64url(List<int>.filled(16, 3))}'),
        isNull,
      );
    });

    test('ignores sibling fragment parameters', () {
      final link = 'https://secretmsg.net/reply/t#x=1&k=${CryptoEncoding.b64url(key)}&y=2';
      expect(ClaimLink.extractKey(link), key);
    });
  });

  group('redaction', () {
    test('strips the fragment but keeps the path', () {
      final link = ClaimLink.build(
        baseUrl: 'https://secretmsg.net',
        replyToken: 'rep_abc123',
        contentKey: key,
      );
      final redacted = ClaimLink.redact(link);
      expect(redacted, 'https://secretmsg.net/reply/rep_abc123');
      expect(redacted, isNot(contains(CryptoEncoding.b64url(key))));
    });

    test('withoutKey keeps other fragments if a caller adds them', () {
      final uri = Uri.parse('https://secretmsg.net/reply/t#k=secret');
      expect(ClaimLink.withoutKey(uri).fragment, isEmpty);
    });
  });
}
