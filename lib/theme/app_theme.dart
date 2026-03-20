import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Clickable ──────────────────────────────────────────────────────────────
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
          duration: const Duration(milliseconds: 100),
          opacity: _hovered ? 0.65 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Terminal number — flicker update like a real terminal ──────────────────
class TerminalNumber extends StatefulWidget {
  final int value;
  final double size;
  final Color? color;
  const TerminalNumber({super.key, required this.value,
      this.size = 80, this.color});
  @override
  State<TerminalNumber> createState() => _TerminalNumberState();
}
class _TerminalNumberState extends State<TerminalNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  int _displayed = 0;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _opacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void didUpdateWidget(TerminalNumber old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    _countTimer?.cancel();
    if (widget.value > _displayed) {
      _countUp(_displayed, widget.value);
    } else {
      _ctrl.forward().then((_) {
        if (mounted) {
          setState(() => _displayed = widget.value);
          _ctrl.reverse();
        }
      });
    }
  }

  void _countUp(int from, int to) {
    final steps = to - from;
    final stepMs = (450 / steps).clamp(40.0, 120.0).round();
    int current = from;
    _countTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      current++;
      if (mounted) setState(() => _displayed = current);
      if (current >= to) t.cancel();
    });
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.accent;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Text(
          _displayed > 0 ? '$_displayed' : '--',
          style: GoogleFonts.jetBrainsMono(
            fontSize: widget.size,
            fontWeight: FontWeight.w700,
            color: _displayed > 0 ? c : AppColors.muted,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ── Brick gauge — 2 rows × 5 cols ──────────────────────────────────────────
class PacManGauge extends StatelessWidget {
  final int contracts;
  final bool hasData;
  static const _cols = 5;
  static const _maxBricks = 10; // 2 rows × 5 cols
  const PacManGauge({super.key, required this.contracts, required this.hasData});

  @override
  Widget build(BuildContext context) {
    final filled = hasData ? contracts.clamp(0, _maxBricks) : 0;
    final overflow = hasData && contracts > _maxBricks ? contracts - _maxBricks : 0;

    // Build a row of 5 bricks; offset shifts which global index they start at
    Widget brickRow(int offset) => Row(
      children: List.generate(_cols, (col) {
        final idx = offset + col; // global brick index 0–9
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: col < _cols - 1 ? 4 : 0),
            child: _Brick(on: idx < filled, index: idx),
          ),
        );
      }),
    );

    return SizedBox(
      height: 175,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 2×5 brick grid on the left
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                brickRow(5), // top row: bricks 5–9
                const SizedBox(height: 4),
                brickRow(0), // bottom row: bricks 0–4
                if (overflow > 0) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('+$overflow',
                        style: AppText.mono(size: 9, color: AppColors.accent)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Contract count on the right
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TerminalNumber(
                  value: contracts, size: 72, color: AppColors.accent),
              const SizedBox(height: 2),
              Text('CONTRACTS',
                  style: AppText.label(size: 9, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brick extends StatelessWidget {
  final bool on;
  final int index;
  const _Brick({required this.on, required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Empty shell — always visible, sharp corners
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          // Filled brick — scales + fades in, staggered by index
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: on ? 1.0 : 0.0),
            duration: Duration(milliseconds: 90 + index * 28),
            curve: Curves.easeOut,
            builder: (_, t, __) {
              if (t < 0.01) return const SizedBox.shrink();
              return Opacity(
                opacity: t,
                child: Transform.scale(
                  scale: 0.72 + 0.28 * t,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.45 * t),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _BrickFacePainter()),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BrickFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Top highlight
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 3),
        Paint()..color = Colors.white.withValues(alpha: 0.30));
    // Left highlight
    canvas.drawRect(Rect.fromLTWH(0, 0, 3, h),
        Paint()..color = Colors.white.withValues(alpha: 0.16));
    // Bottom shadow
    canvas.drawRect(Rect.fromLTWH(0, h - 3, w, 3),
        Paint()..color = Colors.black.withValues(alpha: 0.28));
    // Right shadow
    canvas.drawRect(Rect.fromLTWH(w - 3, 0, 3, h),
        Paint()..color = Colors.black.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Dot leader ─────────────────────────────────────────────────────────────
class DotLeader extends StatelessWidget {
  const DotLeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 5.5).floor();
          return Text(
            '.' * count,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: AppText.mono(size: 11,
                color: AppColors.muted.withValues(alpha: 0.25)),
          );
        },
      ),
    );
  }
}

// ── Scanline overlay ───────────────────────────────────────────────────────
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _ScanlinePainter(), size: Size.infinite),
  );
}
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Grain overlay ──────────────────────────────────────────────────────────
class GrainOverlay extends StatelessWidget {
  final double opacity;
  const GrainOverlay({super.key, this.opacity = 0.025});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _GrainPainter(opacity), size: Size.infinite),
  );
}
class _GrainPainter extends CustomPainter {
  final double opacity;
  _GrainPainter(this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    for (int i = 0; i < 10000; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.7,
        Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * opacity),
      );
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Colors ─────────────────────────────────────────────────────────────────
class AppColors {
  static bool isDark = true;

