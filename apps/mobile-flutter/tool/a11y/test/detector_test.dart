/// Acceptance test for the detector, run as part of the gate.
///
/// Why this is a plain `dart run` script and not a `flutter test`: the point
/// is that the parsing half of the tool needs no Flutter toolchain, and a
/// `flutter test` would make the detector's own test suite cost a minute of
/// gate time to prove something that takes 40 ms. It is wired into
/// `scripts/verify.sh` as its own named check for the same reason.
library;

///
/// The acceptance criterion is narrow and non-negotiable: a detector that
/// cannot catch the gradient that actually shipped is worthless. So the first
/// two cases run the detector over a fixture carrying that exact pattern, and
/// assert it is flagged; the third asserts the correctly-themed version is not.

import 'dart:convert';
import 'dart:io';

import '../src/baseline.dart';
import '../src/color.dart';
import '../src/dart_source.dart';
import '../src/literal_scan.dart';
import '../src/palette.dart';

int _failures = 0;
int _checks = 0;

void check(String what, bool ok, [String detail = '']) {
  _checks++;
  if (ok) {
    stdout.writeln('  ok    $what');
  } else {
    _failures++;
    stdout.writeln('  FAIL  $what${detail.isEmpty ? '' : '  ($detail)'}');
  }
}

void checkClose(String what, double actual, double expected, double tolerance) {
  check(
    what,
    (actual - expected).abs() <= tolerance,
    'got ${actual.toStringAsFixed(3)}, expected ${expected.toStringAsFixed(3)} +/- $tolerance',
  );
}

void main() {
  final fixtures = _fixturesDir();

  stdout.writeln('a11y detector acceptance test');
  stdout.writeln('-' * 70);

  _testTheShippedBug(fixtures);
  _testTheFixedVersionIsClean(fixtures);
  _testBenignContexts(fixtures);
  _testInlineAllowance();
  _testColorMath();
  _testPaletteParse(fixtures);
  _testBaselineRoundTrip();
  _testReportIsValidJson();
  _testTheLiveAppIsClean();

  stdout.writeln('-' * 70);
  if (_failures == 0) {
    stdout.writeln('a11y detector: all $_checks checks passed');
    return;
  }
  stdout.writeln('a11y detector: $_failures of $_checks checks FAILED');
  exitCode = 1;
}

String _fixturesDir() {
  final here = Directory.current.path;
  for (final candidate in [
    '$here/tool/a11y/test/fixtures',
    '$here/test/fixtures',
  ]) {
    if (Directory(candidate).existsSync()) return candidate;
  }
  throw StateError('could not find the fixture directory from $here');
}

List<LiteralFinding> _scan(String dir, String name) =>
    scanFile('fixtures/$name', File('$dir/$name').readAsStringSync());

/// The core acceptance criterion.
///
/// This is the shape of the bug fixed in 43aa190: `colors: [Color(0xFF2A2356),
/// Color(0xFF151B26)]` in a `LinearGradient` inside a `BoxDecoration`. Both
/// stops are dark, the surface is identical in both themes, and the text above
/// it resolves to a light-theme token. The detector has to call both stops
/// theme-blind surfaces, or it does not work.
void _testTheShippedBug(String dir) {
  stdout.writeln('the shipped bug: theme-blind gradient in a widget file');
  final findings = _scan(dir, 'theme_blind_gradient.dart');

  final defective = findings
      .where((f) => f.contextLabel.contains('LinearGradient'))
      .where((f) => f.role == ColorRole.gradientStop)
      .toList();

  check('both gradient stops are reported', defective.length == 2,
      'got ${defective.length}');

  final values = defective.map((f) => f.value?.hex).toSet();
  check(
      'the exact shipped literals are the ones found',
      values.contains('0xFF2A2356') && values.contains('0xFF151B26'),
      'got $values');

  check('they are fatal at the default strictness',
      defective.every((f) => f.isThemeBlind));

  // The values must also be dark enough that the bug was real. If a future
  // edit made the fixture's stops light, the detector assertions would still
  // pass while testing nothing, so the damage is measured here too.
  //
  // #191C2F is the 50/50 blend of the two stops, which is the surface the
  // prompt text actually sat over; the fix commit recorded that pairing at
  // 1.06:1. The pure second stop is 1.03:1. Both are quoted, because a
  // detector that cannot reproduce the published number is not measuring the
  // same thing the person who filed the bug measured.
  checkClose(
    'the defect was real: light textPrimary on the blended stop is 1.06',
    contrastRatio(Argb.parse('0xFF0F172A'), Argb.parse('#191C2F')),
    1.06,
    0.01,
  );
  checkClose(
    '...and on the pure second stop it is 1.03',
    contrastRatio(Argb.parse('0xFF0F172A'), Argb.parse('0xFF151B26')),
    1.03,
    0.01,
  );
  check('the old stop is genuinely dark', Argb.parse('0xFF151B26').r < 40);
  // The two are within a shade of each other channel-wise, which is the whole
  // point: black text on a near-black surface.
  final ink = Argb.parse('0xFF0F172A');
  final stop = Argb.parse('0xFF151B26');
  check(
      'the light text token and that stop are within a shade of each other',
      (ink.r - stop.r).abs() < 0x20 &&
          (ink.g - stop.g).abs() < 0x20 &&
          (ink.b - stop.b).abs() < 0x20);
}

