import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pointer cursor + hover opacity for desktop.
class Clickable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Clickable({super.key, required this.child, this.onTap});
  @override
  State<Clickable> createState() => _ClickableState();
}
class _ClickableState extends State<Clickable> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: _hovered ? 0.70 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

class AppColors {
  // ── Surfaces ────────────────────────────────────────────────────────────
  static const bg       = Color(0xFF07080F); // deep space
  static const card     = Color(0xFF0E1020); // surface 1
  static const elevated = Color(0xFF151829); // surface 2
  static const high     = Color(0xFF1C2038); // surface 3

  // ── Text ────────────────────────────────────────────────────────────────
  static const text     = Color(0xFFFFFFFF);
  static const muted    = Color(0xFF64748B);
  static const subtle   = Color(0xFF334155);

  // ── Accent (indigo → violet gradient) ───────────────────────────────────
  static const accent      = Color(0xFF6366F1); // indigo
  static const accentLight = Color(0xFF818CF8); // lighter indigo
  static const accentBlue  = Color(0xFF6366F1); // alias

  // ── Semantic ────────────────────────────────────────────────────────────
  static const green  = Color(0xFF10B981); // emerald
  static const orange = Color(0xFFF59E0B); // amber

  // ── Structural ──────────────────────────────────────────────────────────
  static const border = Color(0x12FFFFFF); // 7% white
  static const glow   = Color(0x1A6366F1); // indigo glow

  // ── Legacy aliases (keep screens compiling) ─────────────────────────────
  static const darkBg     = bg;
  static const darkCard   = card;
  static const darkBorder = border;
  static const darkText   = text;
  static const darkMuted  = muted;
  static const navyDark   = card;
  static const navyMid    = elevated;
  static const navyCard1  = elevated;
  static const navyCard2  = high;
  static const pill       = card;
}

class AppTheme {
  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static ThemeData _build() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentLight,
      surface: AppColors.card,
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      filled: false,
    ),
  );
}

class AppText {
  static TextStyle mono({double size = 16, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label({double size = 11, Color? color}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: color ?? AppColors.muted,
    );

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
}

class AppDecor {
  // Standard glass card
  static BoxDecoration card({double radius = 16, Color? color}) => BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Glowing accent card (result, levels summary)
  static BoxDecoration glowCard({double radius = 20, Color? glowColor}) {
    final c = glowColor ?? AppColors.accent;
    return BoxDecoration(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.withValues(alpha: 0.25), width: 1),
      boxShadow: [
        BoxShadow(color: c.withValues(alpha: 0.14), blurRadius: 40, offset: const Offset(0, 8)),
        BoxShadow(color: c.withValues(alpha: 0.06), blurRadius: 80, offset: const Offset(0, 16)),
      ],
    );
  }

  // Focused stop loss card
  static BoxDecoration focusCard({double radius = 24}) => BoxDecoration(
    color: AppColors.elevated,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1),
    boxShadow: [
      BoxShadow(color: AppColors.accent.withValues(alpha: 0.16), blurRadius: 40, offset: const Offset(0, 8)),
    ],
  );

  // Legacy aliases
  static BoxDecoration navyGradientCard({double radius = 20}) => glowCard(radius: radius);
  static BoxDecoration whiteCard({double radius = 20}) => card(radius: radius);

  static BoxDecoration activeInstrument() => BoxDecoration(
    color: AppColors.accent.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.45), width: 1),
    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 12)],
  );

  static BoxDecoration inactiveInstrument() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border, width: 1),
  );
}
