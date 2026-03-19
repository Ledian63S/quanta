import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

const _kRowHeight = 58.0;

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
          child: Center(
            child: Text('///', style: AppText.mono(size: 14,
                weight: FontWeight.w700, color: AppColors.muted)),
          ),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Status bar
            Row(children: [
              Text('> ', style: AppText.mono(size: 11, color: AppColors.accent)),
              Text(state.currentInstrument.ticker,
                  style: AppText.mono(size: 11, color: AppColors.accentLight,
                      weight: FontWeight.w700)),
              Text('  \$${state.currentInstrument.pointValue}/PT',
                  style: AppText.mono(size: 11, color: AppColors.muted)),
              const Spacer(),
              Text('LEVELS', style: AppText.label(color: AppColors.muted)),
            ]),
            const SizedBox(height: 16),

            // Big stop display
            Container(
              decoration: AppDecor.glowCard(glowColor: AppColors.accent),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('STOP LOSS', style: AppText.label(color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Text(
                    selectedStop.toStringAsFixed(1),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 56, fontWeight: FontWeight.w700,
                        color: AppColors.accent, height: 1.0),
                  ),
                  Text('pts', style: AppText.label(color: AppColors.muted)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _StatBox(label: 'CONTRACTS', value: '$contracts',
                      color: AppColors.accentLight, large: true),
                  const SizedBox(height: 10),
                  _StatBox(label: 'ACTUAL RISK',
                      value: '\$${actualRisk.toStringAsFixed(0)}',
                      color: AppColors.green, large: false),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Column headers
            Row(children: [
              const SizedBox(width: 16),
              Expanded(child: Text('POINTS', style: AppText.label(size: 9))),
              Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center,
                  style: AppText.label(size: 9))),
              Expanded(child: Text('RISK', textAlign: TextAlign.right,
                  style: AppText.label(size: 9))),
              const SizedBox(width: 16),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListWheelScrollView.useDelegate(
                  controller: _wheelController!,
                  itemExtent: _kRowHeight,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 100,
                  overAndUnderCenterOpacity: 1.0,
                  onSelectedItemChanged: (i) {
                    if (DateTime.now().isAfter(_programmaticScrollUntil))
                      HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = i);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: levels.length,
                    builder: (context, i) {
                      final sl = levels[i];
                      final c = state.contractsForStop(sl);
                      final ar = state.actualRiskForStop(sl);
                      return AnimatedBuilder(
                        animation: _wheelController!,
                        builder: (context, _) {
                          double dist = 0;
                          if (_wheelController!.hasClients) {
                            final frac = _wheelController!.offset / _kRowHeight;
                            dist = (frac - i).abs();
                          }
                          final isSelected = dist < 0.5;
                          final opacity = (1.0 - dist * 0.18).clamp(0.4, 1.0);
                          return Opacity(
                            opacity: opacity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(children: [
                                Expanded(child: Text(sl.toStringAsFixed(1),
                                    style: AppText.mono(
                                      size: isSelected ? 16 : 14,
                                      weight: isSelected
                                          ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.text : AppColors.muted,
                                    ))),
                                Expanded(child: Text('$c',
                                    textAlign: TextAlign.center,
                                    style: AppText.mono(
                                      size: isSelected ? 18 : 15,
                                      weight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.accentLight : AppColors.subtle,
                                    ))),
                                Expanded(child: Text('\$${ar.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: AppText.mono(
                                      size: isSelected ? 16 : 14,
                                      weight: FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.green : AppColors.subtle,
                                    ))),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            // Fade overlays
            Positioned(top: 0, left: 0, right: 0,
              child: IgnorePointer(child: Container(height: 70,
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.bg, AppColors.bg.withValues(alpha: 0)],
                ))))),
            Positioned(bottom: 0, left: 0, right: 0,
              child: IgnorePointer(child: Container(height: 70,
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

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool large;
  const _StatBox({required this.label, required this.value,
      required this.color, required this.large});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label, style: AppText.label(size: 9, color: AppColors.muted)),
      const SizedBox(height: 2),
      Text(value, style: AppText.mono(
          size: large ? 28 : 20,
          weight: FontWeight.w700,
          color: color)),
    ]);
  }
}
