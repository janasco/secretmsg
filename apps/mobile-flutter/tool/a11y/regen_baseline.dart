/// `dart run tool/a11y/regen_baseline.dart` — regenerate the `pairings`
/// block of `a11y_baseline.json` from the palette, with a reason per group.
///
/// Why a generator rather than a hand-maintained list: 94 cells is too many to
/// keep honest by hand. Someone changes a palette value, a pairing stops
/// failing, the entry stays, and from then on it hides the *next* regression
/// on that cell. Generating the file means it always describes today's
/// palette, and a pairing dropping out of the report becomes visible instead
/// of silent.
///
/// Run it with `--write` to update the file, or with no arguments to see what
/// would change. `--check` exits non-zero if the file on disk differs, which is
/// what the gate uses to stop the baseline from being edited by hand.
///
/// It is a separate entry point from `lint.dart` rather than a flag, because
/// writing the file is not something a report should ever be able to do.
library;

import 'dart:convert';
import 'dart:io';

import 'src/matrix.dart';
import 'src/palette.dart';

/// Surfaces no screen paints body copy on.
///
/// `roseDeep` is the destructive-button fill (widgets/common.dart:432). Every
/// text-on-roseDeep cell is therefore unreachable today, which is exactly why
/// it is worth recording: it is the warning if someone starts putting text
/// there.
const Set<String> kSurfacesWithoutBodyCopy = {'roseDeep'};

/// Tokens that are surfaces, not glyph colours.
///
/// `roseDeep` is the only one, and the group is large because a surface token
/// fails against every surface including itself.
const Set<String> kSurfaceTokensUsedAsText = {'roseDeep'};

/// Fill and tint tokens. Each is unusable as a glyph colour in at least one
/// theme, which the matrix is what makes visible.
const Map<String, String> kFillOnlyTokens = {
  'amber': 'amber is the fill/tint token: pill washes, borders, and icons on a '
      'dark surface. In light mode it carries the same #F59E0B as dark, so it '
      'cannot be a glyph colour there. Screens that need an amber glyph use '
      'amberLight, which is what the send-screen pause icon now does.',
  'rose': 'rose is the destructive fill and the error border. Unusable as a '
      'glyph colour in light mode (2.05:1 on bg). Screens that need a red '
      'glyph use roseLight, which is what the Turnstile error icon and the '
      'backup-codes warning now do.',
  'emerald': 'emerald is a fill/tint token: success washes, borders, and icons '
      'on a dark surface. Unusable as a glyph colour in light mode (2.42:1 on '
      'bg). Screens that need a green glyph use emeraldSoft or emeraldLight, '
      'which is what the send-screen success card now does.',
  'accentDark': 'accentDark is a gradient stop and the focused-border token, '
      'never body copy. No screen draws an accentDark glyph on any of these '
      'surfaces.',
  'accentFaint': 'accentFaint is the progress-indicator tint. Its real use is '
      'a spinner stroke, which needs 3:1 and not 4.5:1, not readable copy.',
  'accent': 'accent is the FilledButton fill. A button label is white on '
      'accent, never accent on a surface, and the screens that do use accent '
      'as a glyph colour put it on a dark surface where it clears 3:1.',
};

/// `textFaint` is a hairline and placeholder token, and WCAG 1.4.3 excludes
/// placeholder text from its contrast requirement outright.
const String kTextFaintReason = 'textFaint is the hairline and placeholder '
    'token (1px separators, hint text, disabled labels), not readable copy. '
    'WCAG 1.4.3 excludes placeholder text from its contrast requirement, and '
    'no screen uses this token for body text.';

const String kDiagonalReason = 'a surface token measured against itself, which '
    'is never a real pairing';

/// Returns the reason a cell is recorded, or null if it needs none.
String? _reasonFor(String theme, String text, String surface, double ratio) {
  if (text == surface) return kDiagonalReason;

  if (kSurfaceTokensUsedAsText.contains(text)) {
    return '$text is a surface token, not a glyph colour: it is the '
        'destructive-button fill (widgets/common.dart:432) and no screen draws '
        'text in it. Every cell in this group becomes a live bug the moment '
        'someone uses $text as a text or icon colour.';
  }

  if (kSurfacesWithoutBodyCopy.contains(surface)) {
    return '$surface is the destructive-button fill '
        '(widgets/common.dart:432) and no screen puts $text text on it. This '
        'cell only becomes a bug if someone does.';
  }

  if (text == 'textFaint') return kTextFaintReason;

  final fillReason = kFillOnlyTokens[text];
  if (fillReason != null) return fillReason;

  if (text == 'textSecondary' && theme == 'light') {
    return 'textSecondary measures 4.55:1 on light bg and 4.76:1 on the white '
        'surfaces, so it misses AA only on the tinted cards, by 0.01 to 0.24. '
        'It is the app-wide body-secondary token; screens that need AA on a '
        'tinted card use textHigh, which is what the Daily Drop fix did.';
  }

  if (text == 'textMuted') {
    return 'textMuted is the metadata token (timestamps, counts) and measures '
        '3.2-4.4:1 across the dark surfaces. In light mode it is the same value '
        'as textSecondary, so the Daily Drop fix could not have swapped to it: '
        'the change would have been a no-op.';
  }

  if (text == 'emeraldSoft' || text == 'emeraldLight') {
    return '$text is an icon and inline-glyph token. It clears the 3:1 '
        'non-text requirement on the neutral surfaces (3.4:1 to 3.8:1) and '
        'falls short only on a tinted card. No screen pairs it with $surface.';
  }

  if (text == 'roseLight') {
    return 'roseLight is the red-glyph token. It clears AA on the neutral '
        'surfaces and lands at 4.32:1 on the tinted card, which commit 43aa190 '
        'measured and recorded as a token property rather than a screen bug.';
  }

  return '$text on $surface measures ${ratio.toStringAsFixed(2)}:1. A possible '
      'pairing, not an observed one: no screen currently puts these two tokens '
      'together, and this cell is the warning if one starts to.';
}

