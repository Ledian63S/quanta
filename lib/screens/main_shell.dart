import 'package:flutter/material.dart';
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
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _FloatingPillNav(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingPillNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.pill : Colors.white;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(child: _PillTab(icon: Icons.description_outlined, label: 'Calculator', active: currentIndex == 0, onTap: () => onTap(0), isDark: isDark)),
            _NavDivider(color: dividerColor),
            Expanded(child: _PillTab(icon: Icons.bar_chart, label: 'Levels', active: currentIndex == 1, onTap: () => onTap(1), isDark: isDark)),
            _NavDivider(color: dividerColor),
            Expanded(child: _PillTab(icon: Icons.star_outline, label: 'Instruments', active: currentIndex == 2, onTap: () => onTap(2), isDark: isDark)),
            _NavDivider(color: dividerColor),
            Expanded(child: _PillTab(icon: Icons.settings_outlined, label: 'Settings', active: currentIndex == 3, onTap: () => onTap(3), isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  const _PillTab({required this.icon, required this.label, required this.active, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? Colors.white.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.3);
    final activeColor = isDark ? AppColors.accent : AppColors.accentBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? activeColor : inactiveColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: active ? activeColor : inactiveColor,
            )),
          ],
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  final Color color;
  const _NavDivider({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: color, margin: const EdgeInsets.symmetric(horizontal: 1));
  }
}
