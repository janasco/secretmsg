import 'text_normalizer.dart';

/// How the deterministic hidden-words stage matches.
enum HiddenWordsMatchMode {
  /// Default. Separator-blind, lookalike-folded substring matching with
  /// repeated-character tolerance and bounded leet-variant expansion.
  evasionResistant,

  /// Reproduces the legacy server behavior as closely as the client can:
  /// case-insensitive / lookalike-folded substring of the message, without
  /// separator stripping, repetition tolerance or variant expansion. Kept so
  /// the difference between old and new enforcement is auditable in tests.
  plainSubstring,
}

/// A hit against one entry of the recipient's hidden-words list.
class HiddenWordsMatch {
  final String word;
  final int start;
  final int end;
  final bool repetitionTolerant;

  const HiddenWordsMatch({
    required this.word,
    required this.start,
    required this.end,
    this.repetitionTolerant = false,
  });

  @override
  String toString() =>
      'HiddenWordsMatch($word @$start..$end${repetitionTolerant ? ', repeated' : ''})';
}

/// Deterministic matching stage. This is the evasion-resistant part of the
/// pipeline and it must never be skipped: even when the user's sensitivity is
/// `off`, the pipeline runs it and records the result, because enforcement is a
/// UI policy while the *check* is the safety mechanism.
///
/// Match semantics (evasionResistant):
/// * The message and every list entry are normalized with [TextNormalizer].
/// * Entries whose `compact` form is 3+ characters match as a substring of the
///   compact message, so separators (`f.u.c.k`), zero-width characters and
///   lookalike letters cannot split the word.
/// * Each character in the matched word allows repetition in the message
///   (`fuuuck`) but the match must be at least as long as the word, so `as`
///   does not satisfy `ass`.
/// * Each entry is expanded into at most [_maxLeetVariants] digit-substitution
///   variants (`spam` -> `5pam`, `love` -> `l0ve`) so digit leet is caught
///   without folding digits in ordinary text.
/// * Entries shorter than 3 compact characters match whole tokens in the
///   skeleton, so a one-letter entry cannot match every message.
/// * Entries with no compact form (emoji, punctuation art) match as an exact
///   substring of the folded form.
///
/// Documented false positives: substring semantics mean an entry can match
/// inside a longer word (`ass` in `class`), exactly as the legacy server
/// substring check did. Reveal is one tap and never punishes the user.
class HiddenWordsFilter {
  HiddenWordsFilter({
    required List<String> words,
    TextNormalizer normalizer = const TextNormalizer(),
    this.mode = HiddenWordsMatchMode.evasionResistant,
  }) : _entries = _compile(words, normalizer, mode);

  /// Cap on generated leet variants per entry. Deterministic order, so the
  /// cap only weakens exotic multi-substitution spellings; nine substitutions
  /// in one short word is already unusual.
  static const int _maxLeetVariants = 64;

  final HiddenWordsMatchMode mode;
  final List<_CompiledWord> _entries;

  bool get isEmpty => _entries.isEmpty;

  /// Original, deduplicated word list, in user order.
  List<String> get words => _entries.map((e) => e.original).toList();

  HiddenWordsMatch? firstMatch(NormalizedText text) {
    for (final entry in _entries) {
      final match = entry.match(text, mode);
      if (match != null) return match;
    }
    return null;
  }

  bool matches(NormalizedText text) => firstMatch(text) != null;

  static List<_CompiledWord> _compile(
    List<String> words,
    TextNormalizer normalizer,
    HiddenWordsMatchMode mode,
  ) {
    final compiled = <_CompiledWord>[];
    final seen = <String>{};
    for (final raw in words) {
      final word = raw.trim();
      if (word.isEmpty) continue;
      final normalized = normalizer.normalize(word);
      if (normalized.folded.trim().isEmpty) continue;
      final key = '${normalized.folded}\u0000${normalized.compact}';
      if (!seen.add(key)) continue;
      compiled.add(_CompiledWord(
        original: word,
        folded: normalized.folded.trim(),
        skeleton: normalized.skeleton,
        compact: normalized.compact,
      ));
    }
    return compiled;
  }
}

