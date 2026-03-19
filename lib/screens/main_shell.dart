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
      body: SafeArea(
        child: Stack(
          children: [
            // Page content — padded at bottom so pill never overlaps content
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
            // Floating pill nav — anchored inside safe area
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _FloatingPillNav(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              ),
            ),
          ],
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
    // Use LayoutBuilder to ensure pill never overflows screen width
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pill,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PillTab(icon: Icons.description_outlined, label: 'Calculator', active: currentIndex == 0, onTap: () => onTap(0)),
            _Divider(),
            _PillTab(icon: Icons.bar_chart, label: 'Levels', active: currentIndex == 1, onTap: () => onTap(1)),
            _Divider(),
            _PillTab(icon: Icons.star_outline, label: 'Instruments', active: currentIndex == 2, onTap: () => onTap(2)),
            _Divider(),
            _PillTab(icon: Icons.settings_outlined, label: 'Settings', active: currentIndex == 3, onTap: () => onTap(3)),
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
  const _PillTab({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.accent : Colors.white.withOpacity(0.28)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: active ? AppColors.accent : Colors.white.withOpacity(0.22),
            )),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: Colors.white.withOpacity(0.07), margin: const EdgeInsets.symmetric(horizontal: 1));
  }
}
