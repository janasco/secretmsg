/// Reads the two palettes out of `lib/theme.dart`.
///
/// The alternative — importing the package and asking Dart — would need the
/// Flutter toolchain and a build step, which is exactly what the gate must
/// not pay for. `AppPalette.dark` and `AppPalette.light` are `const`
/// constructor invocations of literals, so a targeted read is both faster and
/// sufficient: the numbers come from the source of truth, and if someone
/// changes a palette value the matrix moves with it on the next run.
library;

import 'color.dart';

/// One named colour slot, in both themes.
class PaletteToken {
  const PaletteToken(this.name, this.dark, this.light);

  final String name;
  final Argb dark;
  final Argb light;

  /// True when the token cannot respond to a theme change. A gradient built
  /// from these is a surface that renders identically in both themes, which
  /// is the defect class this tool exists to catch.
  bool get isThemeInvariant => dark == light;

  Argb inTheme(String theme) => theme == 'dark' ? dark : light;
}

class Palette {
  const Palette(this.tokens);

  final Map<String, PaletteToken> tokens;

  PaletteToken? operator [](String name) => tokens[name];
}

/// Text-bearing tokens: anything plausibly used as a glyph colour.
const Set<String> kTextTokens = {
  'textPrimary',
  'textHigh',
  'textSecondary',
  'textMuted',
  'textFaint',
  'accent',
  'accentDark',
  'accentSoft',
  'accentFaint',
  'amber',
  'amberLight',
  'emerald',
  'emeraldSoft',
  'emeraldLight',
  'rose',
  'roseLight',
  'roseDeep',
};

/// Surface tokens: anything plausibly used as a background behind text.
const Set<String> kSurfaceTokens = {
  'bg',
  'bgSoft',
  'surface',
  'surfaceLight',
  'accentDeep',
  'roseDeep',
};

/// Parses both `AppPalette` const instances from `theme.dart`.
///
/// Throws [FormatException] rather than returning a partial palette: a
/// half-parsed palette would produce a matrix full of confident nonsense,
/// which is the failure mode that makes a tool like this untrustworthy.
Palette parsePalette(String themeSource) {
  final assembled = <String, PaletteToken>{};
  for (final theme in const ['dark', 'light']) {
    final values = _parseConstAppPalette(themeSource, theme);
    for (final entry in values.entries) {
      final prev = assembled[entry.key];
      assembled[entry.key] = prev == null
          ? PaletteToken(entry.key, entry.value, entry.value)
          : (theme == 'dark'
              ? PaletteToken(entry.key, entry.value, prev.light)
              : PaletteToken(entry.key, prev.dark, entry.value));
    }
  }

  // AppPalette's constructor marks every field required, so a token present in
  // one theme and missing from the other means the parse went wrong. The same
  // value in both themes is legal and deliberate (accent, amber, emerald, rose
  // and roseDeep are theme-invariant by product decision), so that is not an
  // error and is not checked here.
  final darkNames = _parseConstAppPalette(themeSource, 'dark').keys.toSet();
  final lightNames = _parseConstAppPalette(themeSource, 'light').keys.toSet();
  final onlyDark = darkNames.difference(lightNames);
  final onlyLight = lightNames.difference(darkNames);
  if (onlyDark.isNotEmpty || onlyLight.isNotEmpty) {
    throw FormatException(
      'palette token sets disagree between themes; '
      'only in dark: ${(onlyDark.toList()..sort()).join(', ')}; only in light: ${(onlyLight.toList()..sort()).join(', ')}',
    );
  }

  return Palette(Map.unmodifiable(assembled));
}

/// Extracts `name: Color(0x...)` pairs from `static const <theme> = AppPalette(`.
Map<String, Argb> _parseConstAppPalette(String source, String theme) {
  final startMarker =
      RegExp(r'static\s+const\s+' + theme + r'\s*=\s*AppPalette\s*\(');
  final match = startMarker.firstMatch(source);
  if (match == null) {
    throw FormatException(
        'could not find `static const $theme = AppPalette(` in theme.dart');
  }

  final open = source.indexOf('(', match.start);
  final close = _matchingParen(source, open);
  final body = source.substring(open + 1, close);

  final values = <String, Argb>{};
  final field = RegExp(r'(\w+)\s*:\s*Color\(\s*(0[xX][0-9a-fA-F]{8})\s*\)');

  for (final m in field.allMatches(body)) {
    // `int.parse` with an explicit radix rejects a `0x` prefix, and the
    // Dart `Color(0xAARRGGBB)` literal is written with one.
    final digits = m.group(2)!.replaceFirst(RegExp('^0[xX]'), '');
    values[m.group(1)!] = Argb.fromInt(int.parse(digits, radix: 16));
  }

  if (values.isEmpty) {
    throw FormatException('parsed no colors out of AppPalette.$theme');
  }
  return values;
}

int _matchingParen(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final c = source[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw FormatException('unbalanced parentheses from offset $open');
}
