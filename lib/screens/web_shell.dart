import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'levels_screen.dart';
import 'instruments_screen.dart';
import 'settings_screen.dart';

class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _tab = 0;
  bool _sidebarExpanded = false;

  void _setTab(int i) => setState(() => _tab = i);
  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

  static const _labels = ['CALC', 'LEVELS', 'MARKETS', 'SETTINGS'];
  static const _icons  = ['#', '≡', '◈', '⚙'];

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        const Positioned.fill(child: ScanlineOverlay()),
        const Positioned.fill(child: GrainOverlay()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Narrow viewport: revert to mobile-like layout
              if (constraints.maxWidth < 700) {
                return Column(children: [
                  Expanded(child: _mobileContent()),
                  _MobileNav(currentIndex: _tab, onTap: _setTab),
                ]);
              }
              // Wide viewport: sidebar dashboard
              return Row(children: [
                _Sidebar(
                  currentIndex: _tab,
                  labels: _labels,
                  icons: _icons,
                  expanded: _sidebarExpanded,
                  onTap: _setTab,
                  onToggle: _toggleSidebar,
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: Column(children: [
                    _TopBar(title: _labels[_tab]),
                    Expanded(child: _wideContent()),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _mobileContent() {
    switch (_tab) {
      case 1: return LevelsScreen(onNavigateToCalc: () => _setTab(0));
      case 2: return const InstrumentsScreen();
      case 3: return const SettingsScreen();
      default: return const CalculatorScreen();
    }
  }

  Widget _wideContent() {
    switch (_tab) {
      case 0: return const _WebCalcView();
      case 1: return _WebLevelsView(onNavigateToCalc: () => _setTab(0));
      case 2: return const _WebScrollView(child: InstrumentsScreen());
      case 3: return const _WebScrollView(child: SettingsScreen());
      default: return const _WebCalcView();
    }
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final List<String> icons;
  final bool expanded;
  final ValueChanged<int> onTap;
  final VoidCallback onToggle;
  const _Sidebar({
    required this.currentIndex,
    required this.labels,
    required this.icons,
    required this.expanded,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? 180 : 64,
      color: AppColors.bg,
      child: Column(children: [
        // Logo + toggle
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Text('Q',
              style: AppText.mono(
                size: 18, weight: FontWeight.w700, color: AppColors.accent,
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text('QUANTA',
                  style: AppText.mono(
                    size: 11, weight: FontWeight.w700, color: AppColors.text,
                  ),
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
            const Spacer(),
            Clickable(
              onTap: onToggle,
              child: Text(expanded ? '‹' : '›',
                style: AppText.mono(size: 16, color: AppColors.muted),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        // Nav items
        for (int i = 0; i < labels.length; i++)
          _SidebarItem(
            icon: icons[i],
            label: labels[i],
            active: currentIndex == i,
            expanded: expanded,
            onTap: () => onTap(i),
          ),
      ]),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String icon, label;
  final bool active, expanded;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon, required this.label,
    required this.active, required this.expanded,
    required this.onTap,
  });
  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.active
        ? AppColors.accent
        : _hovered ? AppColors.text : AppColors.muted;

    final item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.accent.withValues(alpha: 0.1)
                : _hovered ? AppColors.elevated : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.active ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(children: [
            Text(widget.icon,
              style: TextStyle(fontSize: 16, color: iconColor)),
            if (widget.expanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label,
                  overflow: TextOverflow.clip,
                  style: AppText.label(
                    size: 11,
                    color: widget.active ? AppColors.accent : AppColors.muted,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );

    // Only show tooltip when collapsed
    if (widget.expanded) return item;
    return Tooltip(
      message: widget.label,
      preferBelow: false,
      textStyle: GoogleFonts.jetBrainsMono(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: AppColors.bg, letterSpacing: 1.4,
      ),
      child: item,
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.92),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Text('> ', style: AppText.mono(size: 12, color: AppColors.accent)),
            Text(title,
              style: AppText.mono(
                size: 13, weight: FontWeight.w700, color: AppColors.text,
              ),
            ),
            const Spacer(),
            // Theme toggle
            Clickable(
              onTap: () => state.setThemeMode(
                state.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  state.themeMode == ThemeMode.dark ? '◑  LIGHT' : '☀  DARK',
                  style: AppText.label(size: 10, color: AppColors.muted),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Web Calc View (two-column dashboard) ─────────────────────────────────────
class _WebCalcView extends StatelessWidget {
  const _WebCalcView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below 900px: single column (calc + levels stacked)
        if (constraints.maxWidth < 900) {
          return const CalculatorScreen();
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: inputs (account + instrument + stop loss + result)
            SizedBox(width: 420, child: const CalculatorScreen()),
            Container(width: 1, color: AppColors.border),
            // Right: levels table
            const Expanded(child: _LevelsPanel()),
          ],
        );
      },
    );
  }
}

// ── Web Levels View ──────────────────────────────────────────────────────────
class _WebLevelsView extends StatelessWidget {
  final VoidCallback? onNavigateToCalc;
  const _WebLevelsView({this.onNavigateToCalc});

  @override
  Widget build(BuildContext context) {
    return LevelsScreen(onNavigateToCalc: onNavigateToCalc);
  }
}

// ── Scrollable wrapper for screens designed for mobile ──────────────────────
class _WebScrollView extends StatelessWidget {
  final Widget child;
  const _WebScrollView({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ── Levels panel for the right column ───────────────────────────────────────
class _LevelsPanel extends StatelessWidget {
  const _LevelsPanel();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final levels = state.nearbyRiskLevels;

    if (levels.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('—', style: AppText.mono(size: 32, color: AppColors.subtle)),
          const SizedBox(height: 12),
          Text('ENTER A STOP LOSS', style: AppText.label(size: 10, color: AppColors.subtle)),
          const SizedBox(height: 4),
          Text('to see risk levels', style: AppText.body(size: 11, color: AppColors.subtle)),
        ]),
      );
    }

    final maxCts = levels
        .map((r) => state.contractsForRisk(r))
        .fold(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(children: [
            Text('LEVELS', style: AppText.label()),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: AppColors.border)),
            const SizedBox(width: 12),
            Text(
              'SL  ${AppFormat.stopLoss(state.stopLossPoints)} PTS',
              style: AppText.label(size: 10, color: AppColors.muted),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            SizedBox(width: 100,
              child: Text('RISK', style: AppText.label(size: 10, color: AppColors.muted))),
            SizedBox(width: 72,
              child: Text('CTS', textAlign: TextAlign.center,
                  style: AppText.label(size: 10, color: AppColors.muted))),
            Expanded(
              child: Text('ACTUAL', textAlign: TextAlign.right,
                  style: AppText.label(size: 10, color: AppColors.muted))),
          ]),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(height: 1, color: AppColors.border),
        ),
        const SizedBox(height: 4),
        // Rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final risk      = levels[i];
              final cts       = state.contractsForRisk(risk);
              final actual    = state.actualRiskForRisk(risk);
              final isCurrent = (risk - state.effectiveRisk).abs() < 0.01;
              final barFrac   = maxCts > 0 ? cts / maxCts : 0.0;
              return _LevelRow(
                risk: risk, contracts: cts, actual: actual,
                isCurrent: isCurrent, barFraction: barFrac,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final double risk, actual, barFraction;
  final int contracts;
  final bool isCurrent;
  const _LevelRow({
    required this.risk, required this.contracts,
    required this.actual, required this.isCurrent,
    required this.barFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(children: [
        // Background bar
        if (!isCurrent)
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barFraction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        // Highlight row
        if (isCurrent)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(children: [
            SizedBox(
              width: 100,
              child: Text(AppFormat.dollar(risk),
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accent : AppColors.text,
                )),
            ),
            SizedBox(
              width: 72,
              child: Text('$contracts',
                textAlign: TextAlign.center,
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accent : AppColors.text,
                )),
            ),
            Expanded(
              child: Text(AppFormat.dollar(actual),
                textAlign: TextAlign.right,
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accentLight : AppColors.muted,
                )),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Mobile bottom nav (narrow viewports) ────────────────────────────────────
class _MobileNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _MobileNav({required this.currentIndex, required this.onTap});

  static const _labels = ['CALC', 'LEVELS', 'MARKETS', 'SETTINGS'];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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
                      child: Text(_labels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10, fontWeight: FontWeight.w700,
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
