import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/moderation/text/hidden_words.dart';
import 'package:secretmsg_mobile/moderation/text/text_normalizer.dart';

void main() {
  const normalizer = TextNormalizer();

  HiddenWordsFilter filter(List<String> words,
          [HiddenWordsMatchMode mode =
              HiddenWordsMatchMode.evasionResistant]) =>
      HiddenWordsFilter(words: words, normalizer: normalizer, mode: mode);

  HiddenWordsMatch? hit(List<String> words, String text,
          [HiddenWordsMatchMode mode =
              HiddenWordsMatchMode.evasionResistant]) =>
      filter(words, mode).firstMatch(normalizer.normalize(text));

  group('evasion-resistant matching', () {
    test('plain containment, case-insensitive', () {
      expect(hit(['spam'], 'this is SPAM')?.word, 'spam');
      expect(hit(['spam'], 'this is fine'), isNull);
    });

    test('zero-width insertion cannot split a word', () {
      expect(hit(['spam'], 's\u200Bp\u200Ba\u200Bm'), isNotNull);
      expect(hit(['spam'], 's\uFEFFp\u2060am'), isNotNull);
    });

    test('homoglyph scripts and diacritics cannot disguise a word', () {
      expect(hit(['spam'], 'sp\u0430m'), isNotNull, reason: 'Cyrillic a');
      expect(hit(['love'], 'l\u043Eve'), isNotNull, reason: 'Cyrillic o');
      expect(hit(['fuck'], 'f\u00FCck'), isNotNull, reason: 'precomposed ü');
      expect(hit(['fuck'], 'f\u03C5ck'), isNotNull, reason: 'Greek upsilon');
    });

    test('separator insertion cannot split a word', () {
      expect(hit(['spam'], 's.p.a.m'), isNotNull);
      expect(hit(['spam'], 's p a m'), isNotNull);
      expect(hit(['spam'], 's-p_a*m'), isNotNull);
    });

    test('repeated characters cannot evade', () {
      expect(hit(['spam'], 'spaaam'), isNotNull);
      final match = hit(['spam'], 'spaaam');
      expect(match?.repetitionTolerant, isTrue);
    });

    test('digit leet variants are expanded on the wordlist side', () {
      expect(hit(['spam'], '5pam'), isNotNull);
      expect(hit(['shit'], '5hit'), isNotNull);
      expect(hit(['love'], 'l0ve'), isNotNull);
      expect(hit(['test'], 't3st'), isNotNull);
      expect(hit(['bait'], 'b41t'), isNotNull);
      expect(hit(['ass'], 'a55'), isNotNull);
      // `u` has no digit substitute in the map; `f0ck` reads as `fock` and
      // does not match `fuck`. Exact list spelling still works.
      expect(hit(['fuck'], 'fuck'), isNotNull);
    });

    test('symbol substitutions fold in the message, not the list', () {
      expect(hit(['ass'], 'a\$\$'), isNotNull);
      expect(hit(['bitch'], 'b!tch'), isNotNull);
    });

    test('repetition tolerance does not make a shorter message match', () {
      expect(hit(['ass'], 'as'), isNull);
      expect(hit(['spam'], 'spa'), isNull);
    });

    test('documented false positive: substring inside a longer word', () {
      // Legacy server semantics were plain containment; this pipeline keeps
      // that so a sender cannot append a letter to evade. Reveal is one tap.
      expect(hit(['ass'], 'class'), isNotNull);
    });

    test('short entries match whole tokens only', () {
      expect(hit(['ok'], 'ok then'), isNotNull);
      expect(hit(['ok'], 'OK.'), isNotNull);
      expect(hit(['ok'], 'book'), isNull);
      expect(hit(['ok'], 'look at me'), isNull);
    });

    test('entries with no compact form match exactly after folding', () {
      expect(hit(['💀'], 'so ominous 💀'), isNotNull);
      expect(hit(['💀'], 'no skulls here'), isNull);
      expect(hit(['💀💀'], '💀💀💀'), isNotNull);
    });

    test('non-Latin words round-trip through the same folding', () {
      expect(hit(['привет'], 'привет'), isNotNull);
      expect(hit(['привет'], 'ПРИВЕТ'), isNotNull);
      expect(hit(['привет'], 'прив\u200Bет'), isNotNull);
      expect(hit(['日本語'], 'これは日本語です'), isNotNull);
    });

    test('word list is deduplicated and blanks are skipped', () {
      final compiled = filter(['spam', 'SPAM', ' spam ', '', '  ']);
      expect(compiled.words, ['spam']);
      expect(compiled.isEmpty, isFalse);
      expect(filter(['', '   ']).isEmpty, isTrue);
    });
  });

  group('plainSubstring parity mode', () {
    test('matches only lookalike-folded containment', () {
      expect(hit(['fuck'], 'FUCK', HiddenWordsMatchMode.plainSubstring),
          isNotNull);
      // Separation and repetition are what the evasion-resistant mode adds;
      // even parity mode folds case, lookalikes and zero-width characters.
      expect(hit(['fuck'], 'f.u.c.k', HiddenWordsMatchMode.plainSubstring),
          isNull);
      expect(hit(['fuck'], 'fuuuck', HiddenWordsMatchMode.plainSubstring),
          isNull);
      expect(hit(['fuck'], 'f\u200Buck', HiddenWordsMatchMode.plainSubstring),
          isNotNull);
    });
  });
}
