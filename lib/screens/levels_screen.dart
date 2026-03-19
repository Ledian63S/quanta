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
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(Icons.bar_chart_rounded, size: 30, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Text('No stop loss set',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.text)),
        const SizedBox(height: 6),
        Text('Enter a value in Calculator first',
            style: GoogleFonts.manrope(fontSize: 13, color: AppColors.muted)),
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
        // ── Hero: selected stop ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            // Ticker chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${state.currentInstrument.ticker}  ·  \$${state.currentInstrument.pointValue}/pt',
                style: AppText.label(color: AppColors.accentLight),
              ),
            ),
            const SizedBox(height: 24),

            // Big stop number
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                selectedStop.toStringAsFixed(1),
                key: ValueKey(selectedStop),
                style: AppText.mono(size: 72, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text('pts', style: AppText.label(color: AppColors.muted)),

            const SizedBox(height: 24),

            // Contracts + risk inline
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _HeroStat(
                value: '$contracts',
                label: 'contracts',
                color: AppColors.accentLight,
                large: true,
              ),
              Container(width: 1, height: 36, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
              _HeroStat(
                value: '\$${actualRisk.toStringAsFixed(0)}',
                label: 'actual risk',
                color: AppColors.green,
                large: true,
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 24),
        Container(height: 1, color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 20)),
        const SizedBox(height: 10),

        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(children: [
            Expanded(child: Text('POINTS', style: AppText.label(size: 10))),
            Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center,
                style: AppText.label(size: 10))),
            Expanded(child: Text('RISK', textAlign: TextAlign.right,
                style: AppText.label(size: 10))),
          ]),
        ),
        const SizedBox(height: 8),

        // ── Wheel ──────────────────────────────────────────────────────
        Expanded(
          child: Stack(children: [
            IgnorePointer(
              child: Center(
                child: Container(
                  height: _kRowHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(14),
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
                                          ? Colors.white : AppColors.muted,
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

class _HeroStat extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool large;
  const _HeroStat({required this.value, required this.label,
      required this.color, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(value,
          key: ValueKey(value),
          style: AppText.mono(
              size: large ? 28 : 20,
              weight: FontWeight.w700,
              color: color),
        ),
      ),
      const SizedBox(height: 3),
      Text(label, style: AppText.label(size: 10, color: AppColors.muted)),
    ]);
  }
}
