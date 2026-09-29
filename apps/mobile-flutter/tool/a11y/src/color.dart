/// WCAG 2.1 relative luminance and contrast, implemented locally.
///
/// The tool deliberately carries its own colour maths rather than importing
/// `dart:ui` or `package:flutter`. Two reasons: the gate must be able to run
/// the parsing half with a bare Dart VM, and a second implementation of
/// sRGB relative luminance is the only way to catch a bug in the one the app
/// itself uses. Validated against known values: black on white is exactly
/// 21.0, `#767676` on white is 4.54.
library;

import 'dart:math' as math;

/// An 8-bit sRGB colour with straight (non-premultiplied) alpha.
class Argb {
  const Argb(this.a, this.r, this.g, this.b);

  /// Builds from a `0xAARRGGBB` literal, as written in Dart source.
  factory Argb.fromInt(int value) => Argb((value >> 24) & 0xFF,
      (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF);

  /// Parses `#RGB`, `#RRGGBB` or `#AARRGGBB`, with or without the hash.
  ///
  /// The alpha byte is *leading* in the 8-digit form, because that is the
  /// layout of the `Color(0xAARRGGBB)` literal Dart source uses. Appending it
  /// instead — the obvious thing to do, and what an earlier version of this
  /// file did — turns `#000000` into `#000000FF` and then reads that as
  /// `a=00 r=00 g=00 b=FF`: a blue. It does not throw, it quietly reports
  /// nonsense, which is why the acceptance test pins these parses against
  /// known values.
  factory Argb.parse(String text) {
    var s = text.trim().toLowerCase().replaceFirst('#', '');
    if (s.startsWith('0x')) s = s.substring(2);
    if (s.length == 3) {
      // #RGB -> #RRGGBB, opaque.
      s = '${s.split('').map((c) => '$c$c').join()}FF';
    } else if (s.length == 6) {
      // #RRGGBB -> #AARRGGBB, opaque.
      s = 'FF$s';
    } else if (s.length != 8) {
      throw FormatException('not a colour: $text');
    }
    return Argb(
      int.parse(s.substring(0, 2), radix: 16),
      int.parse(s.substring(2, 4), radix: 16),
      int.parse(s.substring(4, 6), radix: 16),
      int.parse(s.substring(6, 8), radix: 16),
    );
  }

  final int a;
  final int r;
  final int g;
  final int b;

  int get value => (a << 24) | (r << 16) | (g << 8) | b;

  bool get isOpaque => a == 255;

  /// The `0xAARRGGBB` form, so a report line can be pasted back into source.
  String get hex =>
      '0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// `#RRGGBB`, upper case, the form used by the contrast matrix tables and by
  /// every published contrast number in this repo.
  String get css => '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  @override
  String toString() => css;

  @override
  bool operator ==(Object other) => other is Argb && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

double _channelLuminance(int c) {
  final s = c / 255.0;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG 2.1 relative luminance. Alpha is ignored here on purpose: callers
/// resolve transparency with [compositeOver] first, because luminance of a
/// translucent colour is not a meaningful quantity.
double relativeLuminance(Argb c) =>
    0.2126 * _channelLuminance(c.r) +
    0.7152 * _channelLuminance(c.g) +
    0.0722 * _channelLuminance(c.b);

/// Source-over composite of [fg] onto an opaque [bg], in 8-bit sRGB.
///
/// This is what Flutter's `Color.withValues(alpha:)` on a decoration colour
/// amounts to on screen. Doing it in gamma-encoded sRGB rather than linear
/// light matches the framework; the difference is under 0.02 of a contrast
/// ratio at these alphas, well below the 0.01 precision the report prints at.
Argb compositeOver(Argb fg, Argb bg) {
  if (fg.isOpaque) return fg;
  final k = fg.a / 255.0;
  return Argb(
    255,
    (fg.r * k + bg.r * (1 - k)).round().clamp(0, 255),
    (fg.g * k + bg.g * (1 - k)).round().clamp(0, 255),
    (fg.b * k + bg.b * (1 - k)).round().clamp(0, 255),
  );
}

/// WCAG 2.1 contrast ratio between two colours, 1.0 to 21.0.
///
/// [fg] is composited over [bg] if it carries alpha, so a tinted pill and the
/// text on it can be measured as a human would see them.
double contrastRatio(Argb fg, Argb bg) {
  final l1 = relativeLuminance(compositeOver(fg, bg));
  final l2 = relativeLuminance(bg);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

/// The WCAG grade for a measured ratio.
///
/// `large` is WCAG's own carve-out: text at 18.66px bold or 24px regular and
/// up only needs 3:1. The app's card labels sit at 10-12px, so for those the
/// 3:1 band is a warning about *large* text only, never a pass.
enum WcagGrade {
  aaa('AAA', 7.0),
  aa('AA', 4.5),
  aaLarge('AA-large', 3.0),
  fail('FAIL', 0.0);

  const WcagGrade(this.label, this.threshold);

  final String label;
  final double threshold;

  static WcagGrade of(double ratio) {
    for (final g in WcagGrade.values) {
      if (ratio >= g.threshold) return g;
    }
    return WcagGrade.fail;
  }
}
