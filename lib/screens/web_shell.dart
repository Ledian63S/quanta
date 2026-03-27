import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../utils/window_utils.dart';
import 'web_calc_screen.dart';
import 'levels_screen.dart';
import 'instruments_screen.dart';
import 'settings_screen.dart';

// ── Palette — VOID terminal ────────────────────────────────────────────────────
Color _sidebarBg(bool d) => d ? const Color(0xFF0C0C0C) : const Color(0xFFF0ECE8);
Color _desktopBg(bool d) => d ? const Color(0xFF000000) : const Color(0xFFD8D4CF);

// ── Nav item model ────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final Color iconBg;
  const _NavItem(this.label, this.icon, this.iconBg);
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
    _NavItem('Calculator', Icons.calculate_outlined,      Color(0xFFD4AF37)),
    _NavItem('Levels',   Icons.bar_chart_outlined,         Color(0xFF4ADE80)),
    _NavItem('Markets',  Icons.candlestick_chart_outlined, Color(0xFFFF6B35)),
    _NavItem('Settings', Icons.settings_outlined,          Color(0xFF807060)),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LayoutBuilder(builder: (ctx, cons) {
        final wide = cons.maxWidth >= 700;

        // ── Mobile layout — unchanged ──────────────────────────────────────
        if (!wide) {
          return Column(children: [
            Expanded(child: _screen()),
            _MobileNav(currentIndex: _tab, onTap: _setTab, isDark: d),
          ]);
        }

        final isNativeDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows);

        final sidebarAndContent = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              items: _items,
              currentIndex: _tab,
              isDark: d,
              onTap: _setTab,
              showTrafficLights: isNativeDesktop,
            ),
            VerticalDivider(
              width: 1, thickness: 1,
              color: d
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.07),
            ),
            Expanded(child: _screen()),
          ],
        );

        // ── Native desktop: fill window, no outer border/background ───────────
        if (isNativeDesktop) {
          return sidebarAndContent;
        }

        // ── Web: centered floating macOS window ───────────────────────────────
        return Container(
          color: _desktopBg(d),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1100,
                  maxHeight: cons.maxHeight - 56,
                ),
                child: _FloatingWindow(
                  isDark: d,
                  child: sidebarAndContent,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Floating window container ──────────────────────────────────────────────────
class _FloatingWindow extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _FloatingWindow({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
              : const Color(0xFFB8B0A6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.18),
            blurRadius: 48,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: child,
      ),
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class _Sidebar extends StatefulWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;
  final bool showTrafficLights;

  const _Sidebar({
    required this.items, required this.currentIndex,
    required this.isDark, required this.onTap,
    this.showTrafficLights = false,
  });
  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'v${info.version}.${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;

    return Container(
      width: 210,
      decoration: BoxDecoration(color: _sidebarBg(d)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Traffic lights (native desktop only) ─────────────────────
          if (widget.showTrafficLights)
            DragToMoveArea(
              child: _TrafficLights(),
            ),

          const SizedBox(height: 20),

          // ── Logo then app name, centered ─────────────────────────────
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('assets/icon_rounded.png', width: 58, height: 58),
              ),
              const SizedBox(height: 8),
              Text('Quanta', style: AppText.mono(
                size: 13, weight: FontWeight.w700,
                color: d ? const Color(0xFFD4AF37) : const Color(0xFF9A7D1A),
              )),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Section label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text('MENU', style: AppText.label()),
          ),

          // ── Nav items ────────────────────────────────────────────────────
          for (int i = 0; i < widget.items.length; i++)
            _NavRow(
              item: widget.items[i],
              active: widget.currentIndex == i,
              onTap: () => widget.onTap(i),
            ),

          const Spacer(),

          // ── Bottom area (theme toggle + footer) ──────────────────────────
          _BottomArea(isDark: d, version: _version),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Nav row — macOS System Settings style ─────────────────────────────────────
class _NavRow extends StatefulWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavRow({required this.item, required this.active, required this.onTap});
  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final d = AppColors.isDark;
    final accent = d ? const Color(0xFFD4AF37) : const Color(0xFF9A7D1A);
    final textColor = d ? const Color(0xFFF0ECD8) : const Color(0xFF080808);
    final mutedColor = d ? const Color(0xFF807060) : const Color(0xFF4A4642);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: d ? 0.15 : 0.12)
                  : (_hovered
                      ? (d
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.05))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(2),
              border: active
                  ? Border.all(color: accent.withValues(alpha: 0.4), width: 1)
                  : null,
              boxShadow: active ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(children: [
              // Icon badge
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: active
                      ? accent.withValues(alpha: 0.2)
                      : widget.item.iconBg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: active
                        ? accent.withValues(alpha: 0.5)
                        : widget.item.iconBg.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 13,
                  color: active ? accent : widget.item.iconBg,
                ),
              ),
              const SizedBox(width: 9),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                style: AppText.label(
                  color: active ? accent : mutedColor,
                ),
                child: Text(widget.item.label.toUpperCase()),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Bottom area ───────────────────────────────────────────────────────────────
class _BottomArea extends StatelessWidget {
  final bool isDark;
  final String version;
  const _BottomArea({
    required this.isDark, required this.version,
  });

  @override
  Widget build(BuildContext context) {
    final d = isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Hairline separator
        Divider(height: 1, thickness: 1,
            color: d
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07)),
        const SizedBox(height: 10),

        // Footer — centered, subtle
        Center(
          child: Text(
            'Made with ♥ for traders'
            '${version.isEmpty ? '' : '\n$version'}',
            textAlign: TextAlign.center,
            style: AppText.mono(
              size: 10,
              color: d
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.22),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── macOS traffic lights ──────────────────────────────────────────────────────
const _kClose    = Color(0xFFFF5F57);
const _kMinimize = Color(0xFFFFBD2E);
const _kZoom     = Color(0xFF28C840);

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _TLDot(color: _kClose,    symbol: '×', show: _hovered, onTap: closeWindow),
          const SizedBox(width: 8),
          _TLDot(color: _kMinimize, symbol: '−', show: _hovered, onTap: minimizeWindow),
          const SizedBox(width: 8),
          _TLDot(color: _kZoom,     symbol: '+', show: _hovered, onTap: zoomWindow),
        ]),
      ),
    );
  }
}

class _TLDot extends StatefulWidget {
  final Color color;
  final String symbol;
  final bool show;
  final VoidCallback onTap;
  const _TLDot({required this.color, required this.symbol,
      required this.show, required this.onTap});
  @override
  State<_TLDot> createState() => _TLDotState();
}

class _TLDotState extends State<_TLDot> {
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
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _pressed ? 0.6 : 1.0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: widget.show ? 1.0 : 0.0,
            child: Text(widget.symbol, style: TextStyle(
              fontSize: 8, height: 1.0, fontWeight: FontWeight.w900,
              color: widget.color.withValues(alpha: 0.5),
            )),
          ),
        ),
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
  static const _icons  = [
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
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _icons[i],
                          key: ValueKey(active),
                          size: 20,
                          color: active
                              ? (isDark ? const Color(0xFFD4AF37) : const Color(0xFF9A7D1A))
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.35)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[i],
                        style: AppText.mono(
                          size: 10, weight: FontWeight.w500,
                          color: active
                              ? (isDark ? const Color(0xFFD4AF37) : const Color(0xFF9A7D1A))
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
