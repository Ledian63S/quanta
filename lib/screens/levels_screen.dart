import 'package:flutter/material.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wheelController?.animateToItem(idx,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final hasData = state.stopLossPoints > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.bg;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    if (!hasData) {
      return SafeArea(
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart, size: 48, color: mutedColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Enter a stop loss in Calculator\nto see nearby levels',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 14, color: mutedColor,
                  fontWeight: FontWeight.w500, height: 1.6)),
        ])),
      );
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

    final selectedStop = levels.isNotEmpty ? levels[_selectedIndex] : state.stopLossPoints;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SummaryCard(state: state, selectedStop: selectedStop),
          const SizedBox(height: 20),
          _SectionLabel('Nearby Stop Levels', color: mutedColor),
          const SizedBox(height: 10),
          _TableHeader(mutedColor: mutedColor),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [

                // Center highlight — fixed behind the wheel
                IgnorePointer(
                  child: Center(
                    child: Container(
                      height: _kRowHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.navyCard1, AppColors.navyCard2],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.35), width: 1.5),
                        boxShadow: [BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            blurRadius: 16)],
                      ),
                    ),
                  ),
                ),

                // Wheel picker — snaps automatically
                if (_wheelController != null)
                  ListWheelScrollView.useDelegate(
                    controller: _wheelController!,
                    itemExtent: _kRowHeight,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 100,
                    overAndUnderCenterOpacity: 1.0,
                    onSelectedItemChanged: (i) =>
                        setState(() => _selectedIndex = i),
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
                            final opacity = (1.0 - dist * 0.15).clamp(0.5, 1.0);
                            final ptSize = (17.0 - dist * 1.2).clamp(14.0, 17.0);
                            final cSize  = (19.0 - dist * 1.4).clamp(15.0, 19.0);
                            final rSize  = (17.0 - dist * 1.2).clamp(14.0, 17.0);
                            return Opacity(
                              opacity: opacity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(children: [
                                  Expanded(child: Text(sl.toStringAsFixed(1),
                                      style: AppText.body(size: ptSize,
                                          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.85)
                                              : textColor))),
                                  Expanded(child: Text('$c',
                                      textAlign: TextAlign.center,
                                      style: AppText.mono(size: cSize,
                                          weight: FontWeight.w700,
                                          color: isSelected ? Colors.white : textColor))),
                                  Expanded(child: Text('\$${ar.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: AppText.mono(size: rSize,
                                          weight: FontWeight.w500,
                                          color: isSelected ? AppColors.green : textColor))),
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                // Top fade
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [bgColor, bgColor.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom fade
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [bgColor.withValues(alpha: 0), bgColor],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final QuantaState state;
  final double selectedStop;
  const _SummaryCard({required this.state, required this.selectedStop});
  @override
  Widget build(BuildContext context) {
    final c = state.contractsForStop(selectedStop);
    final ar = state.actualRiskForStop(selectedStop);
    return Container(
      decoration: AppDecor.navyGradientCard(),
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${state.currentInstrument.ticker} · \$${state.currentInstrument.pointValue}/pt',
            style: AppText.label(color: AppColors.accent.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        Row(children: [
          _SumItem(label: 'Contracts', value: '$c', color: AppColors.accent),
          _SumItem(label: 'Stop Loss',
              value: '${selectedStop.toStringAsFixed(1)} pts', color: Colors.white),
          _SumItem(label: 'Actual Risk',
              value: '\$${ar.toStringAsFixed(0)}', color: Colors.white),
        ]),
      ]),
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumItem({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppText.label(size: 11, color: Colors.white.withValues(alpha: 0.3))),
      const SizedBox(height: 5),
      Text(value, style: AppText.mono(size: 20, weight: FontWeight.w600, color: color)),
    ]));
  }
}

class _TableHeader extends StatelessWidget {
  final Color mutedColor;
  const _TableHeader({required this.mutedColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(child: Text('POINTS', style: AppText.label(size: 11, color: mutedColor))),
        Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center,
            style: AppText.label(size: 11, color: mutedColor))),
        Expanded(child: Text('ACTUAL RISK', textAlign: TextAlign.right,
            style: AppText.label(size: 11, color: mutedColor))),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, {required this.color});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.label(color: color));
}
