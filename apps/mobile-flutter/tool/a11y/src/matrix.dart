/// The contrast matrix: every text-bearing token against every surface token,
/// in both themes.
///
/// This is a *possible pairings* matrix, not a map of what the app actually
/// does. It answers "if these two tokens ever meet, can a human read it",
/// which is the question that catches a token combination before a screen
/// wires it up. Screens that never pair `textMuted` with `roseDeep` cost
/// nothing here and would cost a lot at 2.11:1 if they did.
library;

import 'color.dart';
import 'palette.dart';

/// One cell of the matrix.
class MatrixCell {
  const MatrixCell({
    required this.theme,
    required this.text,
    required this.surface,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.grade,
  });

  final String theme;
  final String text;
  final String surface;

  /// [foreground] after compositing any alpha over the surface.
  final Argb foreground;
  final Argb background;
  final double ratio;
  final WcagGrade grade;

  String get key => '$theme/$text/$surface';

  bool get passesAA => ratio >= 4.5;
  bool get passesLargeText => ratio >= 3.0;
}

class ContrastMatrix {
  const ContrastMatrix(this.cells);

  final List<MatrixCell> cells;

  Iterable<MatrixCell> failingAA() =>
      cells.where((c) => !c.passesAA && c.passesLargeText);

  Iterable<MatrixCell> failingLargeText() =>
      cells.where((c) => !c.passesLargeText);

  List<MatrixCell> forTheme(String theme) =>
      cells.where((c) => c.theme == theme).toList();

  /// Renders one theme as a fixed-width table.
  ///
  /// Columns are surfaces, rows are text tokens. A cell is marked so the table
  /// is readable without the legend: `ok` for AA, `~` for the 3:1
  /// large-text-only band, and `X` for below 3:1.
  String render(
      String theme, List<String> textTokens, List<String> surfaceTokens) {
    final buf = StringBuffer();
    final labelWidth =
        textTokens.fold<int>(12, (w, t) => t.length > w ? t.length : w);

    buf.writeln('  $theme theme');
    buf.writeln(
        '  ${' ' * labelWidth} ${surfaceTokens.map((s) => s.centerPad(9)).join(' ')}');
    buf.writeln(
        '  ${'-' * labelWidth} ${surfaceTokens.map((_) => '-' * 9).join(' ')}');

    for (final t in textTokens) {
      final row = StringBuffer('  ${t.padRight(labelWidth)} ');
      for (final s in surfaceTokens) {
        final cell = cells
            .where((c) => c.theme == theme && c.text == t && c.surface == s);
        if (cell.isEmpty) {
          row.write(' '.centerPad(9));
          continue;
        }
        final c = cell.first;
        final mark = c.passesAA ? '  ' : (c.passesLargeText ? ' ~' : ' X');
        row.write('${c.ratio.toStringAsFixed(2).padLeft(5)}$mark'.centerPad(9));
      }
      buf.writeln(row.toString());
    }
    return buf.toString();
  }
}

/// Builds the full text x surface matrix for both themes.
ContrastMatrix buildMatrix(Palette palette) {
  final cells = <MatrixCell>[];

  for (final theme in const ['dark', 'light']) {
    for (final textName in kTextTokens) {
      final textToken = palette[textName];
      if (textToken == null) continue;
      final fg = textToken.inTheme(theme);

      for (final surfaceName in kSurfaceTokens) {
        final surfaceToken = palette[surfaceName];
        if (surfaceToken == null) continue;
        final bg = surfaceToken.inTheme(theme);

        final resolved = compositeOver(fg, bg);
        final ratio = contrastRatio(fg, bg);
        cells.add(MatrixCell(
          theme: theme,
          text: textName,
          surface: surfaceName,
          foreground: resolved,
          background: bg,
          ratio: ratio,
          grade: WcagGrade.of(ratio),
        ));
      }
    }
  }

  return ContrastMatrix(cells);
}

extension on String {
  String centerPad(int width) {
    if (length >= width) return substring(0, width);
    final left = (width - length) ~/ 2;
    return ' ' * left + this + ' ' * (width - length - left);
  }
}
