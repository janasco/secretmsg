/// Script-level language detection. This is *not* full language
/// identification: it can tell Latin from Cyrillic from Han, not English from
/// German. The pipeline uses it only to decide whether translation is
/// plausibly needed; a real per-language ID model is a separate signed bundle
/// and is not shipped in this change.
class DetectedLanguage {
  /// BCP-47-ish tag. Script-only results use `und-<Script>`
  /// (for example `und-Cyrl`); a real model may return a concrete language.
  final String tag;
  final String script;
  final double confidence;
  final DetectionMethod method;

  const DetectedLanguage({
    required this.tag,
    required this.script,
    required this.confidence,
    required this.method,
  });

  bool get isUnknown => script == 'Zyyy' || tag == 'und' || confidence < 0.6;
}

enum DetectionMethod { scriptHeuristic, model, hint }

abstract interface class LanguageIdentifier {
  DetectedLanguage detect(String text);
}

/// Counts letters per script and returns `und-<Script>` for a dominant script.
///
/// Honest limits, restated in the docs: same-script language differences
/// (Spanish vs English) are invisible to this identifier. Until a real
/// language-ID model ships, the pipeline will not auto-translate same-script
/// text; it never calls a network service to find out.
class ScriptHeuristicLanguageIdentifier implements LanguageIdentifier {
  const ScriptHeuristicLanguageIdentifier();

  static const String _unknown = 'und-Zyyy';

  @override
  DetectedLanguage detect(String text) {
    final counts = <String, int>{};
    var letters = 0;
    for (final codePoint in text.runes) {
      final script = scriptOfCodePoint(codePoint);
      if (script == null) continue;
      letters++;
      counts[script] = (counts[script] ?? 0) + 1;
    }
    if (letters == 0) {
      return const DetectedLanguage(
        tag: _unknown,
        script: 'Zyyy',
        confidence: 0,
        method: DetectionMethod.scriptHeuristic,
      );
    }
    var dominant = 'Zyyy';
    var dominantCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > dominantCount) {
        dominant = entry.key;
        dominantCount = entry.value;
      }
    }
    final confidence = dominantCount / letters;
    if (confidence < 0.6) {
      return const DetectedLanguage(
        tag: _unknown,
        script: 'Zyyy',
        confidence: 0.6,
        method: DetectionMethod.scriptHeuristic,
      );
    }
    return DetectedLanguage(
      tag: 'und-$dominant',
      script: dominant,
      confidence: confidence,
      method: DetectionMethod.scriptHeuristic,
    );
  }
}

/// Null for non-letters and scripts we do not track.
String? scriptOfCodePoint(int codePoint) {
  if ((codePoint >= 0x41 && codePoint <= 0x5a) ||
      (codePoint >= 0x61 && codePoint <= 0x7a) ||
      (codePoint >= 0xc0 && codePoint <= 0x24f) ||
      (codePoint >= 0x1e00 && codePoint <= 0x1eff) ||
      (codePoint >= 0x2c60 && codePoint <= 0x2c7f) ||
      (codePoint >= 0xa720 && codePoint <= 0xa7ff)) {
    return 'Latn';
  }
  if ((codePoint >= 0x400 && codePoint <= 0x52f) ||
      (codePoint >= 0x1c80 && codePoint <= 0x1c8f) ||
      (codePoint >= 0x2de0 && codePoint <= 0x2dff) ||
      (codePoint >= 0xa640 && codePoint <= 0xa69f)) {
    return 'Cyrl';
  }
  if ((codePoint >= 0x370 && codePoint <= 0x3ff) ||
      (codePoint >= 0x1f00 && codePoint <= 0x1fff)) {
    return 'Grek';
  }
  if ((codePoint >= 0x600 && codePoint <= 0x6ff) ||
      (codePoint >= 0x750 && codePoint <= 0x77f) ||
      (codePoint >= 0x8a0 && codePoint <= 0x8ff) ||
      (codePoint >= 0xfb50 && codePoint <= 0xfdff) ||
      (codePoint >= 0xfe70 && codePoint <= 0xfeff)) {
    return 'Arab';
  }
  if ((codePoint >= 0x590 && codePoint <= 0x5ff) ||
      (codePoint >= 0xfb1d && codePoint <= 0xfb4f)) {
    return 'Hebr';
  }
  if (codePoint >= 0x900 && codePoint <= 0x97f) return 'Deva';
  if ((codePoint >= 0x4e00 && codePoint <= 0x9fff) ||
      (codePoint >= 0x3400 && codePoint <= 0x4dbf) ||
      (codePoint >= 0xf900 && codePoint <= 0xfaff) ||
      (codePoint >= 0x20000 && codePoint <= 0x3134f)) {
    return 'Hani';
  }
  if (codePoint >= 0x3040 && codePoint <= 0x309f) return 'Hira';
  if ((codePoint >= 0x30a0 && codePoint <= 0x30ff) ||
      (codePoint >= 0x31f0 && codePoint <= 0x31ff)) {
    return 'Kana';
  }
  if ((codePoint >= 0xac00 && codePoint <= 0xd7af) ||
      (codePoint >= 0x1100 && codePoint <= 0x11ff) ||
      (codePoint >= 0x3130 && codePoint <= 0x318f)) {
    return 'Hang';
  }
  if (codePoint >= 0xe00 && codePoint <= 0xe7f) return 'Thai';
  return null;
}

/// Primary language -> usual script, for the languages the product is likely
/// to see. Used only to avoid attempting translation when the message is
/// already written in the user's script; extending this map is data, not code.
String? scriptOfLanguage(String? languageTag) {
  if (languageTag == null) return null;
  final primary = languageTag.trim().toLowerCase().split('-').first;
  switch (primary) {
    case 'en':
    case 'de':
    case 'fr':
    case 'es':
    case 'pt':
    case 'it':
    case 'nl':
    case 'pl':
    case 'tr':
    case 'id':
    case 'ms':
    case 'vi':
    case 'ro':
    case 'sv':
    case 'da':
    case 'no':
    case 'fi':
    case 'cs':
    case 'sk':
    case 'hu':
    case 'hr':
    case 'sl':
    case 'et':
    case 'lv':
    case 'lt':
    case 'tl':
    case 'sw':
    case 'af':
    case 'ca':
    case 'eu':
    case 'gl':
    case 'sq':
    case 'az':
    case 'uz':
      return 'Latn';
    case 'ru':
    case 'uk':
    case 'bg':
    case 'sr':
    case 'mk':
    case 'be':
    case 'ky':
    case 'mn':
      return 'Cyrl';
    case 'el':
      return 'Grek';
    case 'ar':
    case 'fa':
    case 'ur':
      return 'Arab';
    case 'he':
    case 'yi':
      return 'Hebr';
    case 'hi':
    case 'mr':
    case 'ne':
      return 'Deva';
    case 'zh':
      return 'Hani';
    case 'ja':
      return 'Hira';
    case 'ko':
      return 'Hang';
    case 'th':
      return 'Thai';
    default:
      return null;
  }
}
