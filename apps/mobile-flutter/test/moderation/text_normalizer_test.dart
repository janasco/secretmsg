import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/moderation/text/confusables.dart';
import 'package:secretmsg_mobile/moderation/text/text_normalizer.dart';

void main() {
  const normalizer = TextNormalizer();

  String compact(String input) => normalizer.normalize(input).compact;
  String folded(String input) => normalizer.normalize(input).folded;
  String skeleton(String input) => normalizer.normalize(input).skeleton;

  group('case and compatibility folding', () {
    test('case folds', () {
      expect(compact('FUCK'), 'fuck');
      expect(compact('MiXeD CaSe'), 'mixedcase');
      expect(folded('İ'), 'i');
      expect(compact('ẞ'), 'ss');
    });

    test('fullwidth forms fold to ASCII', () {
      expect(compact('ｆｕｃｋ'), 'fuck');
    });

    test('mathematical alphanumerics fold to ASCII', () {
      expect(compact('𝐟𝐮𝐜𝐤'), 'fuck');
      expect(compact('𝟝𝟙'), '51');
    });

    test('precomposed Latin diacritics fold to their base letters', () {
      expect(compact('fück'), 'fuck');
      expect(compact('fôö'), 'foo');
      expect(foldCodePoint(0xC0), 'a');
      expect(foldCodePoint(0x41), isNull, reason: 'ASCII is unchanged');
    });

    test('non-decomposing lookalikes from UTS #39 fold', () {
      expect(compact('l\xF8ve'), 'love', reason: 'ø -> o');
      expect(compact('łove'), 'love', reason: 'ł -> l');
      expect(compact('ħello'), 'hello', reason: 'ħ -> h');
      expect(compact('ŋame'), 'name', reason: 'ŋ -> n');
      expect(compact('þorn'), 'porn', reason: 'þ -> p');
      // Documented false negative: UTS #39 maps ð to ∂ + overlay, and ∂ has
      // no ASCII skeleton, so this one is not folded. See the docs.
      expect(compact('ðog'), 'og');
    });
  });

  group('evasion resistance', () {
    test('zero-width and invisible characters are removed for matching', () {
      const input = 'f\u200Bu\u200Dc\uFEFFk';
      final result = normalizer.normalize(input);
      expect(result.compact, 'fuck');
      expect(result.flags.hasInvisibleCharacters, isTrue);
      expect(result.display, input,
          reason: 'display keeps joiners so emoji and CJK still render');
    });

    test('variation selectors are kept for display and dropped for matching',
        () {
      const input = 'f\uFE0Fu\uFE0Fck';
      final result = normalizer.normalize(input);
      expect(result.compact, 'fuck');
      expect(result.display, input);
      expect(result.flags.hasInvisibleCharacters, isTrue);
    });

    test('universal combining marks are stripped for matching', () {
      const input = 'f\u0301u\u0308ck';
      final result = normalizer.normalize(input);
      expect(result.compact, 'fuck');
      expect(result.display, input, reason: 'accents still render');
      expect(result.flags.hasStrippedCombiningMarks, isTrue);
    });

    test('script-specific vowel signs are preserved, not stripped', () {
      // Devanagari sign vowel aa is a letter, not an evasion: stripping it
      // would collide distinct Hindi words.
      const hindi = 'क\u093E\u0932\u093E';
      final result = normalizer.normalize(hindi);
      expect(result.folded, hindi);
      expect(result.flags.hasStrippedCombiningMarks, isFalse);
    });

    test('cross-script lookalikes fold', () {
      // Cyrillic small a / c / o / e / p / x and Greek upsilon-alpha.
      expect(compact('fu\u0441k'), 'fuck');
      expect(compact('l\u043Eve'), 'love');
      expect(compact('f\u03C5ck'), 'fuck');
      expect(compact('\u0430\u0435\u043E\u0440\u0445'), 'aeopx');
      final result = normalizer.normalize('sp\u0430m');
      expect(result.compact, 'spam');
      expect(result.flags.hasFoldedHomoglyphs, isTrue);
    });

    test('separators and symbol substitutions fold in the compact form', () {
      expect(compact('f.u.c.k'), 'fuck');
      expect(compact('f u c k'), 'fuck');
      expect(compact('a\$\$'), 'ass');
      expect(compact('b!tch'), 'bitch');
      expect(skeleton('f.u.c.k'), 'f u c k');
    });

    test('bidi controls are removed from the display form', () {
      const input = '\u202Ehello\u202C';
      final result = normalizer.normalize(input);
      expect(result.display, 'hello');
      expect(result.flags.hasBidiControls, isTrue);
    });

    test('Unicode whitespace collapses to single spaces', () {
      final result = normalizer.normalize('a\u00A0\u2003b');
      expect(result.skeleton, 'a b');
      expect(result.compact, 'ab');
      expect(result.display, 'a\u00A0\u2003b');
    });
  });

  group('non-Latin and emoji text', () {
    test('non-Latin scripts stay in the folded form for exact matching', () {
      expect(folded('Привет'), folded('привет'));
      expect(normalizer.normalize('Привет').compact,
          normalizer.normalize('привет').compact);
      expect(folded('日本語'), '日本語');
      expect(compact('日本語'), '');
    });

    test('emoji survive folding and skin tones are symbols in the skeleton',
        () {
      final result = normalizer.normalize('ok 👍🏽');
      expect(result.compact, 'ok');
      expect(result.folded, 'ok 👍🏽');
      expect(result.display, 'ok 👍🏽');
    });

    test('emoji ZWJ sequences keep their joiner on display only', () {
      const family = '👨\u200D👩\u200D👧';
      final result = normalizer.normalize(family);
      expect(result.display, family);
      expect(result.folded, isNot(contains('\u200D')));
      expect(result.flags.hasInvisibleCharacters, isTrue);
    });
  });

  group('character classes', () {
    test('ignored, bidi, mark and whitespace classification', () {
      expect(isIgnoredForMatching(0x200D), isTrue, reason: 'ZWJ');
      expect(isIgnoredForMatching(0xFE0F), isTrue, reason: 'VS16');
      expect(isBidiControl(0x202E), isTrue, reason: 'RLO');
      expect(isBidiControl(0x200B), isFalse, reason: 'ZWSP is not bidi');
      expect(isStrippableCombiningMark(0x0301), isTrue);
      expect(isStrippableCombiningMark(0x093E), isFalse,
          reason: 'Devanagari letter AA is kept');
      expect(isUnicodeWhitespace(0x00A0), isTrue);
      expect(isUnicodeWhitespace(0x41), isFalse);
    });

    test('flags report nothing for plain ASCII', () {
      final result = normalizer.normalize('hello world');
      expect(result.flags.hasAny, isFalse);
      expect(result.display, 'hello world');
      expect(result.compact, 'helloworld');
    });
  });
}
