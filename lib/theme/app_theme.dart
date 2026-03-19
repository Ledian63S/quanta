import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg          = Color(0xFFF4F6FB);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE2E8F2);
  static const text        = Color(0xFF0A1020);
  static const muted       = Color(0xFF8A9CBA);
  static const accent      = Color(0xFF00C2E0);
  static const accentBlue  = Color(0xFF2563EB);
  static const navyDark    = Color(0xFF06101E);
  static const navyMid     = Color(0xFF0C1E3A);
  static const navyCard1   = Color(0xFF060E1E);
  static const navyCard2   = Color(0xFF0B1E3C);
  static const green       = Color(0xFF00D48A);
  static const orange      = Color(0xFFF59E0B);
  static const pill        = Color(0xFF0A1428);

  // Dark mode
  static const darkBg      = Color(0xFF0E1018);
  static const darkCard    = Color(0xFF131A2E);
  static const darkBorder  = Color(0xFF1E2A40);
  static const darkText    = Color(0xFFE8F0FF);
  static const darkMuted   = Color(0xFF4A5580);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentBlue,
        secondary: AppColors.accent,
        surface: AppColors.card,
      ),
      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        filled: false,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accent,
        surface: AppColors.darkCard,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        filled: false,
      ),
    );
  }
}

// Shared text styles
class AppText {
  static TextStyle mono({double size = 16, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label({double size = 11, Color? color}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w700,
      letterSpacing: 1.1, color: color);

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
}

// Shared decorations
class AppDecor {
  static BoxDecoration navyGradientCard({double radius = 20}) => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [AppColors.navyCard1, AppColors.navyCard2],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
  );

  static BoxDecoration whiteCard({double radius = 20}) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: 1.5),
  );

  static BoxDecoration activeInstrument() => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [AppColors.navyCard1, AppColors.navyCard2],
    ),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
  );

  static BoxDecoration inactiveInstrument() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border, width: 1.5),
  );
}
