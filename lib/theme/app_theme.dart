import 'dart:math';
import 'dart:ui';
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
    if (old.value != widget.value) {
      _ctrl.forward().then((_) {
        setState(() => _displayed = widget.value);
        _ctrl.reverse();
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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

// ── Risk arc gauge ─────────────────────────────────────────────────────────
class RiskGauge extends StatelessWidget {
  final double actual;
  final double max;
  final int contracts;
  const RiskGauge({super.key, required this.actual,
      required this.max, required this.contracts});

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (actual / max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 200, height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, r, __) => CustomPaint(
              size: const Size(200, 200),
              painter: _GaugePainter(ratio: r),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            TerminalNumber(value: contracts, size: 56, color: AppColors.accent),
            const SizedBox(height: 2),
            Text('CONTRACTS', style: AppText.label(size: 9, color: AppColors.muted)),
          ]),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  _GaugePainter({required this.ratio});

  static const _start = 135 * pi / 180;
  static const _sweep = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _start, _sweep, false,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Glow + fill
    if (ratio > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _start, _sweep * ratio, false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _start, _sweep * ratio, false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks at 0%, 25%, 50%, 75%, 100%
    final tickPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    for (int i = 0; i <= 4; i++) {
      final angle = _start + _sweep * (i / 4);
      final inner = center + Offset(cos(angle), sin(angle)) * (radius - 10);
      final outer = center + Offset(cos(angle), sin(angle)) * (radius + 6);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.ratio != ratio;
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
  static const bg       = Color(0xFF080601); // near-black, warm tint
  static const card     = Color(0xFF0D0A00); // dark amber-black
  static const elevated = Color(0xFF131000);
  static const high     = Color(0xFF1A1600);

  static const text     = Color(0xFFDDD5A0); // aged amber-white
  static const muted    = Color(0xFF5C5530); // dark amber
  static const subtle   = Color(0xFF2E2A18);

  static const accent      = Color(0xFFE8A000); // Bloomberg amber
  static const accentLight = Color(0xFFFFBF3C); // brighter amber
  static const accentBlue  = Color(0xFFE8A000); // alias

  static const green  = Color(0xFF4ADE80); // terminal green
  static const orange = Color(0xFFFF6B35); // warm orange-red for negatives

  static const border = Color(0xFF2A2510); // warm dark border

  // Legacy aliases
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

// ── Theme ──────────────────────────────────────────────────────────────────
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
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
    ),
    textTheme: GoogleFonts.jetBrainsMonoTextTheme(
        ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      filled: false,
    ),
  );
}

// ── Text styles — monospace everything ─────────────────────────────────────
class AppText {
  // Numbers / data
  static TextStyle mono({double size = 16, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  // Section labels — all caps, tracked
  static TextStyle label({double size = 10, Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: color ?? AppColors.muted,
    );

  // Body — also monospace for terminal feel
  static TextStyle body({double size = 13, FontWeight weight = FontWeight.w400, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  // Display (unused but kept for compat)
  static TextStyle display({double size = 80, FontWeight weight = FontWeight.w700, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight,
        color: color, height: 1.0);
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
