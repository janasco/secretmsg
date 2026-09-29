/// `dart run tool/a11y/lint.dart` — theme-blind colour detection and the
/// palette contrast matrix.
///
/// Two independent findings, deliberately not merged into one verdict:
///
///   1. A hardcoded colour literal in a widget or screen file, which cannot
///      respond to a theme change. This is the class of bug that shipped in
///      `daily_drop_screen.dart`: a dark gradient in both themes, with text
///      that resolved to a light-theme token, giving black on black at 1.06:1.
///
///   2. Every text-bearing palette token against every surface token, in both
///      themes, with alpha resolved against the surface it would sit on.
///
/// Exit status is the gate. `--strictness` (or `A11Y_LINT_STRICTNESS`) picks
/// what counts as fatal; the default fails on a new theme-blind surface and
/// leaves the pre-existing palette shortfalls reported but not fatal.
library;

import 'dart:io';

import 'src/baseline.dart';
import 'src/dart_source.dart';
import 'src/literal_scan.dart';
import 'src/matrix.dart';
import 'src/palette.dart';

const String kUsage = '''
dart run tool/a11y/lint.dart [options]

  --root=PATH        app root (default: found by walking up for pubspec.yaml)
  --lib=PATH         lib directory to scan (default: <root>/lib)
  --theme=PATH       theme file to parse (default: <lib>/theme.dart)
  --baseline=PATH    baseline JSON (default: <root>/tool/a11y/a11y_baseline.json)
  --strictness=LEVEL report | surface | text | strict
                     (env: A11Y_LINT_STRICTNESS; default: surface)
  --json             emit machine-readable JSON instead of the report
  --no-matrix        skip the contrast matrix
  --quiet            only print findings and the summary
''';

const int _exitUsage = 64;

void main(List<String> args) {
  final opts = _Options.parse(args);
  if (opts == null) {
    stdout.write(kUsage);
    return;
  }
  if (opts.help) {
    stdout.write(kUsage);
    return;
  }

  final code = _run(opts);
  exitCode = code;
}

class _Options {
  _Options({
    required this.root,
    required this.lib,
    required this.theme,
    required this.baseline,
    required this.strictness,
    required this.json,
    required this.matrix,
    required this.quiet,
  });

  final String root;
  final String lib;
  final String theme;
  final String baseline;
  final Strictness strictness;
  final bool json;
  final bool matrix;
  final bool quiet;
  final bool help = false;

  /// Returns null on an argument error, having already reported it.
  static _Options? parse(List<String> args) {
    String? root;
    String? lib;
    String? theme;
    String? baseline;
    var strictnessRaw =
        Platform.environment['A11Y_LINT_STRICTNESS'] ?? 'surface';
    var json = false;
    var matrix = true;
    var quiet = false;

    for (final arg in args) {
      if (arg == '--json') {
        json = true;
      } else if (arg == '--no-matrix') {
        matrix = false;
      } else if (arg == '--quiet') {
        quiet = true;
      } else if (arg == '--help' || arg == '-h') {
        return _Options(
          root: '',
          lib: '',
          theme: '',
          baseline: '',
          strictness: Strictness.report,
          json: false,
          matrix: false,
          quiet: false,
        );
      } else if (arg.startsWith('--root=')) {
        root = arg.substring('--root='.length);
      } else if (arg.startsWith('--lib=')) {
        lib = arg.substring('--lib='.length);
      } else if (arg.startsWith('--theme=')) {
        theme = arg.substring('--theme='.length);
      } else if (arg.startsWith('--baseline=')) {
        baseline = arg.substring('--baseline='.length);
      } else if (arg.startsWith('--strictness=')) {
        strictnessRaw = arg.substring('--strictness='.length);
      } else {
        stderr.writeln('unknown argument: $arg');
        return null;
      }
    }

    final Strictness strictness;
    try {
      strictness = Strictness.parse(strictnessRaw);
    } on FormatException catch (e) {
      stderr.writeln(e.message);
      return null;
    }

    final found = root ?? _findAppRoot();
    if (found == null) {
      stderr.writeln('could not locate the app root; pass --root=PATH');
      return null;
    }

    return _Options(
      root: found,
      lib: lib ?? '$found/lib',
      theme: theme ?? '${lib ?? '$found/lib'}/theme.dart',
      baseline: baseline ?? '$found/tool/a11y/a11y_baseline.json',
      strictness: strictness,
      json: json,
      matrix: matrix,
      quiet: quiet,
    );
  }
}