/// The negative case. A detector that flags everything is as useless as one
/// that flags nothing, so the correctly-themed card must come back clean.
void _testTheFixedVersionIsClean(String dir) {
  stdout.writeln('the fixed version: gradient reads palette tokens');
  final findings = _scan(dir, 'theme_blind_gradient.dart')
      .where((f) => f.contextLabel.contains('Container'))
      .where((f) => f.line > 40)
      .toList();

  check('no literals at all in the themed card', findings.isEmpty,
      'got ${findings.map((f) => f.location).toList()}');
}

/// Cases where a raw literal is the right answer. If any of these were fatal,
/// the gate would be red on correct code and would get switched off.
void _testBenignContexts(String dir) {
  stdout.writeln('benign contexts: literals that are correct');
  final findings = _scan(dir, 'benign_contexts.dart');

  LiteralFinding? at(int line) {
    for (final f in findings) {
      if (f.line == line) return f;
    }
    return null;
  }

  // The line numbers are read out of the fixture rather than hardcoded, so
  // editing the fixture cannot silently turn these checks into no-ops.
  int lineOf(String needle) {
    final lines = File('$dir/benign_contexts.dart').readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].contains(needle)) return i + 1;
    }
    throw StateError('fixture no longer contains "$needle"');
  }

  check(
      'a BoxShadow colour is a shadow, not a surface',
      at(lineOf('0x33000000'))?.role == ColorRole.shadow,
      'got ${at(lineOf('0x33000000'))?.role}');
  check(
      'a border colour is a border, not a surface',
      at(lineOf('0x1FFFFFFF'))?.role == ColorRole.border,
      'got ${at(lineOf('0x1FFFFFFF'))?.role}');
  check(
      'a white-on-brand icon is text/icon',
      at(lineOf('Icons.verified'))?.role == ColorRole.text,
      'got ${at(lineOf('Icons.verified'))?.role}');
  check(
      'a brand gradient is a gradient stop, which is a real finding to triage',
      at(lineOf('0xFF4F46E5'))?.role == ColorRole.gradientStop,
      'got ${at(lineOf('0xFF4F46E5'))?.role}');
  // A QR code's quiet zone has to stay white in both themes or the scanner
  // loses the contrast it needs, so this one is a *reported* surface literal
  // that the app answers with an inline allowance rather than a token.
  final quietZone = at(lineOf('color: const Color(0xFFFFFFFF)'));
  check('a QR quiet zone is classified as a surface',
      quietZone?.role == ColorRole.surface, 'got ${quietZone?.role}');
}

/// `// a11y-allow: <reason>` is the escape hatch for a judgement that is local
/// to one line. It has to work from the line itself and from the line above.
void _testInlineAllowance() {
  stdout.writeln('inline allowances');

  final sameLine = scanFile('t.dart', '''
final a = Container(color: const Color(0xFF101322)); // a11y-allow: QR quiet zone
''');
  check(
      'an allowance on the same line suppresses the finding',
      sameLine.single.allowance == 'QR quiet zone',
      'got ${sameLine.single.allowance}');
  check('an allowed literal is not theme-blind', !sameLine.single.isThemeBlind);

  final above = scanFile('t.dart', '''
// a11y-allow: matches the upstream challenge theme
final b = ColoredBox(color: const Color(0xFF101322));
''');
  check(
      'an allowance on the line above suppresses the finding',
      above.single.allowance == 'matches the upstream challenge theme',
      'got ${above.single.allowance}');

  final none = scanFile(
      't.dart', 'final c = Container(color: const Color(0xFF101322));\n');
  check(
      'without an allowance the finding stands', none.single.allowance == null);
  check('and it is theme-blind', none.single.isThemeBlind);

  final ignored = scanFile('t.dart', '''
// Color(0xFFDEADBE) in a comment is not a colour
final d = 'Color(0xFF2A2356) inside a string is not a colour either';
''');
  check('comments and strings are not scanned', ignored.isEmpty,
      'got ${ignored.map((f) => f.location).toList()}');
}

