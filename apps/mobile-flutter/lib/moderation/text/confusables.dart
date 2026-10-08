/// Folding tables and character classes used by the deterministic matching
/// skeleton.
///
/// Two authoritative tables are combined, in this precedence order:
///
/// 1. [kConfusablesTable] — non-ASCII lookalikes derived from Unicode UTS #39
///    `confusables.txt` (Cyrillic/Greek/Armenian/... letters that render like
///    Latin ones). ASCII sources are deliberately excluded: the UTS #39 data
///    also encodes leet substitutions (`1 -> l`, `0 -> O`) and
///    identifier-specific folds (`m -> rn`) that would mangle ordinary text.
///    Substitution attacks are handled by bounded wordlist variant expansion
///    in `hidden_words.dart` instead.
/// 2. [kUnicodeFoldTable] — NFKD compatibility folding + case folding +
///    combining-mark stripping for every non-ASCII code point that reduces to
///    ASCII (fullwidth forms, math alphanumerics, circled/superscript forms,
///    Latin diacritics and ligatures).
///
/// Known false negatives are documented in `docs/on-device-moderation.md`:
/// letters whose visual match is ambiguous (Cyrillic `и`, `к`, `т`; Greek
/// `κ`, `τ`) are not in UTS #39's ASCII skeleton and are therefore not
/// folded. They remain caught only if the recipient writes the lookalike
/// spelling in their list.
library;

import 'confusables_table.g.dart';
import 'unicode_fold_table.g.dart';

/// Returns the skeleton expansion for [codePoint], or null when the code point
/// is unchanged by folding.
String? foldCodePoint(int codePoint) {
  final confusable = kConfusablesTable[codePoint];
  if (confusable != null) return confusable;
  return kUnicodeFoldTable[codePoint];
}

/// True for characters that must be dropped before matching: zero-width and
/// invisible format characters, variation selectors and tag characters. These
/// are the classic "separate the letters of a bad word" evasion.
///
/// Variation selectors and emoji joiners are dropped for *matching* only; the
/// display form keeps them so emoji and CJK variation sequences still render.
bool isIgnoredForMatching(int codePoint) {
  if (codePoint < 0x80) return false;
  return (codePoint >= 0x00ad && codePoint <= 0x00ad) || // soft hyphen
      (codePoint >= 0x034f && codePoint <= 0x034f) || // combining grapheme joiner
      (codePoint >= 0x061c && codePoint <= 0x061c) || // Arabic letter mark
      (codePoint >= 0x115f && codePoint <= 0x1160) || // Hangul fillers
      (codePoint >= 0x17b4 && codePoint <= 0x17b5) || // Khmer inherent vowels
      (codePoint >= 0x180b && codePoint <= 0x180e) || // Mongolian selectors
      (codePoint >= 0x200b && codePoint <= 0x200f) || // ZWSP..RLM
      (codePoint >= 0x202a && codePoint <= 0x202e) || // bidi embeddings/override
      (codePoint >= 0x2060 && codePoint <= 0x2064) || // word joiner, invisible ops
      (codePoint >= 0x2066 && codePoint <= 0x2069) || // bidi isolates
      (codePoint >= 0xfeff && codePoint <= 0xfeff) || // BOM / ZWNBSP
      (codePoint >= 0xfe00 && codePoint <= 0xfe0f) || // variation selectors
      (codePoint >= 0xe0100 && codePoint <= 0xe01ef) || // VS supplement
      (codePoint >= 0xe0000 && codePoint <= 0xe007f); // tag characters
}

/// True for bidi embedding, override and isolate controls. These are removed
/// from the *display* form as well, because they can visually reorder text.
bool isBidiControl(int codePoint) =>
    (codePoint >= 0x202a && codePoint <= 0x202e) ||
    (codePoint >= 0x2066 && codePoint <= 0x2069) ||
    codePoint == 0x200e ||
    codePoint == 0x200f ||
    codePoint == 0x061c;

/// True for the universal combining-diacritic ranges that are stripped from
/// the matching skeleton. Script-specific vowel signs and tone marks (Indic,
/// Arabic, Hebrew, Thai, Japanese) are intentionally preserved: they are
/// letters, not evasion, and stripping them would collide distinct words.
bool isStrippableCombiningMark(int codePoint) =>
    (codePoint >= 0x0300 && codePoint <= 0x036f) || // combining diacriticals
    (codePoint >= 0x0483 && codePoint <= 0x0489) || // Cyrillic combining
    (codePoint >= 0x1ab0 && codePoint <= 0x1aff) ||
    (codePoint >= 0x1dc0 && codePoint <= 0x1dff) ||
    (codePoint >= 0x20d0 && codePoint <= 0x20ff) ||
    (codePoint >= 0xfe20 && codePoint <= 0xfe2f);

/// Unicode whitespace, collapsed to a single ASCII space in the skeleton.
bool isUnicodeWhitespace(int codePoint) =>
    codePoint == 0x09 ||
    codePoint == 0x0a ||
    codePoint == 0x0b ||
    codePoint == 0x0c ||
    codePoint == 0x0d ||
    codePoint == 0x20 ||
    codePoint == 0x85 ||
    codePoint == 0xa0 ||
    codePoint == 0x1680 ||
    (codePoint >= 0x2000 && codePoint <= 0x200a) ||
    codePoint == 0x2028 ||
    codePoint == 0x2029 ||
    codePoint == 0x202f ||
    codePoint == 0x205f ||
    codePoint == 0x3000;