int _run(_Options opts) {
  if (!Directory(opts.lib).existsSync()) {
    stderr.writeln('no such lib directory: ${opts.lib}');
    return _exitUsage;
  }
  if (!File(opts.theme).existsSync()) {
    stderr.writeln('no such theme file: ${opts.theme}');
    return _exitUsage;
  }

  var baseline = const Baseline();
  final baselineExists = File(opts.baseline).existsSync();
  if (baselineExists) {
    try {
      baseline = Baseline.parse(File(opts.baseline).readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln('could not parse ${opts.baseline}: ${e.message}');
      return _exitUsage;
    }
  }

  // --- Part 1: hardcoded literals in widget code -------------------------

  final findings = <LiteralFinding>[];
  for (final entity
      in Directory(opts.lib).listSync(recursive: true).whereType<File>()) {
    final path = entity.path;
    if (!_isScannable(path)) continue;
    final relative = path.startsWith('${opts.root}/')
        ? path.substring(opts.root.length + 1)
        : path;
    findings.addAll(scanFile(relative, entity.readAsStringSync()));
  }
  findings.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });

  // --- Part 2: the palette contrast matrix -------------------------------

  Palette? palette;
  ContrastMatrix? matrix;
  final cells = <MatrixCell>[];
  if (opts.matrix) {
    try {
      palette = parsePalette(File(opts.theme).readAsStringSync());
    } on FormatException catch (e) {
      stderr.writeln('could not parse the palette: ${e.message}');
      return _exitUsage;
    }
    matrix = buildMatrix(palette);
    cells.addAll(matrix.cells);
  }

  // --- Triage ------------------------------------------------------------

  final fatal = <String>[];
  final warned = <String>[];

  for (final f in findings) {
    if (f.allowance != null) continue;
    if (baseline.hasLiteral(f.path, f.line, f.role)) continue;

    final label = '${f.location} ${f.role.label}';
    switch (f.role) {
      case ColorRole.surface:
      case ColorRole.gradientStop:
        if (opts.strictness != Strictness.report) fatal.add(label);
      case ColorRole.text:
        if (opts.strictness == Strictness.text ||
            opts.strictness == Strictness.strict) {
          fatal.add(label);
        } else {
          warned.add(label);
        }
      case ColorRole.border:
      case ColorRole.shadow:
      case ColorRole.unknown:
        break;
    }
  }

  final newPairings = <MatrixCell>[];
  for (final c in cells) {
    if (c.passesAA) continue;
    if (baseline.hasPairing(c.theme, c.text, c.surface)) continue;
    newPairings.add(c);
    if (opts.strictness == Strictness.strict) {
      fatal.add('${c.key} ${c.ratio.toStringAsFixed(2)}:1');
    }
  }

  if (opts.json) {
    stdout.writeln(_renderJson(
      strictness: opts.strictness,
      findings: findings,
      cells: cells,
      newPairings: newPairings,
      fatal: fatal,
      warned: warned,
      palette: palette,
    ));
  } else {
    stdout.write(_renderReport(
      strictness: opts.strictness,
      findings: findings,
      matrix: matrix,
      newPairings: newPairings,
      fatal: fatal,
      warned: warned,
      baseline: baseline,
      baselinePath: opts.baseline,
      baselineExists: baselineExists,
      liveLiteralKeys: {
        for (final f in findings) '${f.path}:${f.line}:${f.role.label}',
      },
      quiet: opts.quiet,
    ));
  }

  if (fatal.isEmpty) {
    stdout.writeln('a11y lint: pass (${opts.strictness.blurb})');
    return 0;
  }
  stdout
      .writeln('a11y lint: FAIL — ${fatal.length} finding(s) under strictness '
          '`${opts.strictness.id}`');
  for (final f in fatal) {
    stdout.writeln('  $f');
  }
  return 1;
}

