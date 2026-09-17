import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme-aware palette: the same semantic tokens in obsidian (dark) and
/// paper (light). UI code must read colors via `context.colors` — never the
/// static [AppColors] (dark-only legacy, kept for theme construction).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color bgSoft;
  final Color surface;
  final Color surfaceLight;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color accentFaint;
  final Color amber;
  final Color amberLight;
  final Color emerald;
  final Color rose;
  final Color textPrimary;
  final Color textHigh;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color accentDeep;
  final Color emeraldSoft;
  final Color emeraldLight;
  final Color roseLight;
  final Color roseDeep;
  final Color border;
  final Color borderStrong;

  const AppPalette({
    required this.bg,
    required this.bgSoft,
    required this.surface,
    required this.surfaceLight,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.accentFaint,
    required this.amber,
    required this.amberLight,
    required this.emerald,
    required this.rose,
    required this.textPrimary,
    required this.textHigh,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accentDeep,
    required this.emeraldSoft,
    required this.emeraldLight,
    required this.roseLight,
    required this.roseDeep,
    required this.border,
    required this.borderStrong,
  });

  static const dark = AppPalette(
    bg: Color(0xFF0B0E14),
    bgSoft: Color(0xFF0E131C),
    surface: Color(0xFF151B26),
    surfaceLight: Color(0xFF1D2433),
    accent: Color(0xFF6366F1),
    accentDark: Color(0xFF4F46E5),
    accentSoft: Color(0xFFA5B4FC),
    accentFaint: Color(0xFF818CF8),
    amber: Color(0xFFF59E0B),
    amberLight: Color(0xFFFCD34D),
    emerald: Color(0xFF10B981),
    rose: Color(0xFFF43F5E),
    textPrimary: Color(0xFFF8FAFC),
    textHigh: Color(0xFFCBD5E1),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF475569),
    accentDeep: Color(0xFF1E1B4B),
    emeraldSoft: Color(0xFF34D399),
    emeraldLight: Color(0xFF6EE7B7),
    roseLight: Color(0xFFF87171),
    roseDeep: Color(0xFF7F1D1D),
    border: Color(0x1FFFFFFF),
    borderStrong: Color(0x3DFFFFFF),
  );

  static const light = AppPalette(
    bg: Color(0xFFF8FAFC),
    bgSoft: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF1F5F9),
    accent: Color(0xFF6366F1),
    accentDark: Color(0xFF4F46E5),
    accentSoft: Color(0xFF4338CA),
    accentFaint: Color(0xFF6366F1),
    amber: Color(0xFFF59E0B),
    amberLight: Color(0xFFB45309),
    emerald: Color(0xFF10B981),
    rose: Color(0xFFF43F5E),
    textPrimary: Color(0xFF0F172A),
    textHigh: Color(0xFF334155),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFFCBD5E1),
    accentDeep: Color(0xFFEEF2FF),
    emeraldSoft: Color(0xFF059669),
    emeraldLight: Color(0xFF047857),
    roseLight: Color(0xFFDC2626),
    roseDeep: Color(0xFF7F1D1D),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
  );

  @override
  AppPalette copyWith({
    Color? bg, Color? bgSoft, Color? surface, Color? surfaceLight,
    Color? accent, Color? accentDark, Color? accentSoft, Color? accentFaint,
    Color? amber, Color? amberLight, Color? emerald, Color? rose,
    Color? textPrimary, Color? textHigh, Color? textSecondary,
    Color? textMuted, Color? textFaint, Color? accentDeep,
    Color? emeraldSoft, Color? emeraldLight, Color? roseLight,
    Color? roseDeep, Color? border, Color? borderStrong,
  }) {
    return AppPalette(
      bg: bg ?? this.bg, bgSoft: bgSoft ?? this.bgSoft,
      surface: surface ?? this.surface, surfaceLight: surfaceLight ?? this.surfaceLight,
      accent: accent ?? this.accent, accentDark: accentDark ?? this.accentDark,
      accentSoft: accentSoft ?? this.accentSoft, accentFaint: accentFaint ?? this.accentFaint,
      amber: amber ?? this.amber, amberLight: amberLight ?? this.amberLight,
      emerald: emerald ?? this.emerald, rose: rose ?? this.rose,
      textPrimary: textPrimary ?? this.textPrimary, textHigh: textHigh ?? this.textHigh,
      textSecondary: textSecondary ?? this.textSecondary, textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint, accentDeep: accentDeep ?? this.accentDeep,
      emeraldSoft: emeraldSoft ?? this.emeraldSoft, emeraldLight: emeraldLight ?? this.emeraldLight,
      roseLight: roseLight ?? this.roseLight, roseDeep: roseDeep ?? this.roseDeep,
      border: border ?? this.border, borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bg: l(bg, other.bg), bgSoft: l(bgSoft, other.bgSoft),
      surface: l(surface, other.surface), surfaceLight: l(surfaceLight, other.surfaceLight),
      accent: l(accent, other.accent), accentDark: l(accentDark, other.accentDark),
      accentSoft: l(accentSoft, other.accentSoft), accentFaint: l(accentFaint, other.accentFaint),
      amber: l(amber, other.amber), amberLight: l(amberLight, other.amberLight),
      emerald: l(emerald, other.emerald), rose: l(rose, other.rose),
      textPrimary: l(textPrimary, other.textPrimary), textHigh: l(textHigh, other.textHigh),
      textSecondary: l(textSecondary, other.textSecondary), textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint), accentDeep: l(accentDeep, other.accentDeep),
      emeraldSoft: l(emeraldSoft, other.emeraldSoft), emeraldLight: l(emeraldLight, other.emeraldLight),
      roseLight: l(roseLight, other.roseLight), roseDeep: l(roseDeep, other.roseDeep),
      border: l(border, other.border), borderStrong: l(borderStrong, other.borderStrong),
    );
  }
}

