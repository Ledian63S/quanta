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

// ── Risk arc gauge ─────────────────────────────────────────────────────────
class RiskGauge extends StatefulWidget {
  final double actual;
  final double max;
  final int contracts;
  const RiskGauge({super.key, required this.actual,
      required this.max, required this.contracts});
  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _pulse = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(RiskGauge old) {
    super.didUpdateWidget(old);
    if (old.contracts != widget.contracts && widget.contracts > 0) {
      _pulseCtrl.forward(from: 0).then((_) => _pulseCtrl.reverse());
    }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.max > 0
        ? (widget.actual / widget.max).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 250, height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, r, __) => AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => CustomPaint(
                size: const Size(250, 250),
                painter: _GaugePainter(ratio: r, pulse: _pulse.value),
              ),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            TerminalNumber(value: widget.contracts, size: 72,
                color: AppColors.accent),
            const SizedBox(height: 4),
            Text('CONTRACTS',
                style: AppText.label(size: 10, color: AppColors.muted)),
          ]),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  final double pulse;
  _GaugePainter({required this.ratio, this.pulse = 0});

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
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Glow + fill
    if (ratio > 0.01) {
      final glowAlpha = 0.2 + pulse * 0.35;
      final glowWidth = 26.0 + pulse * 16;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _start, _sweep * ratio, false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: glowAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = glowWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _start, _sweep * ratio, false,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }

    // Tick marks at 0%, 25%, 50%, 75%, 100%
    final tickPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5;
    for (int i = 0; i <= 4; i++) {
      final angle = _start + _sweep * (i / 4);
      final inner = center + Offset(cos(angle), sin(angle)) * (radius - 12);
      final outer = center + Offset(cos(angle), sin(angle)) * (radius + 8);
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.ratio != ratio || old.pulse != pulse || old._isDark != _isDark;

  final bool _isDark = AppColors.isDark;
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
