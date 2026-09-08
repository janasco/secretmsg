import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Titanium Noir & Crisp White Theme Tokens
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF151B26);
  static const Color surfaceDim = Color(0xFF10131A);
  static const Color surfaceHigh = Color(0xFF1D2433);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color outline = Color(0x1FFFFFFF);
  static const Color outlineStrong = Color(0x3DFFFFFF);

  // Vibe Accents
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color wholesomeRose = Color(0xFFF43F5E);
  static const Color amberGold = Color(0xFFFBBF24);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color indigoSoft = Color(0xFF818CF8);

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryWhite,
      canvasColor: background,
      cardColor: surface,
      dividerColor: outline,
      colorScheme: const ColorScheme.dark(
        primary: primaryWhite,
        onPrimary: background,
        surface: surface,
        onSurface: primaryWhite,
        outline: outline,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: primaryWhite,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: primaryWhite,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: primaryWhite,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryWhite),
      ),
    );
  }
}
