import 'confusables.dart';

/// What the normalizer observed and neutralized while preparing a message for
/// matching and display.
class TextSafetyFlags {
  /// Bidi embedding/override/isolate controls were present and were removed
  /// from the display text. These can visually reorder text and are never
  /// rendered by this pipeline.
  final bool hasBidiControls;

  /// Invisible characters (zero-width joiners/spaces, variation selectors,
  /// tag characters, ...) were present. They are kept in [NormalizedText.display]
  /// where they are needed for emoji/CJK rendering and dropped from the
  /// matching forms.
  final bool hasInvisibleCharacters;

  /// Universal combining diacritics were stripped from the matching forms
  /// (`fúck` -> `fuck`).
  final bool hasStrippedCombiningMarks;

  /// At least one lookalike or compatibility character was folded
  /// (`ŀove` / `lоve` -> `love`).
  final bool hasFoldedHomoglyphs;

  const TextSafetyFlags({
    this.hasBidiControls = false,
    this.hasInvisibleCharacters = false,
    this.hasStrippedCombiningMarks = false,
    this.hasFoldedHomoglyphs = false,
  });

  static const none = TextSafetyFlags();

  bool get hasAny =>
      hasBidiControls ||
      hasInvisibleCharacters ||
      hasStrippedCombiningMarks ||
      hasFoldedHomoglyphs;

  TextSafetyFlags copyWith({
    bool? hasBidiControls,
    bool? hasInvisibleCharacters,
    bool? hasStrippedCombiningMarks,
    bool? hasFoldedHomoglyphs,
  }) =>
      TextSafetyFlags(
        hasBidiControls: hasBidiControls ?? this.hasBidiControls,
        hasInvisibleCharacters:
            hasInvisibleCharacters ?? this.hasInvisibleCharacters,
        hasStrippedCombiningMarks:
            hasStrippedCombiningMarks ?? this.hasStrippedCombiningMarks,
        hasFoldedHomoglyphs: hasFoldedHomoglyphs ?? this.hasFoldedHomoglyphs,
      );
}

/// One message body after normalization.
///
/// Four views are produced from the same pass so the deterministic matcher and
/// the render path can never disagree about what the message says:
///
/// * [display] — safe to render: original text with bidi controls removed and
///   everything else preserved (emoji ZWJ sequences, variation selectors).
/// * [folded] — case-folded, lookalike-folded, invisible characters stripped,
///   universal combining marks stripped. Used for exact matching (emoji,
///   non-Latin scripts).
/// * [skeleton] — [folded] with all punctuation/symbols collapsed to single
///   spaces. Used for short-word token matching.
/// * [compact] — [skeleton] with common symbol substitutions folded
///   (`@`->`a`, `$`->`s`, `!`->`i`, `|`->`l`) and every non `[a-z0-9]`
///   character removed. This is the separator-blind form used for the main
///   substring match, so `f.u.c.k`, `f u c k` and `f*ck` all collapse the
///   same way.
class NormalizedText {
  final String display;
  final String folded;
  final String skeleton;
  final String compact;
  final TextSafetyFlags flags;

  const NormalizedText({
    required this.display,
    required this.folded,
    required this.skeleton,
    required this.compact,
    this.flags = TextSafetyFlags.none,
  });

  bool get isEmpty => display.trim().isEmpty;
}

/// Deterministic, dependency-free text normalization for on-device matching.
///
/// This is deliberately not a full NFC implementation: the pipeline matches
/// on a fold that is stronger than NFC anyway (marks stripped, lookalikes
/// mapped), and the display form is the sender's original text with unsafe
/// bidi controls removed. Full NFC is a future concern for a translator model,
/// which may itself require precomposed input.
class TextNormalizer {
  const TextNormalizer();

  static final RegExp _nonTokenRun = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final RegExp _nonAsciiAlnum = RegExp(r'[^a-z0-9]');

  NormalizedText normalize(String input) {
    final display = StringBuffer();
    final folded = StringBuffer();
    var hasBidi = false;
    var hasInvisible = false;
    var hasMarks = false;
    var hasFold = false;

    for (final codePoint in input.runes) {
      if (isBidiControl(codePoint)) {
        hasBidi = true;
        continue; // never rendered
      }
      display.writeCharCode(codePoint);

      if (isIgnoredForMatching(codePoint)) {
        hasInvisible = true;
        continue;
      }
      if (isStrippableCombiningMark(codePoint)) {
        hasMarks = true;
        continue;
      }
      if (isUnicodeWhitespace(codePoint)) {
        folded.write(' ');
        continue;
      }

      final lower = String.fromCharCode(codePoint).toLowerCase();
      for (final lowerCodePoint in lower.runes) {
        if (isIgnoredForMatching(lowerCodePoint)) {
          hasInvisible = true;
          continue;
        }
        if (isStrippableCombiningMark(lowerCodePoint)) {
          hasMarks = true;
          continue;
        }
        final mapped = foldCodePoint(lowerCodePoint);
        if (mapped != null) {
          hasFold = true;
          folded.write(mapped);
        } else {
          folded.writeCharCode(lowerCodePoint);
        }
      }
    }

    final foldedText = folded.toString();
    final skeleton =
        foldedText.replaceAll(_nonTokenRun, ' ').trim().toLowerCase();
    final compact = _compact(foldedText);

    return NormalizedText(
      display: display.toString(),
      folded: foldedText,
      skeleton: skeleton,
      compact: compact,
      flags: TextSafetyFlags(
        hasBidiControls: hasBidi,
        hasInvisibleCharacters: hasInvisible,
        hasStrippedCombiningMarks: hasMarks,
        hasFoldedHomoglyphs: hasFold,
      ),
    );
  }

  /// Symbol substitutions that survive the compact pass because they are
  /// typed as letters. Digit substitutions are *not* folded here: digits carry
  /// real information in messages, so digit-leet is handled by bounded
  /// wordlist variant expansion in `hidden_words.dart`.
  ///
  /// Built from the folded text, not the skeleton: the skeleton has already
  /// turned `$`, `@`, `!` and `|` into spaces, and those are exactly the
  /// substitutions this pass folds to letters.
  static String _compact(String folded) {
    final buffer = StringBuffer();
    for (final codePoint in folded.runes) {
      switch (codePoint) {
        case 0x40: // @
          buffer.write('a');
        case 0x24: // $
          buffer.write('s');
        case 0x21: // !
          buffer.write('i');
        case 0x7c: // |
          buffer.write('l');
        default:
          final char = String.fromCharCode(codePoint);
          if (_nonAsciiAlnum.hasMatch(char)) continue;
          buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