/// A widget/screen file. The tool is not interested in the palette file,
/// which is where literals legitimately live.
bool _isScannable(String path) {
  if (!path.endsWith('.dart')) return false;
  return path.split('/').last != 'theme.dart';
}

String _renderReport({
  required Strictness strictness,
  required List<LiteralFinding> findings,
  required ContrastMatrix? matrix,
  required List<MatrixCell> newPairings,
  required List<String> fatal,
  required List<String> warned,
  required Baseline baseline,
  required String baselinePath,
  required bool baselineExists,
  required Set<String> liveLiteralKeys,
  required bool quiet,
}) {
  final b = StringBuffer();

  if (!quiet) {
    b.writeln('=' * 78);
    b.writeln('a11y lint — strictness: ${strictness.id} (${strictness.blurb})');
    b.writeln('=' * 78);
  }

  _renderLiterals(b, findings, baseline, baselinePath, liveLiteralKeys);

  if (matrix != null) {
    if (!quiet) {
      b.writeln();
      b.writeln(
          'CONTRAST MATRIX  (WCAG 2.1, text token x surface token, alpha resolved)');
      b.writeln('-' * 78);
      b.writeln(
          '  legend: blank = AA (>=4.5)   ~ = 3:1, large text only   X = below 3:1');
      b.writeln();
      b.writeln(matrix.render(
          'dark',
          _tokensPresent(kTextTokens, matrix.cells, 'dark', true),
          _tokensPresent(kSurfaceTokens, matrix.cells, 'dark', false)));
      b.writeln();
      b.writeln(matrix.render(
          'light',
          _tokensPresent(kTextTokens, matrix.cells, 'light', true),
          _tokensPresent(kSurfaceTokens, matrix.cells, 'light', false)));
    }
    _renderPairings(b, newPairings, baseline, baselinePath, !quiet);
  }

  b.writeln();
  b.writeln('SUMMARY');
  b.writeln('-' * 78);
  b.writeln('  theme-blind surface literals (new)   '
      '${fatal.where((f) => f.contains('surface') || f.contains('gradient')).length}');
  b.writeln('  theme-blind text literals (new)       ${warned.length}');
  b.writeln('  palette pairings below AA (new)       ${newPairings.length}');
  b.writeln('  baselined exceptions still in play   '
      '${baseline.literals.where((e) => liveLiteralKeys.contains(e.key)).length}'
      ' of ${baseline.literals.length}');
  if (!baselineExists) {
    b.writeln('  (no baseline file at $baselinePath)');
  }

  return b.toString();
}

