import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';

class WebShell extends StatelessWidget {
  const WebShell({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        const Positioned.fill(child: ScanlineOverlay()),
        const Positioned.fill(child: GrainOverlay()),
        SafeArea(
          child: Column(children: [
            const _WebTopBar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 760) {
                    return const _WideLayout();
                  }
                  // Narrow (mobile-sized browser): single column calculator
                  return const CalculatorScreen();
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Top navigation bar ──────────────────────────────────────────────────────
class _WebTopBar extends StatelessWidget {
  const _WebTopBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.92),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Text('> ', style: AppText.mono(size: 13, color: AppColors.accent)),
            Text('QUANTA', style: AppText.mono(
              size: 13, weight: FontWeight.w700, color: AppColors.text,
            )),
            const Spacer(),
            Clickable(
              onTap: () {
                final next = state.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                state.setThemeMode(next);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    state.themeMode == ThemeMode.dark ? '◑  LIGHT' : '☀  DARK',
                    style: AppText.label(size: 10, color: AppColors.muted),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Two-column wide layout ───────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Calculator panel
        SizedBox(
          width: 420,
          child: const CalculatorScreen(),
        ),
        // Vertical divider
        Container(width: 1, color: AppColors.border),
        // Right: Levels panel
        const Expanded(child: _WebLevelsPanel()),
      ],
    );
  }
}

// ── Levels panel (web) ───────────────────────────────────────────────────────
class _WebLevelsPanel extends StatelessWidget {
  const _WebLevelsPanel();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final levels = state.nearbyRiskLevels;

    if (levels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NO DATA', style: AppText.label(color: AppColors.subtle)),
            const SizedBox(height: 8),
            Text('ENTER A STOP LOSS TO SEE LEVELS',
                style: AppText.label(size: 10, color: AppColors.subtle)),
          ],
        ),
      );
    }

    final maxContracts = levels
        .map((r) => state.contractsForRisk(r))
        .fold(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
        const SizedBox(height: 12),
        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            SizedBox(
              width: 100,
              child: Text('RISK', style: AppText.label(size: 10, color: AppColors.muted)),
            ),
            SizedBox(
              width: 80,
              child: Text('CTS', textAlign: TextAlign.center,
                  style: AppText.label(size: 10, color: AppColors.muted)),
            ),
            Expanded(
              child: Text('ACTUAL', textAlign: TextAlign.right,
                  style: AppText.label(size: 10, color: AppColors.muted)),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 24)),
        const SizedBox(height: 4),
        // Rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final risk = levels[index];
              final contracts = state.contractsForRisk(risk);
              final actual = state.actualRiskForRisk(risk);
              final isCurrent =
                  (risk - state.effectiveRisk).abs() < 0.01;

              return _LevelRow(
                risk: risk,
                contracts: contracts,
                actual: actual,
                isCurrent: isCurrent,
                maxContracts: maxContracts,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final double risk;
  final int contracts;
  final double actual;
  final bool isCurrent;
  final int maxContracts;

  const _LevelRow({
    required this.risk,
    required this.contracts,
    required this.actual,
    required this.isCurrent,
    required this.maxContracts,
  });

  @override
  Widget build(BuildContext context) {
    final barWidth = maxContracts > 0 ? contracts / maxContracts : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(children: [
        // Background bar proportional to contracts
        if (!isCurrent)
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        // Highlight for current risk
        if (isCurrent)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35)),
              ),
            ),
          ),
        // Row content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            SizedBox(
              width: 100,
              child: Text(
                AppFormat.dollar(risk),
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accent : AppColors.text,
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '$contracts',
                textAlign: TextAlign.center,
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accent : AppColors.text,
                ),
              ),
            ),
            Expanded(
              child: Text(
                AppFormat.dollar(actual),
                textAlign: TextAlign.right,
                style: AppText.mono(
                  size: 13,
                  weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent ? AppColors.accentLight : AppColors.muted,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
