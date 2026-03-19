import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _slController = TextEditingController();
  final _slFocus = FocusNode();
  bool _slFocused = false;

  @override
  void initState() {
    super.initState();
    _slFocus.addListener(() => setState(() => _slFocused = _slFocus.hasFocus));
  }

  @override
  void dispose() {
    _slController.dispose();
    _slFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const LogoRow(subtitle: 'Calculator'),
          const SizedBox(height: 4),
          _ChipsRow(state: state),
          const SizedBox(height: 20),
          const _SectionLabel('Instrument'),
          const SizedBox(height: 8),
          _InstrumentScrollRow(state: state),
          const SizedBox(height: 20),
          const _SectionLabel('Stop Loss'),
          const SizedBox(height: 8),
          _StopLossCard(
            controller: _slController,
            focusNode: _slFocus,
            focused: _slFocused,
            onChanged: (v) => state.setStopLoss(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),
          if (state.contracts > 0 || state.stopLossPoints > 0)
            _ResultHeroCard(state: state),
        ]),
      ),
    );
  }
}

class LogoRow extends StatelessWidget {
  final String subtitle;
  const LogoRow({super.key, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accentBlue, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.blur_circular, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quanta', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.4)),
          Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.5)),
        ]),
      ]),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final QuantaState state;
  const _ChipsRow({required this.state});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _InfoChip(label: 'Balance', value: '\$${state.accountBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}', valueColor: AppColors.text)),
      const SizedBox(width: 8),
      Expanded(child: _InfoChip(label: 'Risk / Trade', value: '\$${state.riskAmount.toStringAsFixed(0)}', valueColor: AppColors.accentBlue)),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _InfoChip({required this.label, required this.value, required this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accentBlue, AppColors.accent]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(12, 13, 12, 11), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppText.label(color: AppColors.muted)),
            const SizedBox(height: 3),
            Text(value, style: AppText.mono(size: 14, weight: FontWeight.w600, color: valueColor)),
          ],
        )),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppText.label(color: AppColors.muted));
}

class _InstrumentScrollRow extends StatelessWidget {
  final QuantaState state;
  const _InstrumentScrollRow({required this.state});
  @override
  Widget build(BuildContext context) {
    final favs = state.favoriteInstruments;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.whiteCard(radius: 14),
        child: Text('★ Star instruments to add here', style: AppText.body(color: AppColors.muted)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: favs.map((inst) {
        final isActive = inst.ticker == state.selectedTicker;
        return GestureDetector(
          onTap: () => state.setInstrument(inst.ticker),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: isActive ? AppDecor.activeInstrument() : AppDecor.inactiveInstrument(),
            child: Column(children: [
              Text(inst.ticker, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.white : AppColors.text)),
              const SizedBox(height: 3),
              Text('\$${inst.pointValue}/pt', style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w500, color: isActive ? Colors.white.withValues(alpha: 0.55) : AppColors.muted)),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

class _StopLossCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;
  const _StopLossCard({required this.controller, required this.focusNode, required this.focused, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: focused ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.navyCard1, AppColors.navyCard2]) : null,
        color: focused ? null : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: focused ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border, width: 1.5),
        boxShadow: focused ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 8))] : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Enter Points', style: AppText.label(color: focused ? AppColors.accent.withValues(alpha: 0.5) : AppColors.muted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: focused ? AppColors.accent.withValues(alpha: 0.1) : AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: focused ? AppColors.accent.withValues(alpha: 0.2) : AppColors.border),
            ),
            child: Text('pts', style: AppText.label(color: focused ? AppColors.accent : AppColors.muted)),
          ),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppText.mono(size: 36, weight: FontWeight.w600, color: focused ? Colors.white : AppColors.text),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: AppText.mono(size: 28, weight: FontWeight.w300, color: focused ? Colors.white.withValues(alpha: 0.12) : AppColors.muted.withValues(alpha: 0.3)),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 3,
          margin: const EdgeInsets.only(top: 4, bottom: 0),
          decoration: BoxDecoration(
            gradient: focused ? const LinearGradient(colors: [AppColors.accentBlue, AppColors.accent]) : null,
            color: focused ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 0),
      ]),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final QuantaState state;
  const _ResultHeroCard({required this.state});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.navyGradientCard(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${state.currentInstrument.ticker} — ${state.currentInstrument.name} · \$${state.currentInstrument.pointValue}/pt',
          style: AppText.label(color: AppColors.accent.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${state.contracts}', style: AppText.mono(size: 56, weight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 8),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('contracts', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.3)))),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _RiskCell(label: 'Max Risk',     value: '\$${state.riskAmount.toStringAsFixed(0)}', color: Colors.white.withValues(alpha: 0.5)),
            _RiskCell(label: 'Actual Risk',  value: '\$${state.actualRisk.toStringAsFixed(0)}', color: AppColors.green),
            _RiskCell(label: 'Unused',       value: '\$${state.unusedRisk.toStringAsFixed(0)}', color: AppColors.orange, isLast: true),
          ]),
        ),
      ]),
    );
  }
}

class _RiskCell extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isLast;
  const _RiskCell({required this.label, required this.value, required this.color, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.label(size: 8.5, color: Colors.white.withValues(alpha: 0.28))),
        const SizedBox(height: 2),
        Text(value, style: AppText.mono(size: 13, weight: FontWeight.w600, color: color)),
      ]),
    ));
  }
}