enum _MatchKind { compactSubstring, token, exactFolded }

class _CompiledWord {
  _CompiledWord({
    required this.original,
    required this.folded,
    required this.skeleton,
    required this.compact,
  }) : _kind = switch (compact.length) {
          0 => _MatchKind.exactFolded,
          < 3 => _MatchKind.token,
          _ => _MatchKind.compactSubstring,
        } {
    if (_kind == _MatchKind.exactFolded) return;
    // Compact matching runs on the ASCII compact form; token matching must
    // run on the skeleton, because a short non-Latin word has an ASCII
    // compact form (or none) that cannot be found in the skeleton text.
    final source =
        _kind == _MatchKind.compactSubstring ? compact : skeleton;
    final variants = _expandLeet(source);
    _patterns = variants
        .map((variant) => RegExp(
              variant.runes
                  .map((r) => '${RegExp.escape(String.fromCharCode(r))}+')
                  .join(),
            ))
        .toList(growable: false);
  }

  final String original;
  final String folded;
  final String skeleton;
  final String compact;
  final _MatchKind _kind;
  late final List<RegExp> _patterns;

  HiddenWordsMatch? match(NormalizedText text, HiddenWordsMatchMode mode) {
    switch (mode) {
      case HiddenWordsMatchMode.plainSubstring:
        final index = text.folded.indexOf(folded);
        if (index < 0) return null;
        return HiddenWordsMatch(word: original, start: index, end: index + folded.length);
      case HiddenWordsMatchMode.evasionResistant:
        break;
    }

    switch (_kind) {
      case _MatchKind.exactFolded:
        final index = text.folded.indexOf(folded);
        if (index < 0) return null;
        return HiddenWordsMatch(
            word: original, start: index, end: index + folded.length);

      case _MatchKind.token:
        for (final pattern in _patterns) {
          for (final match in pattern.allMatches(text.skeleton)) {
            final beforeOk = match.start == 0 ||
                text.skeleton[match.start - 1] == ' ';
            final afterOk = match.end == text.skeleton.length ||
                text.skeleton[match.end] == ' ';
            if (!beforeOk || !afterOk) continue;
            return HiddenWordsMatch(
              word: original,
              start: match.start,
              end: match.end,
              repetitionTolerant: match.end - match.start > skeleton.length,
            );
          }
        }
        return null;

      case _MatchKind.compactSubstring:
        for (final pattern in _patterns) {
          for (final match in pattern.allMatches(text.compact)) {
            // Repetition tolerance must not make a shorter message match:
            // `as` may not satisfy `ass`.
            if (match.end - match.start < compact.length) continue;
            return HiddenWordsMatch(
              word: original,
              start: match.start,
              end: match.end,
              repetitionTolerant: match.end - match.start > compact.length,
            );
          }
        }
        return null;
    }
  }

  /// Bounded digit-leet expansion. Only digits are substituted: symbol
  /// substitutions (`@`, `$`, `!`, `|`) are folded on the text side in
  /// [TextNormalizer.compact], and folding them here too would double-count.
  static List<String> _expandLeet(String word) {
    const substitutes = <String, String>{
      'a': '4',
      'b': '8',
      'e': '3',
      'g': '9',
      'i': '1',
      'l': '1',
      'o': '0',
      's': '5',
      't': '7',
      'z': '2',
    };
    var variants = <String>[word];
    for (var i = 0; i < word.length; i++) {
      final option = substitutes[word[i]];
      if (option == null) continue;
      final next = <String>[];
      for (final variant in variants) {
        next.add(variant);
        next.add(
          '${variant.substring(0, i)}$option${variant.substring(i + 1)}',
        );
      }
      if (next.length > HiddenWordsFilter._maxLeetVariants) {
        next.removeRange(HiddenWordsFilter._maxLeetVariants, next.length);
      }
      variants = next;
      if (variants.length >= HiddenWordsFilter._maxLeetVariants) break;
    }
    return variants;
  }
}