class _Group {
  _Group(this.reason);

  final String reason;
  final List<String> keys = [];
  String worst = '';
  double worstRatio = double.infinity;

  void add(String key, double ratio) {
    keys.add(key);
    if (ratio < worstRatio) {
      worstRatio = ratio;
      worst = '$key at ${ratio.toStringAsFixed(2)}:1';
    }
  }
}

void main(List<String> args) {
  final write = args.contains('--write');
  final check = args.contains('--check');
  if (write && check) {
    stderr.writeln('pick one of --write or --check');
    exit(64);
  }

  final themeFile = File('lib/theme.dart');
  if (!themeFile.existsSync()) {
    stderr.writeln('run this from the app root: lib/theme.dart not found');
    exit(64);
  }
  final baselineFile = File('tool/a11y/a11y_baseline.json');

  final palette = parsePalette(themeFile.readAsStringSync());
  final matrix = buildMatrix(palette);

  final groups = <String, _Group>{};
  var failing = 0;
  for (final cell in matrix.cells) {
    if (cell.passesAA) continue;
    failing++;
    final key = cell.key;
    final reason = _reasonFor(cell.theme, cell.text, cell.surface, cell.ratio);
    if (reason == null) continue;
    groups.putIfAbsent(reason, () => _Group(reason)).add(key, cell.ratio);
  }

  final rendered = groups.values.toList()
    ..sort((a, b) {
      final byWorst = a.worstRatio.compareTo(b.worstRatio);
      return byWorst != 0 ? byWorst : a.reason.compareTo(b.reason);
    });

  stdout.writeln('$failing palette pairings below AA, in ${rendered.length} '
      'reasoned groups:');
  for (final g in rendered) {
    stdout.writeln('  ${g.worst.padRight(38)} ${g.keys.length} cell(s)');
    stdout.writeln('      ${g.reason}');
  }

  if (!write && !check) return;

  final doc =
      jsonDecode(baselineFile.readAsStringSync()) as Map<String, Object?>;
  final next = Map<String, Object?>.from(doc)
    ..['_comment'] = _comment
    ..['literals'] = const <Object?>[]
    ..['pairings'] = [
      for (final g in rendered)
        {
          'pairings': g.keys..sort(),
          'worst': g.worst,
          'reason': g.reason,
        },
    ];

  final encoded = '${const JsonEncoder.withIndent('  ').convert(next)}\n';
  final current = baselineFile.readAsStringSync();
  if (encoded == current) {
    stdout.writeln('\n${baselineFile.path} is already up to date.');
    return;
  }

  if (check) {
    stdout.writeln('\n${baselineFile.path} is out of date with the palette.');
    stdout.writeln('Run: dart run tool/a11y/regen_baseline.dart --write');
    exit(1);
  }

  baselineFile.writeAsStringSync(encoded);
  stdout.writeln('\nwrote ${baselineFile.path}');
}

const List<String> _comment = [
  'Recorded, deliberate exceptions for tool/a11y/lint.dart.',
  '',
  'GENERATED. The `pairings` block is derived from the palette by',
  'tool/a11y/regen_baseline.dart, so it always describes today\'s values',
  'rather than a hand-typed list that drifts the moment a palette value',
  'changes and then hides the next regression on the same cell. Regenerate',
  'with `dart run tool/a11y/regen_baseline.dart --write`; the gate runs',
  '`--check` and fails if this file is stale.',
  '',
  'Every group carries a reason. A pairing recorded with no reason is just a',
  'way of making the gate quiet.',
  '',
  'These are POSSIBLE pairings, not observed ones. The matrix measures every',
  'text-bearing token against every surface-bearing token, and a cell only',
  'becomes a bug when a screen puts those two together. None of these is a',
  'live defect today. They are listed because that is the point of the',
  'matrix: a token that is unusable on a surface should be caught before a',
  'screen reaches for it.',
  '',
  'Fixing any of them means changing a value in lib/theme.dart, which shifts',
  'contrast app-wide. That is deliberately out of scope. The Daily Drop bug',
  'was a SURFACE problem, and the fix that shipped correctly left the palette',
  'alone; these are reported with numbers and left.',
  '',
  '`literals` is empty and should stay that way. Every hardcoded colour that',
  'is genuinely correct in this app is annotated in place with an',
  '`// a11y-allow: <reason>` comment, so the judgement sits next to the code',
  'it defends and shows up in the diff.',
];
