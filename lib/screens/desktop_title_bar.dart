import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';

class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isMac = Platform.isMacOS;

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleBtn(label: '×', onTap: () => windowManager.close()),
        const SizedBox(width: 4),
        _TitleBtn(label: '−', onTap: () => windowManager.minimize()),
        const SizedBox(width: 4),
        _TitleBtn(
          label: '□',
          onTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.restore();
            } else {
              await windowManager.maximize();
            }
          },
        ),
      ],
    );

    return DragToMoveArea(
      child: Container(
        height: 38,
        color: AppColors.bg,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: isMac
              ? [buttons, const Spacer()]
              : [const Spacer(), buttons],
        ),
      ),
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
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 28,
          height: 20,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.elevated : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: _hovered ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
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