  // Backgrounds
  static Color get bg       => isDark ? const Color(0xFF080601) : const Color(0xFFF5EFE0);
  static Color get card     => isDark ? const Color(0xFF0D0A00) : const Color(0xFFFFFFFF);
  static Color get elevated => isDark ? const Color(0xFF131000) : const Color(0xFFF0E8D0);
  static Color get high     => isDark ? const Color(0xFF1A1600) : const Color(0xFFE8DFC0);

  // Text
  static Color get text     => isDark ? const Color(0xFFDDD5A0) : const Color(0xFF1A1500);
  static Color get muted    => isDark ? const Color(0xFF5C5530) : const Color(0xFF8A7A40);
  static Color get subtle   => isDark ? const Color(0xFF2E2A18) : const Color(0xFFCCC5A0);

  // Accent — same amber in both modes
  static const accent      = Color(0xFFE8A000);
  static const accentLight = Color(0xFFFFBF3C);
  static const accentBlue  = Color(0xFFE8A000);

  // Status colors — darker in light mode for contrast
  static Color get green  => isDark ? const Color(0xFF4ADE80) : const Color(0xFF1A8040);
  static Color get orange => isDark ? const Color(0xFFFF6B35) : const Color(0xFFCC4000);

  // Border
  static Color get border => isDark ? const Color(0xFF2A2510) : const Color(0xFFDDD5B0);

  // Legacy aliases
  static Color get darkBg     => bg;
  static Color get darkCard   => card;
  static Color get darkBorder => border;
  static Color get darkText   => text;
  static Color get darkMuted  => muted;
  static Color get navyDark   => card;
  static Color get navyMid    => elevated;
  static Color get navyCard1  => elevated;
  static Color get navyCard2  => high;
  static Color get pill       => card;
}

// ── Theme ──────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData light() => _build(dark: false);
  static ThemeData dark() => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    const accent = AppColors.accent;
    const accentLight = AppColors.accentLight;
    final bg       = dark ? const Color(0xFF080601) : const Color(0xFFF5EFE0);
    final card     = dark ? const Color(0xFF0D0A00) : const Color(0xFFFFFFFF);
    final text     = dark ? const Color(0xFFDDD5A0) : const Color(0xFF1A1500);
    final base     = dark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: dark
          ? ColorScheme.dark(
              primary: accent, secondary: accentLight, surface: card)
          : ColorScheme.light(
              primary: accent, secondary: accentLight, surface: card),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
      ),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        filled: false,
      ),
    );
  }
}

// ── Text styles — monospace everything ─────────────────────────────────────
class AppText {
  // Numbers / data
  static TextStyle mono({double size = 16, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  // Section labels — all caps, tracked
  static TextStyle label({double size = 11, Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: color ?? AppColors.muted,
    );

  // Body — also monospace for terminal feel
  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  // Display (unused but kept for compat)
  static TextStyle display({double size = 80, FontWeight weight = FontWeight.w700, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight,
        color: color, height: 1.0);
}

// ── Number formatting ──────────────────────────────────────────────────────
class AppFormat {
  static String dollar(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  static String pct(double v) => '${v.toStringAsFixed(1)}%';

  // Format stop loss — strip unnecessary trailing zeros
  static String stopLoss(double v) {
    if (v % 1 == 0) return v.toStringAsFixed(0);
    if ((v * 10) % 1 == 0) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}

// ── Decorations ────────────────────────────────────────────────────────────
class AppDecor {
  // Terminal panel — thin border, sharp corners
  static BoxDecoration card({double radius = 4, Color? color}) => BoxDecoration(
    color: color ?? AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Active/glow card
  static BoxDecoration glowCard({double radius = 4, Color? glowColor}) {
    final c = glowColor ?? AppColors.accent;
    return BoxDecoration(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.withValues(alpha: 0.4), width: 1),
      boxShadow: [
        BoxShadow(color: c.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4)),
      ],
    );
  }

  // Focused input
  static BoxDecoration focusCard({double radius = 4}) => BoxDecoration(
    color: AppColors.elevated,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.7), width: 1),
    boxShadow: [
      BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 20),
    ],
  );

  // Pill-shaped instrument chip — active
  static BoxDecoration activeInstrumentPill() => BoxDecoration(
    color: AppColors.accent.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1),
  );

  // Pill-shaped instrument chip — inactive
  static BoxDecoration inactiveInstrumentPill() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Legacy
  static BoxDecoration navyGradientCard({double radius = 20}) => glowCard(radius: 4);
  static BoxDecoration whiteCard({double radius = 20}) => card(radius: 4);

  static BoxDecoration activeInstrument() => BoxDecoration(
    color: AppColors.accent.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1),
  );

  static BoxDecoration inactiveInstrument() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.border, width: 1),
  );
}
