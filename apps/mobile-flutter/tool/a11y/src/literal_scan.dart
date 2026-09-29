/// Finds hardcoded colour construction in widget code.
///
/// The rule under test: in a themed app, a colour literal in a screen or
/// widget file cannot respond to a theme change. That is not automatically a
/// bug — a drop shadow, a brand mark or a canvas that is dark in both themes
/// legitimately wants a literal — but it is always a *decision* that has to be
/// made deliberately, and this tool's job is to make sure it is one.
library;

import 'color.dart';
import 'dart_source.dart';

/// Every way this codebase builds a colour from constants.
final RegExp kColorConstructors = RegExp(
  r'Color\(\s*0[xX][0-9a-fA-F]{6,8}\s*\)'
  r'|Color\.fromARGB\s*\([^)]*\)'
  r'|Color\.fromRGBO\s*\([^)]*\)',
);

/// A hardcoded colour found in source.
class LiteralFinding {
  LiteralFinding({
    required this.path,
    required this.line,
    required this.column,
    required this.value,
    required this.role,
    required this.argLabel,
    required this.contextLabel,
    required this.sourceLine,
    required this.allowance,
  });

  final String path;
  final int line;
  final int column;

  /// The colour, or null when the constructor form was not a plain literal
  /// (`Color.fromARGB(255, g, b, a)` with symbolic arguments).
  final Argb? value;

  final ColorRole role;
  final String? argLabel;
  final String contextLabel;
  final String sourceLine;

  /// An `// a11y-allow: <reason>` annotation attached to the line, if present.
  final String? allowance;

  String get location => '$path:$line:$column';

  /// A theme-blind colour that a glyph or a surface is drawn in, and which
  /// therefore cannot track a theme switch.
  bool get isThemeBlind =>
      (role == ColorRole.surface ||
          role == ColorRole.gradientStop ||
          role == ColorRole.text) &&
      allowance == null;
}

/// `// a11y-allow: reason` on the same line, or on the line above.
///
/// An inline allowance is the right tool for a judgement that is local to one
/// line and explainable in a few words. Anything broader belongs in
/// `a11y_baseline.json`, so that a reviewer sees it once rather than trusting
/// a comment in a file they are not reading.
final RegExp kAllowComment = RegExp(r'a11y-allow\s*:\s*(.+)$');

/// The statement-scoped extent of an `// a11y-allow:` annotation.
///
/// An allowance on the line above a multi-line construct has to cover the whole
/// construct, not just the next line: a `BoxDecoration(gradient: LinearGradient(
/// colors: [a, b]))` puts four literals on four lines, and checking only the
/// immediately preceding line leaves three of them unannotated and the gate
/// still red. The extent therefore runs from the annotation to the next
/// semicolon in the masked source, which is the end of the statement it is
/// attached to. Semicolons inside strings and comments are blanked by the
/// mask, so they cannot end the range early.
class _AllowanceRange {
  const _AllowanceRange(this.from, this.to, this.reason);

  final int from;
  final int to;
  final String reason;

  bool contains(int offset) => offset >= from && offset <= to;
}

/// Every `// a11y-allow: reason` range in the file.
List<_AllowanceRange> _allowanceRanges(MaskedSource src) {
  final ranges = <_AllowanceRange>[];

  for (var line = 0; line < src.lineCount; line++) {
    final hit = kAllowComment.firstMatch(src.lineTextByIndex(line));
    if (hit == null) continue;

    final from = src.lineStartByIndex(line);
    final semicolon = src.masked.indexOf(';', from);
    final to = semicolon < 0 ? src.masked.length : semicolon;
    ranges.add(_AllowanceRange(from, to, hit.group(1)!.trim()));
  }

  return ranges;
}

String? _allowanceFor(List<_AllowanceRange> ranges, int offset) {
  for (final r in ranges) {
    if (r.contains(offset)) return r.reason;
  }
  return null;
}

/// Scans one file for hardcoded colours. [masked] must be masked so that
/// literals inside comments and strings are not reported.
List<LiteralFinding> scanFile(String path, String source) {
  final masked = maskSource(source);

  final matches = kColorConstructors.allMatches(masked.masked).toList();
  if (matches.isEmpty) return const [];

  final offsets = matches.map((m) => m.start).toList();
  final sites = resolveSites(masked, offsets);

  final allowances = _allowanceRanges(masked);

  final findings = <LiteralFinding>[];
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final site = sites[i];
    final text = m.group(0)!;

    Argb? value;
    final hex = RegExp(r'0[xX]([0-9a-fA-F]{6,8})').firstMatch(text);
    if (hex != null) {
      value = Argb.fromInt(int.parse(hex.group(1)!.padLeft(8, 'F'), radix: 16));
    }

    findings.add(LiteralFinding(
      path: path,
      line: masked.lineAt(m.start),
      column: masked.columnAt(m.start),
      value: value,
      role: classifySite(site),
      argLabel: site.argLabel,
      contextLabel: site.contextLabel,
      sourceLine: masked.lineText(m.start),
      allowance: _allowanceFor(allowances, m.start),
    ));
  }

  return findings;
}
