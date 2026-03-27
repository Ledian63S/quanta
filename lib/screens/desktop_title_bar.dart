import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/window_utils.dart';

// macOS traffic light colors
const _kClose    = Color(0xFFFF5F57);
const _kMinimize = Color(0xFFFFBD2E);
const _kZoom     = Color(0xFF28C840);
const _kDotSize  = 12.0;
const _kGap      = 8.0;

class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isMac = isNativeMacOS();

    return DragToMoveArea(
      child: Container(
        height: 38,
        color: AppColors.bg,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: isMac
              ? [
                  _TrafficLights(),
                  const Spacer(),
                ]
              : [
                  const Spacer(),
                  _WindowsButtons(),
                ],
        ),
      ),
    );
  }
}

// ── macOS traffic lights ───────────────────────────────────────────────────────
class _TrafficLights extends StatefulWidget {
  @override
  State<_TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<_TrafficLights> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: _kClose,    symbol: '×', showSymbol: _hovered, onTap: closeWindow),
          const SizedBox(width: _kGap),
          _Dot(color: _kMinimize, symbol: '−', showSymbol: _hovered, onTap: minimizeWindow),
          const SizedBox(width: _kGap),
          _Dot(color: _kZoom,     symbol: '+', showSymbol: _hovered, onTap: () {}),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final String symbol;
  final bool showSymbol;
  final VoidCallback onTap;
  const _Dot({required this.color, required this.symbol,
      required this.showSymbol, required this.onTap});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: _kDotSize,
        height: _kDotSize,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _pressed ? 0.6 : 1.0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: widget.showSymbol ? 1.0 : 0.0,
            child: Text(
              widget.symbol,
              style: TextStyle(
                fontSize: 8,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: widget.color.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Windows-style buttons (unchanged) ─────────────────────────────────────────
class _WindowsButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleBtn(label: '−', onTap: minimizeWindow),
        const SizedBox(width: 4),
        _TitleBtn(label: '×', onTap: closeWindow),
      ],
    );
  }
}

class _TitleBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TitleBtn({required this.label, required this.onTap});

  @override
  State<_TitleBtn> createState() => _TitleBtnState();
}

class _TitleBtnState extends State<_TitleBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 28, height: 20,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: _hovered ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(widget.label,
              style: AppText.mono(
                size: 12,
                color: _hovered ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
