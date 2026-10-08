// NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
// protocol; passing these tests does not make it secure.
//
// Tests for client-side Filtered Words. The normalization cases mirror
// api/src/index.ts:341-346, so a drift between client and (legacy) server
// checking is caught here.

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/crypto/filtered_words.dart';

void main() {
  const words = ['forbidden', 'bad word'];

  group('mode off', () {
    test('never matches', () {
      final d = FilteredWords.evaluate(
          content: 'forbidden things', mode: 'off', words: words);
      expect(d.matched, isFalse);
      expect(d.shouldReject, isFalse);
      expect(d.shouldQuarantine, isFalse);
      expect(d.shouldSend, isTrue);
    });
  });

  group('standard mode', () {
    test('matches case-insensitively and quarantines', () {
      final d = FilteredWords.evaluate(
          content: 'You are FORBIDDEN from this', mode: 'standard', words: words);
      expect(d.matched, isTrue);
      expect(d.shouldQuarantine, isTrue);
      expect(d.shouldReject, isFalse);
      expect(d.shouldSend, isTrue);
    });

    test('keeps punctuation in the haystack, like the server', () {
      // 'bad word' with punctuation between does not match in standard mode.
      final d = FilteredWords.evaluate(
          content: 'bad, word', mode: 'standard', words: words);
      expect(d.matched, isFalse);
    });

    test('empty words never match', () {
      final d = FilteredWords.evaluate(
          content: 'anything', mode: 'standard', words: ['']);
      expect(d.matched, isFalse);
    });
  });

  group('strict mode', () {
    test('strips non-alphanumerics, then matches and rejects', () {
      final d = FilteredWords.evaluate(
          content: 'B@A#D W\$O%R^D!', mode: 'strict', words: words);
      expect(d.matched, isTrue);
      expect(d.shouldReject, isTrue);
      expect(d.shouldQuarantine, isTrue);
      expect(d.shouldSend, isFalse);
    });

    test('digits survive; symbols do not join words', () {
      final d = FilteredWords.evaluate(
          content: 'forbidden!', mode: 'strict', words: ['forbidden']);
      expect(d.matched, isTrue);
    });

    test('a clean message passes', () {
      final d = FilteredWords.evaluate(
          content: 'have a lovely day', mode: 'strict', words: words);
      expect(d.matched, isFalse);
      expect(d.shouldSend, isTrue);
    });
  });

  group('normalize parity', () {
    test('standard is lowercasing only', () {
      expect(
        FilteredWords.normalize('Bad, Word! À', mode: 'standard'),
        'bad, word! à',
      );
    });

    test('strict keeps ascii alphanumerics and spaces only', () {
      expect(
        FilteredWords.normalize('B@A#D w0rd! À', mode: 'strict'),
        'bad w0rd ',
      );
    });
  });

  group('unknown mode', () {
    test('falls back to standard, never to off', () {
      final d = FilteredWords.evaluate(
          content: 'forbidden', mode: 'wat', words: words);
      expect(d.mode, 'standard');
      expect(d.matched, isTrue);
    });
  });
}