/// `context.colors` — the theme-aware palette. Rebuilds automatically on
/// brightness or theme-mode change.
extension PaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

/// Theme-aware type scale: same metrics as [AppType], colors from the
/// active palette. Prefer `context.type.*` over [AppType] in UI code.
class AppTypeSet {
  final AppPalette c;
  const AppTypeSet(this.c);

  TextStyle get displayLg => TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 28, color: c.textPrimary);
  TextStyle get headlineMd => TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600, letterSpacing: -0.01 * 20, color: c.textPrimary);
  TextStyle get titleSm => TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, color: c.textPrimary);
  TextStyle get bodyBase => TextStyle(fontSize: 14, height: 20 / 14, color: c.textPrimary);
  TextStyle get bodySm => TextStyle(fontSize: 12, height: 18 / 12, color: c.textSecondary);
  TextStyle get caption => TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500, letterSpacing: 0.02 * 11, color: c.textSecondary);
  TextStyle get labelCaps => TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w600, letterSpacing: 0.06 * 11, color: c.textSecondary);
}

extension TypeContext on BuildContext {
  AppTypeSet get type => AppTypeSet(colors);
}

const String _kThemeModeKey = 'theme_mode';

/// System / light / dark override, persisted. Defaults to system (auto).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._(super.value);

  static final ThemeController instance = ThemeController._(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kThemeModeKey);
      instance.value = switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kThemeModeKey,
        switch (mode) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', ThemeMode.system => 'system' },
      );
    } catch (_) {}
  }
}

class AppColors {
  // Backdrop — deep obsidian-titanium (Stitch DESIGN.md)
  static const bg = Color(0xFF0B0E14);
  static const bgSoft = Color(0xFF0E131C);
  static const surface = Color(0xFF151B26);
  static const surfaceLight = Color(0xFF1D2433);

  // Brand — the app's violet system (kept per product decision).
  static const accent = Color(0xFF6366F1);
  static const accentDark = Color(0xFF4F46E5);
  static const accentSoft = Color(0xFFA5B4FC);
  static const accentFaint = Color(0xFF818CF8);

  // Semantic accents (Stitch vibe highlights, harmonised with the brand).
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFCD34D);
  static const emerald = Color(0xFF10B981);
  static const rose = Color(0xFFF43F5E);

  // Text
  static const textPrimary = Color(0xFFF8FAFC);
  static const textHigh = Color(0xFFCBD5E1);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const textFaint = Color(0xFF475569);

  // Accent tints for tinted chips and containers.
  static const accentDeep = Color(0xFF1E1B4B);
  static const emeraldSoft = Color(0xFF34D399);
  static const emeraldLight = Color(0xFF6EE7B7);
  static const roseLight = Color(0xFFF87171);
  static const roseDeep = Color(0xFF7F1D1D);

  // Hairline borders (Stitch: rgba(255,255,255,0.12) / 0.24)
  static const border = Color(0x1FFFFFFF);
  static const borderStrong = Color(0x3DFFFFFF);

}

/// Stitch DESIGN.md type scale: display-lg 28/34 -2%, headline-md 20/28 -1%,
/// title-sm 16/24 600, body-base 14/20, body-sm 12/18, caption 11/16 +2%.
class AppType {
  static const displayLg = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 28,
    color: AppColors.textPrimary,
  );

  static const headlineMd = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 20,
    color: AppColors.textPrimary,
  );

  static const titleSm = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const bodyBase = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static const bodySm = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02 * 11,
    color: AppColors.textSecondary,
  );

  /// Small-caps label used by pills, badges and stat card captions.
  static const labelCaps = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.06 * 11,
    color: AppColors.textSecondary,
  );
}

class GlassPainter extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final List<BoxShadow>? shadows;

  const GlassPainter({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16),
    this.borderColor = AppColors.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: (onPressed == null || loading) ? 0.5 : 1.0,
      child: Container(
        height: height,
        constraints: fullWidth
            ? const BoxConstraints(minWidth: double.infinity)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );

    return GestureDetector(
      onTap: (onPressed == null || loading) ? null : onPressed,
      child: button,
    );
  }
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.rose,
      ),
      fontFamily: 'Inter',
      extensions: const [AppPalette.dark],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        headlineSmall: AppType.headlineMd,
        titleMedium: AppType.titleSm,
        bodyMedium: AppType.bodyBase,
        bodySmall: AppType.bodySm,
        labelSmall: AppType.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textFaint),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.rose,
      ),
      fontFamily: 'Inter',
      extensions: const [AppPalette.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 20, height: 28/20, fontWeight: FontWeight.w600, letterSpacing: -0.01*20, color: Color(0xFF0F172A)),
        titleMedium: TextStyle(fontSize: 16, height: 24/16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        bodyMedium: TextStyle(fontSize: 14, height: 20/14, color: Color(0xFF0F172A)),
        bodySmall: TextStyle(fontSize: 12, height: 18/12, color: Color(0xFF64748B)),
        labelSmall: TextStyle(fontSize: 11, height: 16/11, fontWeight: FontWeight.w500, letterSpacing: 0.02*11, color: Color(0xFF64748B)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(color: Color(0xFF0F172A)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFF1F5F9),
        labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
    );
  }
}
