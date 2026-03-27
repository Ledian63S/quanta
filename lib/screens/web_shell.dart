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
Color _cardBg(bool d) => d ? const Color(0xFF141414) : const Color(0xFFF2F2F2);

BoxDecoration _pageDeco(bool d) => BoxDecoration(
  gradient: RadialGradient(
    center: Alignment.center,
    radius: 1.1,
    colors: d
        ? [const Color(0xFF1E1E1E), const Color(0xFF050505)]
        : [const Color(0xFFD8D8D8), const Color(0xFFB4B4B4)],
  ),
);

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
    _NavItem('Calc',     '#'),
    _NavItem('Levels',   '≡'),
    _NavItem('Markets',  '◈'),
    _NavItem('Settings', '⚙'),
  ];

  Widget _screen() {
    switch (_tab) {
      case 0: return const WebCalcScreen();
      case 1: return LevelsScreen(onNavigateToCalc: () => _setTab(0));
      case 2: return const InstrumentsScreen();
      case 3: return const SettingsScreen();
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
                  child: SizedBox(
                    width: double.infinity, height: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardBg(d),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: d ? 0.6 : 0.14),
                            blurRadius: 50, offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Sidebar — floating pill with own border radius
                            _Sidebar(
                              items: _items,
                              currentIndex: _tab,
                              isDark: d,
                              state: state,
                              onTap: _setTab,
                            ),
                            Expanded(child: _screen()),
                          ],
                        ),
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

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final String label, icon;
  const _NavItem(this.label, this.icon);
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

    // Wrap in padding so sidebar floats inside the outer card
    // The AnimatedContainer has its OWN border radius (all 4 corners)
    return Padding(
      padding: const EdgeInsets.all(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: _expanded ? 172 : 62,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: d
                ? [const Color(0xFF2D2D2D), const Color(0xFF1F1F1F)]
                : [const Color(0xFF464646), const Color(0xFF383838)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),

            // Logo
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 0),
              child: _expanded
                  ? Row(children: [
                      _GoldCircle(),
                      const SizedBox(width: 10),
                      Text('Quanta', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                      )),
                    ])
                  : Center(child: _GoldCircle()),
            ),

            const SizedBox(height: 24),

            // Nav items
            for (int i = 0; i < widget.items.length; i++)
              _NavRow(
                item: widget.items[i],
                active: widget.currentIndex == i,
                expanded: _expanded,
                onTap: () => widget.onTap(i),
              ),

            const Spacer(),

            // Bottom card — matches Image #2 exactly
            _BottomCard(
              isDark: d,
              expanded: _expanded,
              state: widget.state,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ── Gold circle logo ──────────────────────────────────────────────────────────
class _GoldCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
            blurRadius: 14, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text('Q', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black,
        )),
      ),
    );
  }
}

// ── Nav row ───────────────────────────────────────────────────────────────────
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
      waitDuration: const Duration(milliseconds: 600),
      textStyle: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 0),
            decoration: BoxDecoration(
              // Row gets a very subtle tint on hover
              color: _hovered && !active
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Circle — gold gradient (active) or visible gray fill (inactive)
                // This matches Image #2 exactly
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
                          )
                        : null,
                    // Inactive: clearly visible gray circle (like Image #2)
                    color: active ? null : const Color(0xFF595959),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(widget.item.icon, style: TextStyle(
                      fontSize: 16,
                      color: active ? Colors.black : const Color(0xFFBBBBBB),
                    )),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Text(widget.item.label, style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? Colors.white : const Color(0xFF888888),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom card — matches Image #2 bottom widget ──────────────────────────────
class _BottomCard extends StatefulWidget {
  final bool isDark, expanded;
  final QuantaState state;
  final VoidCallback onToggle;
  const _BottomCard({
    required this.isDark, required this.expanded,
    required this.state, required this.onToggle,
  });
  @override
  State<_BottomCard> createState() => _BottomCardState();
}
class _BottomCardState extends State<_BottomCard> {
  bool _btnHovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final exp = widget.expanded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: d
                ? [const Color(0xFF1E1E1E), const Color(0xFF161616)]
                : [const Color(0xFF2E2E2E), const Color(0xFF242424)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exp) ...[
                  Text('Quanta', style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    'Fast position sizing\nfor futures traders.',
                    style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF777777), height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // White "Get Started" style button — matches Image #2 exactly
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _btnHovered = true),
                  onExit:  (_) => setState(() => _btnHovered = false),
                  child: GestureDetector(
                    onTap: () => widget.state.setThemeMode(
                        d ? ThemeMode.light : ThemeMode.dark),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _btnHovered
                            ? const Color(0xFFE8E8E8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d ? '◑' : '☀',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black)),
                          if (exp) ...[
                            const SizedBox(width: 6),
                            Text(d ? 'Light mode' : 'Dark mode',
                              style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.black,
                              )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Collapse/expand arrow
                Center(
                  child: GestureDetector(
                    onTap: widget.onToggle,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedRotation(
                        turns: exp ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 240),
                        child: const Icon(Icons.chevron_right,
                            color: Color(0xFF555555), size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Partially-cut-off gold circle icon in bottom-right — matches Image #2
          if (exp)
            Positioned(
              bottom: -18, right: -18,
              child: Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('#', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: Colors.black,
                  )),
                ),
              ),
            ),
        ]),
      ),
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
  static const _labels = ['Calc', 'Levels', 'Markets', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF464646), Color(0xFF383838)],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: active
                              ? const Color(0xFFD4AF37)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(_labels[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: active
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF888888),
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