/// The colour maths has to be right or every number in the report is wrong.
/// These are WCAG's own reference values.
void _testColorMath() {
  stdout.writeln('colour maths');

  checkClose('black on white is 21.0',
      contrastRatio(Argb.parse('#000000'), Argb.parse('#FFFFFF')), 21.0, 0.001);
  checkClose('white on black is 21.0',
      contrastRatio(Argb.parse('#FFFFFF'), Argb.parse('#000000')), 21.0, 0.001);
  checkClose('identical colours are 1.0',
      contrastRatio(Argb.parse('#123456'), Argb.parse('#123456')), 1.0, 0.001);
  checkClose('#767676 on white is 4.54 (the canonical AA boundary grey)',
      contrastRatio(Argb.parse('#767676'), Argb.parse('#FFFFFF')), 4.54, 0.01);
  // #959595 lands on 2.995:1, just under the 3:1 AA-large threshold. It is
  // the boundary the grading code is most likely to get wrong by an inclusive
  // comparison, so it is pinned from both sides.
  checkClose(
      '#959595 on white is 2.995, just under AA-large',
      contrastRatio(Argb.parse('#959595'), Argb.parse('#FFFFFF')),
      2.995,
      0.005);
  check(
      '...and it is graded below AA-large',
      WcagGrade.of(
              contrastRatio(Argb.parse('#959595'), Argb.parse('#FFFFFF'))) ==
          WcagGrade.fail);

  // Two values the fix commit recorded by hand, so a maths regression is
  // caught against the numbers a human already published.
  checkClose('white on accent #6366F1 is 4.47, as the fix commit measured',
      contrastRatio(Argb.parse('#FFFFFF'), Argb.parse('#6366F1')), 4.47, 0.01);
  checkClose('light textPrimary on #191C2F is 1.06, the Daily Drop defect',
      contrastRatio(Argb.parse('#0F172A'), Argb.parse('#191C2F')), 1.06, 0.01);

  // Alpha compositing, which is what the matrix relies on for the border
  // tokens and what the tinted-surface reasoning needs.
  final half = compositeOver(Argb.parse('#80FFFFFF'), Argb.parse('#000000'));
  check('a 50% white over black composites to mid grey', half.r == 128,
      'got ${half.r}');
  final opaque = compositeOver(Argb.parse('#123456'), Argb.parse('#FFFFFF'));
  check('an opaque foreground is unchanged by compositing',
      opaque.hex == '0xFF123456');
  // 50% white composites to #808080 over black, which is 5.32:1 — not the
  // 21:1 an opaque white would give. Measuring the un-composited value is the
  // mistake this check exists to catch.
  checkClose(
      'a translucent foreground is measured against its surface',
      contrastRatio(Argb.parse('#80FFFFFF'), Argb.parse('#000000')),
      5.32,
      0.05);

  check('Argb.parse accepts the 0xAARRGGBB form the source uses',
      Argb.parse('0xFF2A2356').r == 0x2A);
  check('Argb.parse accepts #RRGGBB', Argb.parse('#2A2356').r == 0x2A);
  check('Argb.parse accepts a bare AARRGGBB', Argb.parse('2A2356FF').b == 0xFF);
}

/// The palette parse is what makes the matrix trustworthy: if it silently
/// returned a subset, every "passing" cell would be a cell that was never
/// checked.
void _testPaletteParse(String dir) {
  stdout.writeln('palette parse');
  final themePath = _themePath();
  if (themePath == null) {
    check('theme.dart was found', false, 'not found next to $dir');
    return;
  }

  final palette = parsePalette(File(themePath).readAsStringSync());
  check('both themes parse', palette.tokens.length > 20,
      'got ${palette.tokens.length} tokens');
  check(
      'every token has a dark and a light value',
      palette.tokens.values
          .every((t) => t.dark.value != 0 || t.light.value != 0));

  final surface = palette['surface'];
  check('dark surface is #151B26', surface?.dark.css == '#151B26',
      'got ${surface?.dark.css}');
  check('light surface is #FFFFFF', surface?.light.css == '#FFFFFF',
      'got ${surface?.light.css}');

  final textPrimary = palette['textPrimary'];
  check('dark textPrimary is #F8FAFC', textPrimary?.dark.css == '#F8FAFC');
  check('light textPrimary is #0F172A', textPrimary?.light.css == '#0F172A');

  final accent = palette['accent'];
  check('accent is theme-invariant, as the product intends',
      accent?.isThemeInvariant == true);

  final border = palette['border'];
  check('the dark border token carries alpha',
      border != null && !border.dark.isOpaque);
}

