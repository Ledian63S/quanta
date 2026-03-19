import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

const _kRowHeight = 56.0;
// Horizontal padding shared by header + wheel rows so they align exactly
const _kH = 20.0;

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  FixedExtentScrollController? _wheelController;
  int _selectedIndex = 0;
  double? _prevStopLossPoints;
  DateTime _programmaticScrollUntil = DateTime(0);

  @override
  void dispose() {
    _wheelController?.dispose();
    super.dispose();
  }

  void _initWheel(List<double> levels, double stopLoss) {
    final idx = levels.indexWhere((l) => (l - stopLoss).abs() < 0.01);
    _selectedIndex = idx >= 0 ? idx : levels.length ~/ 2;
    _wheelController?.dispose();
    _wheelController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  void _animateToStop(List<double> levels, double stop) {
    final idx = levels.indexWhere((l) => (l - stop).abs() < 0.01);
    if (idx < 0) return;
    _selectedIndex = idx;
    _programmaticScrollUntil = DateTime.now().add(const Duration(milliseconds: 450));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wheelController?.animateToItem(idx,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final hasData = state.stopLossPoints > 0;

    if (!hasData && _wheelController != null) {
      _wheelController!.dispose();
      _wheelController = null;
      _selectedIndex = 0;
      _prevStopLossPoints = 0;
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
      ]));
    }

    final levels = state.nearbyStopLevels;

    if (_prevStopLossPoints != state.stopLossPoints) {
      _prevStopLossPoints = state.stopLossPoints;
      if (_wheelController == null) {
        _initWheel(levels, state.stopLossPoints);
      } else {
        _animateToStop(levels, state.stopLossPoints);
      }
    }

    final safeIndex = _selectedIndex.clamp(0, levels.length - 1);
    final selectedStop = levels.isNotEmpty ? levels[safeIndex] : state.stopLossPoints;
    final contracts = state.contractsForStop(selectedStop);
    final actualRisk = state.actualRiskForStop(selectedStop);

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

            // Stop + stats — 3-column row matching the wheel below
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              // STOP LOSS (left column)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('STOP LOSS', style: AppText.label(size: 9)),
                const SizedBox(height: 4),
                Text(selectedStop.toStringAsFixed(1),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 40, fontWeight: FontWeight.w700,
                        color: AppColors.accent, height: 1.0)),
                Text('pts', style: AppText.label(size: 9, color: AppColors.muted)),
              ])),

              // CONTRACTS (center column)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                Text('CONTRACTS', style: AppText.label(size: 9)),
                const SizedBox(height: 4),
                Text('$contracts',
                    textAlign: TextAlign.center,
                    style: AppText.mono(size: 32, weight: FontWeight.w700,
                        color: AppColors.accentLight)),
              ])),

              // ACTUAL RISK (right column)
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text('ACTUAL RISK', style: AppText.label(size: 9)),
                const SizedBox(height: 4),
                Text('\$${actualRisk.toStringAsFixed(0)}',
                    style: AppText.mono(size: 22, weight: FontWeight.w700,
                        color: AppColors.green)),
              ])),
            ]),

            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Column headers — same 3-column layout
            Row(children: [
              Expanded(child: Text('POINTS', style: AppText.label(size: 9))),
              Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center,
                  style: AppText.label(size: 9))),
              Expanded(child: Text('RISK', textAlign: TextAlign.right,
                  style: AppText.label(size: 9))),
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
                        color: AppColors.accent.withValues(alpha: 0.3), width: 1),
                  ),
                ),
              ),
            ),

            if (_wheelController != null)
              Builder(builder: (context) {
                final maxC = levels.isEmpty ? 1
                    : levels.map((l) => state.contractsForStop(l))
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
                      final sl = levels[i];
                      final c = state.contractsForStop(sl);
                      final ar = state.actualRiskForStop(sl);
                      final barFraction = maxC > 0 ? c / maxC : 0.0;
                      final isSelected = i == _selectedIndex;
                      return Opacity(
                        opacity: isSelected ? 1.0 : 0.55,
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
                              // Row content — centered by Stack alignment
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: _kH),
                                child: Row(children: [
                                  Expanded(child: Text(sl.toStringAsFixed(1),
                                      style: AppText.mono(
                                        size: isSelected ? 15 : 13,
                                        weight: isSelected
                                            ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.text : AppColors.muted,
                                      ))),
                                  Expanded(child: Text('$c',
                                      textAlign: TextAlign.center,
                                      style: AppText.mono(
                                        size: isSelected ? 17 : 14,
                                        weight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.accentLight : AppColors.subtle,
                                      ))),
                                  Expanded(child: Text('\$${ar.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: AppText.mono(
                                        size: isSelected ? 15 : 13,
                                        weight: FontWeight.w500,
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
              }),

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
