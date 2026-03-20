import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

const _kRowHeight = 64.0;
const _kH = 20.0;

class LevelsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCalc;
  const LevelsScreen({super.key, this.onNavigateToCalc});
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  FixedExtentScrollController? _wheelController;
  int _selectedIndex = 0;
  double? _prevEffectiveRisk;
  double? _prevStopLoss;
  bool _prevHasData = false;
  DateTime _programmaticScrollUntil = DateTime(0);

  @override
  void dispose() {
    _wheelController?.dispose();
    super.dispose();
  }

  void _initWheel(List<double> levels, double targetRisk) {
    final idx = _closestIndex(levels, targetRisk);
    _selectedIndex = idx;
    final oldController = _wheelController;
    _wheelController = FixedExtentScrollController(initialItem: idx);
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => oldController.dispose());
    }
  }

  void _animateToRisk(List<double> levels, double targetRisk) {
    final idx = _closestIndex(levels, targetRisk);
    _selectedIndex = idx;
    _programmaticScrollUntil = DateTime.now().add(const Duration(milliseconds: 450));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wheelController?.animateToItem(idx,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  int _closestIndex(List<double> levels, double target) {
    if (levels.isEmpty) return 0;
    int best = 0;
    double bestDiff = double.infinity;
    for (int i = 0; i < levels.length; i++) {
      final d = (levels[i] - target).abs();
      if (d < bestDiff) { bestDiff = d; best = i; }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // depend on theme so colors repaint on brightness change
    final state = context.watch<QuantaState>();
    final hasData = state.stopLossPoints > 0;

    // Reset when data is cleared
    if (!hasData && _wheelController != null) {
      _wheelController!.dispose();
      _wheelController = null;
      _selectedIndex = 0;
      _prevEffectiveRisk = null;
      _prevStopLoss = null;
      _prevHasData = false;
    }

    if (!hasData) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(child: Text('///', style: AppText.mono(
              size: 14, weight: FontWeight.w700, color: AppColors.muted))),
        ),
        const SizedBox(height: 16),
        Text('NO DATA', style: AppText.label(color: AppColors.muted)),
        const SizedBox(height: 6),
        Text('> SET STOP LOSS IN CALC FIRST',
            style: AppText.mono(size: 11, color: AppColors.subtle)),
        if (widget.onNavigateToCalc != null) ...[
          const SizedBox(height: 20),
          Clickable(
            onTap: widget.onNavigateToCalc,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text('GO TO CALC',
                  style: AppText.label(color: AppColors.accent)),
            ),
          ),
        ],
      ]));
    }

    final levels = state.nearbyRiskLevels;

    // Initialize or animate when effective risk, stop loss, or data state changes
    final effectiveRiskChanged = _prevEffectiveRisk != state.effectiveRisk;
    final stopLossChanged = _prevStopLoss != state.stopLossPoints;
    final dataJustAppeared = !_prevHasData && hasData;

    if (dataJustAppeared || stopLossChanged || (effectiveRiskChanged && _wheelController == null)) {
      _prevEffectiveRisk = state.effectiveRisk;
      _prevStopLoss = state.stopLossPoints;
      _prevHasData = true;
      _initWheel(levels, state.effectiveRisk);
    } else if (effectiveRiskChanged && _wheelController != null) {
      _prevEffectiveRisk = state.effectiveRisk;
      _animateToRisk(levels, state.effectiveRisk);
    }

    final safeIndex = _selectedIndex.clamp(0, levels.length - 1);
    final selectedRisk = levels.isNotEmpty ? levels[safeIndex] : state.effectiveRisk;
    final contracts = state.contractsForRisk(selectedRisk);
    final actualRisk = state.actualRiskForRisk(selectedRisk);

    return SafeArea(
      child: Column(children: [

        // ── Hero ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(_kH, 16, _kH, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Ticker / label bar
            Row(children: [
              Text('> ', style: AppText.mono(size: 11, color: AppColors.accent)),
              Text(state.currentInstrument.ticker,
                  style: AppText.mono(size: 11, weight: FontWeight.w700,
                      color: AppColors.accentLight)),
              Text('  \$${state.currentInstrument.pointValue}/PT',
                  style: AppText.mono(size: 11, color: AppColors.muted)),
              const Spacer(),
              Text('LEVELS', style: AppText.label(color: AppColors.muted)),
            ]),
            const SizedBox(height: 14),

            // Hero stats — 3-column row matching wheel columns below
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // STOP LOSS — fixed from calculator (left)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('STOP LOSS', style: AppText.label(size: 10)),
                const SizedBox(height: 4),
                Text(AppFormat.stopLoss(state.stopLossPoints),
                    style: AppText.mono(size: 32, weight: FontWeight.w700,
                        color: AppColors.muted)),
                Text('pts  ·  fixed', style: AppText.label(size: 10, color: AppColors.subtle)),
              ])),

              // CONTRACTS for selected risk (center)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                Text('CONTRACTS', style: AppText.label(size: 10)),
                const SizedBox(height: 4),
                Text('$contracts',
                    textAlign: TextAlign.center,
                    style: AppText.mono(size: 32, weight: FontWeight.w700,
                        color: AppColors.accentLight)),
              ])),

              // ACTUAL RISK for selected risk (right)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text('ACTUAL RISK', style: AppText.label(size: 10)),
                const SizedBox(height: 4),
                Text(AppFormat.dollar(actualRisk),
                    style: AppText.mono(size: 32, weight: FontWeight.w700,
                        color: AppColors.green)),
              ])),
            ]),

            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Column headers
            Row(children: [
              Expanded(child: Text('RISK', style: AppText.label(size: 10))),
              Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center,
                  style: AppText.label(size: 10))),
              Expanded(child: Text('ACTUAL', textAlign: TextAlign.right,
                  style: AppText.label(size: 10))),
            ]),
            const SizedBox(height: 6),
          ]),
        ),

        // ── Wheel ──────────────────────────────────────────────────────
        Expanded(
          child: Stack(children: [

            // Selection highlight
            IgnorePointer(
              child: Center(
                child: Container(
                  height: _kRowHeight,
                  margin: const EdgeInsets.symmetric(horizontal: _kH - 4),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.65), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        blurRadius: 16, spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_wheelController != null)
              Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent && _wheelController != null) {
                    final next = (_selectedIndex + (event.scrollDelta.dy > 0 ? 1 : -1))
                        .clamp(0, levels.length - 1);
                    if (next != _selectedIndex) {
                      _wheelController!.animateToItem(next,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut);
                    }
                  }
                },
              child: Builder(builder: (context) {
                final maxC = levels.isEmpty ? 1
                    : levels.map((r) => state.contractsForRisk(r))
                        .reduce((a, b) => a > b ? a : b);
                return ListWheelScrollView.useDelegate(
                  controller: _wheelController!,
                  itemExtent: _kRowHeight,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 100,
                  overAndUnderCenterOpacity: 1.0,
                  onSelectedItemChanged: (i) {
                    if (DateTime.now().isAfter(_programmaticScrollUntil)) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() => _selectedIndex = i);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: levels.length,
                    builder: (context, i) {
                      final risk = levels[i];
                      final c = state.contractsForRisk(risk);
                      final ar = state.actualRiskForRisk(risk);
                      final barFraction = maxC > 0 ? c / maxC : 0.0;
                      final isSelected = i == _selectedIndex;
                      final isCurrentRisk = (risk - state.effectiveRisk).abs() < 0.01;
                      final distance = (i - _selectedIndex).abs();
                      final opacity = isSelected
                          ? 1.0
                          : (1.0 - distance * 0.13).clamp(0.18, 0.6);
                      return Opacity(
                        opacity: opacity,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background bar
                              Positioned(
                                left: 0, top: 8, bottom: 8,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: constraints.maxWidth * barFraction * 0.55,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                        alpha: isSelected ? 0.08 : 0.04),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(2),
                                      bottomRight: Radius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              // Left cursor
                              Positioned(
                                left: 0, top: 12, bottom: 12,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 2,
                                  color: isSelected
                                      ? AppColors.accent : Colors.transparent,
                                ),
                              ),
                              // Row content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: _kH),
                                child: Row(children: [
                                  // RISK column
                                  Expanded(child: Row(children: [
                                    Text(AppFormat.dollar(risk),
                                        style: AppText.mono(
                                          size: isSelected ? 18 : 14,
                                          weight: isSelected
                                              ? FontWeight.w700 : FontWeight.w400,
                                          color: isSelected
                                              ? AppColors.text : AppColors.muted,
                                        )),
                                    if (isCurrentRisk) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 4, height: 4,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ])),
                                  // CONTRACTS column
                                  Expanded(child: Text('$c',
                                      textAlign: TextAlign.center,
                                      style: AppText.mono(
                                        size: isSelected ? 18 : 14,
                                        weight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.accentLight : AppColors.subtle,
                                      ))),
                                  // ACTUAL column
                                  Expanded(child: Text(AppFormat.dollar(ar),
                                      textAlign: TextAlign.right,
                                      style: AppText.mono(
                                        size: isSelected ? 18 : 14,
                                        weight: isSelected
                                            ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.green : AppColors.subtle,
                                      ))),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              })),

            // Fade overlays
            Positioned(top: 0, left: 0, right: 0,
              child: IgnorePointer(child: Container(height: 80,
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.bg, AppColors.bg.withValues(alpha: 0)],
                ))))),
            Positioned(bottom: 0, left: 0, right: 0,
              child: IgnorePointer(child: Container(height: 80,
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg],
                ))))),
          ]),
        ),
      ]),
    );
  }
}