String? _themePath() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = File('${dir.path}/lib/theme.dart');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

/// The baseline is hand-edited JSON, so a typo in it must fail loudly rather
/// than silently parsing as "no exceptions recorded" -- which would turn every
/// annotated literal back into a fatal finding and read as a code regression.
void _testBaselineRoundTrip() {
  stdout.writeln('baseline parsing');
  final empty = Baseline.parse('{"literals": [], "pairings": []}');
  check('an empty baseline has no entries',
      empty.literals.isEmpty && empty.pairings.isEmpty);
  check('an unrecorded pairing is not in it',
      !empty.hasPairing('light', 'textFaint', 'bg'));

  // Pairings are stored in groups, so the fixture uses that shape: one reason
  // covering several cells.
  const sample = '{"literals": [{"path": "lib/x.dart", "line": 12, '
      '"role": "surface", "reason": "brand mark"}], '
      '"pairings": [{"pairings": ["light/amber/bg", "light/amber/surface"], '
      '"worst": "light/amber/bg at 2.05:1", "reason": "fill token"}]}';
  final one = Baseline.parse(sample);
  check('a literal entry round-trips',
      one.hasLiteral('lib/x.dart', 12, ColorRole.surface));
  check(
      'its reason comes back',
      one.reasonForLiteral('lib/x.dart', 12, ColorRole.surface) ==
          'brand mark');
  check(
      'every cell in a pairing group round-trips',
      one.hasPairing('light', 'amber', 'bg') &&
          one.hasPairing('light', 'amber', 'surface'));
  check('a cell outside the group does not',
      !one.hasPairing('light', 'amber', 'surfaceLight'));
  check('a group reason comes back for any of its cells',
      one.reasonForPairingKey('light/amber/surface') == 'fill token');
  check('a wrong line does not match',
      !one.hasLiteral('lib/x.dart', 13, ColorRole.surface));
  check('a wrong role does not match',
      !one.hasLiteral('lib/x.dart', 12, ColorRole.text));
  check('a matched entry is not stale',
      one.staleAgainst(const {'lib/x.dart:12:surface'}).isEmpty);
  check('an entry whose code moved is reported stale',
      one.staleAgainst(const {}).length == 1);

  var threw = false;
  try {
    const malformed = 'not json at all';
    Baseline.parse(malformed);
  } on FormatException {
    threw = true;
  }
  check('malformed JSON throws rather than parsing as empty', threw);
}

/// `--json` is a gate-facing output, so it has to actually be JSON. It was not:
/// the palette renderer opened `{"dark": ..., "light": ...` and never closed
/// it, which is a syntax error, and nothing caught it because nothing parsed
/// the output.
void _testReportIsValidJson() {
  stdout.writeln('--json output');
  final out = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/a11y/lint.dart', '--json'],
    workingDirectory: Directory.current.path,
  );
  final text = out.stdout as String;
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  check('--json emits a document', start >= 0 && end > start);

  Object? decoded;
  var threw = false;
  try {
    decoded = jsonDecode(text.substring(start, end + 1));
  } on FormatException {
    threw = true;
  }
  check('--json parses as JSON', !threw && decoded is Map);

  if (decoded is Map) {
    final palette = decoded['palette'];
    check('it carries the palette', palette is Map && palette.isNotEmpty);
    if (palette is Map) {
      check('every palette entry is a complete object',
          palette.values.every((v) => v is Map && v.length == 2));
    }
    check(
        'it carries the verdict inputs',
        decoded.containsKey('fatal') &&
            decoded.containsKey('pairings_below_aa'));
  }
}

/// The tool is only useful if the app it guards is clean, so that is asserted
/// rather than assumed. This is the check that goes red when a new theme-blind
/// surface literal is introduced.
void _testTheLiveAppIsClean() {
  stdout.writeln('the live app');
  final out = Process.runSync(
    Platform.resolvedExecutable,
    ['run', 'tool/a11y/lint.dart', '--no-matrix', '--quiet'],
    workingDirectory: Directory.current.path,
  );
  check('lint.dart exits zero on the current tree', out.exitCode == 0,
      'exit ${out.exitCode}\n${out.stdout}');
}
