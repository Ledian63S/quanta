import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';
import 'web_calc_screen.dart';
import 'levels_screen.dart';
import 'instruments_screen.dart';
import 'settings_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
Color _cardBg(bool d) => d ? const Color(0xFF141414) : const Color(0xFFF0F0F0);

BoxDecoration _pageDeco(bool d) => BoxDecoration(
  gradient: RadialGradient(
    center: Alignment.center,
    radius: 1.1,
    colors: d
        ? [const Color(0xFF1E1E1E), const Color(0xFF050505)]
        : [const Color(0xFFD8D8D8), const Color(0xFFB4B4B4)],
  ),
);

const Color _gold  = Color(0xFFD4AF37);
const Color _goldD = Color(0xFF9E7C1A);

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

// ── Shell ─────────────────────────────────────────────────────────────────────
class WebShell extends StatefulWidget {
  const WebShell({super.key});
  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  int _tab = 0;
  void _setTab(int i) => setState(() => _tab = i);

  static const _items = [
    _NavItem('Calc',     Icons.calculate_outlined),
    _NavItem('Levels',   Icons.bar_chart_outlined),
    _NavItem('Markets',  Icons.candlestick_chart_outlined),
    _NavItem('Settings', Icons.settings_outlined),
  ];

  Widget _screen() {
    switch (_tab) {
      case 0:  return const WebCalcScreen();
      case 1:  return LevelsScreen(onNavigateToCalc: () => _setTab(0));
      case 2:  return const InstrumentsScreen();
      case 3:  return const SettingsScreen();
      default: return const WebCalcScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    final d = AppColors.isDark;
    final state = context.watch<QuantaState>();

    return Scaffold(
      body: Container(
        decoration: _pageDeco(d),
        child: Stack(children: [
          const Positioned.fill(child: ScanlineOverlay()),
          const Positioned.fill(child: GrainOverlay()),
          LayoutBuilder(builder: (ctx, cons) {
            final wide = cons.maxWidth >= 700;

            if (!wide) {
              return Container(
                color: _cardBg(d),
                child: Column(children: [
                  Expanded(child: _screen()),
                  _MobileNav(currentIndex: _tab, onTap: _setTab, isDark: d),
                ]),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardBg(d),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: d
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: d ? 0.55 : 0.18),
                          blurRadius: 60, offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Sidebar(
                            items: _items,
                            currentIndex: _tab,
                            isDark: d,
                            state: state,
                            onTap: _setTab,
                          ),
                          // Hairline separator
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: d
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                          Expanded(child: _screen()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class _Sidebar extends StatefulWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final bool isDark;
  final QuantaState state;
  final ValueChanged<int> onTap;

  const _Sidebar({
    required this.items, required this.currentIndex,
    required this.isDark, required this.state, required this.onTap,
  });
  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: _expanded ? 220 : 64,
      decoration: BoxDecoration(
        color: d ? const Color(0xFF161616) : const Color(0xFF1C1C1E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Traffic lights ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _expanded
                ? Row(children: [
                    _Dot(const Color(0xFFFF5F57)),
                    const SizedBox(width: 7),
                    _Dot(const Color(0xFFFFBD2E)),
                    const SizedBox(width: 7),
                    _Dot(const Color(0xFF28C840)),
                  ])
                : Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _Dot(const Color(0xFFFF5F57)),
                      const SizedBox(height: 5),
                      _Dot(const Color(0xFFFFBD2E)),
                      const SizedBox(height: 5),
                      _Dot(const Color(0xFF28C840)),
                    ]),
                  ),
          ),

          const SizedBox(height: 20),

          // ── Logo ─────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _expanded ? 14 : 0),
            child: _expanded
                ? Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/icon_rounded.png',
                          width: 32, height: 32),
                    ),
                    const SizedBox(width: 10),
                    Text('Quanta', style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                  ])
                : Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/icon_rounded.png',
                          width: 32, height: 32),
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // ── Section label ─────────────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text('MENU', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 0.8,
              )),
            ),

          // ── Nav items ─────────────────────────────────────────────────────
          for (int i = 0; i < widget.items.length; i++)
            _NavRow(
              item: widget.items[i],
              active: widget.currentIndex == i,
              expanded: _expanded,
              onTap: () => widget.onTap(i),
            ),

          const Spacer(),

          // ── Bottom area ───────────────────────────────────────────────────
          _BottomArea(
            isDark: d,
            expanded: _expanded,
            state: widget.state,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Traffic light dot ─────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11, height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Nav row — macOS sidebar style ─────────────────────────────────────────────
class _NavRow extends StatefulWidget {
  final _NavItem item;
  final bool active, expanded;
  final VoidCallback onTap;
  const _NavRow({
    required this.item, required this.active,
    required this.expanded, required this.onTap,
  });
  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active   = widget.active;
    final expanded = widget.expanded;

    return Tooltip(
      message: !expanded ? widget.item.label : '',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      textStyle: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 10 : 8,
              vertical: 2,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
              decoration: BoxDecoration(
                color: active
                    ? _gold.withValues(alpha: 0.14)
                    : (_hovered
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 17,
                    color: active ? _gold : Colors.white.withValues(alpha: 0.4),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Text(widget.item.label, style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom area ───────────────────────────────────────────────────────────────
class _BottomArea extends StatefulWidget {
  final bool isDark, expanded;
  final QuantaState state;
  final VoidCallback onToggle;
  const _BottomArea({
    required this.isDark, required this.expanded,
    required this.state, required this.onToggle,
  });
  @override
  State<_BottomArea> createState() => _BottomAreaState();
}
class _BottomAreaState extends State<_BottomArea> {
  bool _themeHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final exp = widget.expanded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: exp ? 10 : 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Hairline separator
        Divider(height: 1, thickness: 1,
            color: Colors.white.withValues(alpha: 0.07)),
        const SizedBox(height: 12),

        // Theme toggle row
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _themeHovered = true),
          onExit:  (_) => setState(() => _themeHovered = false),
          child: GestureDetector(
            onTap: () => widget.state.setThemeMode(
                d ? ThemeMode.light : ThemeMode.dark),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: exp ? 10 : 0),
              decoration: BoxDecoration(
                color: _themeHovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: exp
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(
                    d ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 17,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  if (exp) ...[
                    const SizedBox(width: 10),
                    Text(d ? 'Light mode' : 'Dark mode',
                      style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.5),
                      )),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Collapse / expand toggle
        GestureDetector(
          onTap: widget.onToggle,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: exp ? 10 : 0),
              child: SizedBox(
                height: 32,
                child: Row(
                  mainAxisAlignment: exp
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    AnimatedRotation(
                      turns: exp ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(Icons.chevron_right,
                          color: Colors.white.withValues(alpha: 0.2), size: 18),
                    ),
                    if (exp) ...[
                      const SizedBox(width: 8),
                      Text('Collapse', style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.2),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Mobile bottom nav ─────────────────────────────────────────────────────────
class _MobileNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  const _MobileNav({
    required this.currentIndex, required this.onTap, required this.isDark,
  });
  static const _labels  = ['Calc', 'Levels', 'Markets', 'Settings'];
  static const _icons   = [
    Icons.calculate_outlined,
    Icons.bar_chart_outlined,
    Icons.candlestick_chart_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final active = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_icons[i], size: 20,
                        color: active
                            ? _gold
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.35)),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: active
                              ? _gold
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.35)),
                        ),
                      ),
                    ]),
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
