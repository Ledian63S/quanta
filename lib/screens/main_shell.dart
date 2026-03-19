import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: GestureDetector(
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
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      opacity: _currentIndex == i ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: _currentIndex != i,
                        child: _screens[i],
                      ),
                    ),
                  )),
                  Positioned(
                    bottom: 10,
                    left: hPad, width: contentWidth,
                    child: _NavBar(
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
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _NavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.calculate_outlined, Icons.calculate_rounded, 'Calc'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Levels'),
    (Icons.star_outline_rounded, Icons.star_rounded, 'Markets'),
    (Icons.tune_outlined, Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 40, offset: const Offset(0, 10)),
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.04), blurRadius: 60),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: List.generate(_items.length, (i) {
            final (iconOut, iconFill, label) = _items[i];
            final active = currentIndex == i;
            return Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            active ? iconFill : iconOut,
                            key: ValueKey(active),
                            size: 22,
                            color: active ? AppColors.accent : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.accent : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
