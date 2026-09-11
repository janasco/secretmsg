import 'package:flutter/material.dart';

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
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
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
              color: AppColors.accent.withOpacity(0.25),
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
}
