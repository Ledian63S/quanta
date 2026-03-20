import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'levels_screen.dart';
import 'instruments_screen.dart';
import 'settings_screen.dart';
import 'desktop_title_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _prevIndex = 0;
  late final AnimationController _animCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  late final List<Widget> _screens = [
    const CalculatorScreen(),
    LevelsScreen(onNavigateToCalc: () => _navigateTo(0)),
    const InstrumentsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0, // start fully visible
    );
    _slideAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _navigateTo(int i) {
    if (i == _currentIndex) return;
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = i;
    });
    _animCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Platform.isMacOS || Platform.isWindows;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bg,
      body: Column(children: [
        if (isDesktop) const DesktopTitleBar(),
        Expanded(child: Stack(
        children: [
          const Positioned.fill(child: ScanlineOverlay()),
          const Positioned.fill(child: GrainOverlay()),

          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth.clamp(0.0, 430.0);
                  final hPad = (constraints.maxWidth - contentWidth) / 2;
                  // direction: +1 = going right (higher index), -1 = going left
                  final direction = _currentIndex >= _prevIndex ? 1.0 : -1.0;
                  return AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, _) {
                      final t = _slideAnim.value;
                      return Stack(
                        children: [
                          // Exiting screen slides out
                          if (_animCtrl.isAnimating)
                            Positioned(
                              top: 0, bottom: 0,
                              left: hPad + (-direction * t * contentWidth * 0.3),
                              width: contentWidth,
                              child: Opacity(
                                opacity: (1.0 - t).clamp(0.0, 1.0),
                                child: IgnorePointer(child: _screens[_prevIndex]),
                              ),
                            ),
                          // Entering screen slides in
                          Positioned(
                            top: 0, bottom: 0,
                            left: hPad + (direction * (1.0 - t) * contentWidth * 0.3),
                            width: contentWidth,
                            child: Opacity(
                              opacity: _fadeAnim.value.clamp(0.0, 1.0),
                              child: IgnorePointer(
                                ignoring: _animCtrl.isAnimating,
                                child: _screens[_currentIndex],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: hPad, width: contentWidth,
                            child: _TerminalNav(
                              currentIndex: _currentIndex,
                              onTap: (i) {
                                HapticFeedback.selectionClick();
                                _navigateTo(i);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      )),
      ]),
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