void _renderLiterals(
  StringBuffer b,
  List<LiteralFinding> findings,
  Baseline baseline,
  String baselinePath,
  Set<String> liveLiteralKeys,
) {
  b.writeln();
  b.writeln('THEME-BLIND COLOUR LITERALS IN WIDGET CODE');
  b.writeln('-' * 78);

  if (findings.isEmpty) {
    b.writeln(
        '  none. Every colour in lib/ outside theme.dart is a palette token');
    b.writeln('  reference or an annotated exception.');
    return;
  }

  for (final f in findings) {
    final value = f.value == null ? '(non-literal constructor)' : f.value!.hex;
    final allowed = f.allowance != null;
    final baselined = !allowed && baseline.hasLiteral(f.path, f.line, f.role);
    final fatal = !allowed &&
        !baselined &&
        (f.role == ColorRole.surface || f.role == ColorRole.gradientStop);

    // The mark is the finding's disposition, and it has to agree with the
    // fatal list below. An annotated literal is `allowed`, not `DEFECT`:
    // printing DEFECT next to a reason that explains why it is fine reads as
    // a contradiction, and a report that contradicts itself is a report
    // nobody triages.
    final mark = switch (f.role) {
      ColorRole.surface ||
      ColorRole.gradientStop =>
        allowed ? 'ok    ' : (baselined ? 'known ' : 'DEFECT'),
      ColorRole.text => allowed ? 'ok    ' : 'text  ',
      ColorRole.border => 'border',
      ColorRole.shadow => 'shadow',
      ColorRole.unknown => '?????',
    };

    b.writeln(
        '  $mark ${f.location}  $value  ${f.role.label}  in ${f.contextLabel}');
    b.writeln('         ${f.sourceLine}');
    final reason =
        f.allowance ?? baseline.reasonForLiteral(f.path, f.line, f.role);
    if (reason != null) {
      b.writeln('         ${allowed ? 'allowed' : 'baselined'}: $reason');
    }
    if (fatal) {
      b.writeln('         ^ fatal at strictness `surface` and above');
    }
    b.writeln();
  }

  final byRole = <ColorRole, int>{};
  for (final f in findings) {
    byRole[f.role] = (byRole[f.role] ?? 0) + 1;
  }
  b.writeln('  ${findings.length} literal(s):');
  for (final role in ColorRole.values) {
    final n = byRole[role];
    if (n != null) b.writeln('    ${n.toString().padLeft(3)}  ${role.label}');
  }

  final stale = baseline.staleAgainst(liveLiteralKeys);
  if (stale.isNotEmpty) {
    b.writeln();
    b.writeln(
        '  STALE BASELINE ENTRIES — the code they described has changed.');
    b.writeln(
        '  Re-check each, then delete it from $baselinePath if no longer needed:');
    for (final e in stale) {
      b.writeln('    ${e.key}  ${e.reason}');
    }
  }
}

void _renderPairings(
  StringBuffer b,
  List<MatrixCell> newPairings,
  Baseline baseline,
  String baselinePath,
  bool verbose,
) {
  final failingLarge = newPairings.where((c) => !c.passesLargeText).toList();
  final failingAA = newPairings.where((c) => c.passesLargeText).toList();

  b.writeln();
  b.writeln('PALETTE PAIRINGS BELOW AA (not in the baseline)');
  b.writeln('-' * 78);
  if (newPairings.isEmpty) {
    b.writeln('  none new.');
    final cells = baseline.pairings.fold<int>(0, (n, p) => n + p.keys.length);
    if (cells > 0) {
      b.writeln(
          '  ${baseline.pairings.length} recorded group(s) covering $cells cell(s) still');
      b.writeln(
          '  fail. They are still visible in the tables above, and their');
      b.writeln('  reasons are recorded in $baselinePath.');
      if (verbose) {
        // The reasons are the point of the baseline. Printing them on every
        // run is what stops them rotting into "we fixed this at some point".
        for (final p in baseline.pairings) {
          b.writeln();
          b.writeln('    ${p.worst}  (${p.keys.length} cell(s))');
          for (final line in _wrap(p.reason)) {
            b.writeln('      $line');
          }
        }
      }
    }
    return;
  }

  b.writeln(
      '  These are POSSIBLE pairings, not observed ones. A cell only becomes a');
  b.writeln('  bug when a screen puts those two tokens together.');
  b.writeln();
  b.writeln('  below 3:1 — unreadable at any size (${failingLarge.length})');
  for (final c in _byRatio(failingLarge)) {
    b.writeln(
        '    X ${c.key.padRight(32)} ${c.ratio.toStringAsFixed(2).padLeft(6)}:1   '
        'fg ${c.foreground.css} on ${c.background.css}');
  }
  b.writeln('  3:1 to 4.5:1 — large text only (${failingAA.length})');
  for (final c in _byRatio(failingAA)) {
    b.writeln(
        '    ~ ${c.key.padRight(32)} ${c.ratio.toStringAsFixed(2).padLeft(6)}:1   '
        'fg ${c.foreground.css} on ${c.background.css}');
  }
}

