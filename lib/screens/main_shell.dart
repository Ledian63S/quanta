import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'levels_screen.dart';
import 'instruments_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    CalculatorScreen(),
    LevelsScreen(),
    InstrumentsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Scanlines
          const Positioned.fill(child: ScanlineOverlay()),
          // Grain
          const Positioned.fill(child: GrainOverlay()),

          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth.clamp(0.0, 430.0);
                  final hPad = (constraints.maxWidth - contentWidth) / 2;
                  return Stack(
                    children: [
                      ...List.generate(_screens.length, (i) => Positioned(
                        top: 0, bottom: 0,
                        left: hPad, width: contentWidth,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _currentIndex == i ? 1.0 : 0.0,
                          child: IgnorePointer(
                            ignoring: _currentIndex != i,
                            child: _screens[i],
                          ),
                        ),
                      )),
                      Positioned(
                        bottom: 0, left: hPad, width: contentWidth,
                        child: _TerminalNav(
                          currentIndex: _currentIndex,
                          onTap: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _currentIndex = i);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Terminal-style tab bar ─────────────────────────────────────────────────
class _TerminalNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _TerminalNav({required this.currentIndex, required this.onTap});

  static const _labels = ['CALC', 'LEVELS', 'MARKETS', 'SETTINGS'];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final active = currentIndex == i;
              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: active ? AppColors.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: active ? AppColors.accent : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
