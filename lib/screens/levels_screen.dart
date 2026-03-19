import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});
  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  double? _selectedStop;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final hasData = state.stopLossPoints > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const LogoRow(subtitle: 'Levels'),
          if (!hasData)
            Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bar_chart, size: 48, color: AppColors.muted.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Enter a stop loss in Calculator\nto see nearby levels', textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w500, height: 1.6)),
            ])))
          else ...[
            _SummaryCard(state: state),
            const SizedBox(height: 16),
            const _SectionLabel('Nearby Stop Levels'),
            const SizedBox(height: 8),
            const _TableHeader(),
            const SizedBox(height: 6),
            Expanded(child: _LevelsTable(state: state, selectedStop: _selectedStop ?? state.stopLossPoints,
              onSelectStop: (s) => setState(() => _selectedStop = s))),
          ],
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final QuantaState state;
  const _SummaryCard({required this.state});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.navyGradientCard(),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${state.currentInstrument.ticker} · \$${state.currentInstrument.pointValue}/pt',
          style: AppText.label(color: AppColors.accent.withValues(alpha: 0.45))),
        const SizedBox(height: 8),
        Row(children: [
          _SumItem(label: 'Contracts', value: '${state.contracts}', color: AppColors.accent),
          _SumItem(label: 'Stop Loss', value: '${state.stopLossPoints} pts', color: Colors.white),
          _SumItem(label: 'Actual Risk', value: '\$${state.actualRisk.toStringAsFixed(0)}', color: Colors.white),
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
      Text(label, style: AppText.label(size: 8.5, color: Colors.white.withValues(alpha: 0.3))),
      const SizedBox(height: 3),
      Text(value, style: AppText.mono(size: 15, weight: FontWeight.w600, color: color)),
    ]));
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        Expanded(child: Text('POINTS', style: AppText.label(size: 9, color: AppColors.muted))),
        Expanded(child: Text('CONTRACTS', textAlign: TextAlign.center, style: AppText.label(size: 9, color: AppColors.muted))),
        Expanded(child: Text('ACTUAL RISK', textAlign: TextAlign.right, style: AppText.label(size: 9, color: AppColors.muted))),
      ]),
    );
  }
}

class _LevelsTable extends StatelessWidget {
  final QuantaState state;
  final double selectedStop;
  final ValueChanged<double> onSelectStop;
  const _LevelsTable({required this.state, required this.selectedStop, required this.onSelectStop});

  @override
  Widget build(BuildContext context) {
    final levels = state.nearbyStopLevels;
    return ListView.builder(
      itemCount: levels.length,
      itemBuilder: (context, i) {
        final sl = levels[i];
        final c = state.contractsForStop(sl);
        final ar = state.actualRiskForStop(sl);
        final isSelected = (sl - selectedStop).abs() < 0.01;
        return GestureDetector(
          onTap: () => onSelectStop(sl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? const LinearGradient(colors: [AppColors.navyCard1, AppColors.navyCard2]) : null,
              borderRadius: BorderRadius.circular(13),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))] : null,
            ),
            child: Row(children: [
              Expanded(child: Text(sl.toStringAsFixed(1), style: AppText.body(size: 13, color: isSelected ? Colors.white.withValues(alpha: 0.4) : AppColors.muted))),
              Expanded(child: Text('$c', textAlign: TextAlign.center,
                style: AppText.mono(size: isSelected ? 16 : 14, weight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.text))),
              Expanded(child: Text('\$${ar.toStringAsFixed(0)}', textAlign: TextAlign.right,
                style: AppText.mono(size: 13, weight: FontWeight.w500, color: isSelected ? AppColors.green : AppColors.text))),
            ]),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppText.label(color: AppColors.muted));
}