/// Greedy word wrap, so a long recorded reason stays readable in a terminal
/// instead of running off the edge.
List<String> _wrap(String text, [int width = 68]) {
  final words = text.split(RegExp(r'\s+'));
  final lines = <String>[];
  var line = '';
  for (final w in words) {
    if (line.isEmpty) {
      line = w;
    } else if (line.length + 1 + w.length <= width) {
      line = '$line $w';
    } else {
      lines.add(line);
      line = w;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}

List<MatrixCell> _byRatio(List<MatrixCell> cells) {
  final copy = [...cells];
  copy.sort((a, b) {
    final byRatio = a.ratio.compareTo(b.ratio);
    return byRatio != 0 ? byRatio : a.key.compareTo(b.key);
  });
  return copy;
}

List<String> _tokensPresent(
  Iterable<String> candidates,
  List<MatrixCell> cells,
  String theme,
  bool isText,
) {
  return candidates
      .where((name) => cells.any(
          (c) => c.theme == theme && (isText ? c.text : c.surface) == name))
      .toList();
}

String _renderJson({
  required Strictness strictness,
  required List<LiteralFinding> findings,
  required List<MatrixCell> cells,
  required List<MatrixCell> newPairings,
  required List<String> fatal,
  required List<String> warned,
  required Palette? palette,
}) {
  final b = StringBuffer();
  b.writeln('{');
  b.writeln('  "strictness": "${strictness.id}",');
  b.writeln('  "literals": [');
  for (var i = 0; i < findings.length; i++) {
    final f = findings[i];
    b.writeln('    {"location": "${_jsonStr(f.location)}", '
        '"role": "${f.role.label}", '
        '"value": "${f.value?.hex ?? ""}", '
        '"context": "${_jsonStr(f.contextLabel)}", '
        '"allowance": "${_jsonStr(f.allowance ?? "")}"}'
        '${i == findings.length - 1 ? '' : ','}');
  }
  b.writeln('  ],');
  b.writeln('  "pairings_below_aa": [');
  for (var i = 0; i < newPairings.length; i++) {
    final c = newPairings[i];
    b.writeln('    {"key": "${c.key}", '
        '"ratio": ${c.ratio.toStringAsFixed(3)}, '
        '"grade": "${c.grade.label}", '
        '"fg": "${c.foreground.css}", '
        '"bg": "${c.background.css}"}'
        '${i == newPairings.length - 1 ? '' : ','}');
  }
  b.writeln('  ],');
  b.writeln('  "fatal": [');
  for (var i = 0; i < fatal.length; i++) {
    b.writeln('    "${_jsonStr(fatal[i])}"${i == fatal.length - 1 ? '' : ','}');
  }
  b.writeln('  ],');
  b.writeln('  "warned": [');
  for (var i = 0; i < warned.length; i++) {
    b.writeln(
        '    "${_jsonStr(warned[i])}"${i == warned.length - 1 ? '' : ','}');
  }
  b.writeln('  ],');
  b.writeln('  "palette": {');
  final tokens = palette?.tokens.values.toList() ?? <PaletteToken>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    b.writeln(
        '    "${t.name}": {"dark": "${t.dark.hex}", "light": "${t.light.hex}"}'
        '${i == tokens.length - 1 ? '' : ','}');
  }
  b.writeln('  }');
  b.writeln('}');
  return b.toString();
}

String _jsonStr(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');

String? _findAppRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
