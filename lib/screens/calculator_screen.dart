import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _riskController;
  final _slFocus = FocusNode();
  final _riskFocus = FocusNode();
  bool _slFocused = false;
  bool _riskFocused = false;

  @override
  void initState() {
    super.initState();
    _riskController = TextEditingController(
      text: context.read<QuantaState>().riskAmount.toStringAsFixed(0),
    );
    _slFocus.addListener(() => setState(() => _slFocused = _slFocus.hasFocus));
    _riskFocus.addListener(() => setState(() => _riskFocused = _riskFocus.hasFocus));
  }

  @override
  void dispose() {
    _slController.dispose();
    _riskController.dispose();
    _slFocus.dispose();
    _riskFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + keyboardHeight),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ChipsRow(state: state, riskFocus: _riskFocus, riskController: _riskController),
              const SizedBox(height: 24),
              const _SectionLabel('Instrument'),
              const SizedBox(height: 10),
              _InstrumentScrollRow(state: state),
              const SizedBox(height: 24),
              const _SectionLabel('Stop Loss'),
              const SizedBox(height: 10),
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
          )),
          if ((_slFocused || _riskFocused) && keyboardHeight > 0)
            Positioned(
              bottom: keyboardHeight + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Builder(builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: Text('Done', style: AppText.label(color: isDark ? AppColors.accent : AppColors.accentBlue)),
                  );
                }),
              ),
            ),
        ],
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
  final FocusNode riskFocus;
  final TextEditingController riskController;
  const _ChipsRow({required this.state, required this.riskFocus, required this.riskController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Balance', style: AppText.label(color: AppColors.muted)),
                  const SizedBox(height: 5),
                  Text(
                    '\$${state.accountBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: AppText.mono(size: 18, weight: FontWeight.w600, color: AppColors.accentBlue),
                  ),
                ]),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Risk / Trade', style: AppText.label(color: AppColors.muted)),
                  const SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('\$', style: AppText.mono(size: 18, weight: FontWeight.w600, color: AppColors.accentBlue)),
                    IntrinsicWidth(
                      child: TextField(
                        controller: riskController,
                        focusNode: riskFocus,
                        onChanged: (v) => state.setSessionRisk(double.tryParse(v) ?? state.riskAmount),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        textAlign: TextAlign.right,
                        style: AppText.mono(size: 18, weight: FontWeight.w600, color: AppColors.accentBlue),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ],
        ),
      ),
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
          onTap: () {
                HapticFeedback.selectionClick();
                state.setInstrument(inst.ticker);
              },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            decoration: isActive ? AppDecor.activeInstrument() : AppDecor.inactiveInstrument(),
            child: Column(children: [
              Text(inst.ticker, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: isActive ? Colors.white : AppColors.text)),
              const SizedBox(height: 4),
              Text('\$${inst.pointValue}/pt', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? Colors.white.withValues(alpha: 0.55) : AppColors.muted)),
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
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
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          style: AppText.mono(size: 44, weight: FontWeight.w600, color: focused ? Colors.white : AppColors.text),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.00',
            hintStyle: AppText.mono(size: 36, weight: FontWeight.w300, color: focused ? Colors.white.withValues(alpha: 0.12) : AppColors.muted.withValues(alpha: 0.3)),
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
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          '${state.currentInstrument.ticker} — ${state.currentInstrument.name} · \$${state.currentInstrument.pointValue}/pt',
          style: AppText.label(color: AppColors.accent.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${state.contracts}', style: AppText.mono(size: 68, weight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('contracts', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.3)))),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _RiskCell(label: 'Max Risk',     value: '\$${state.effectiveRisk.toStringAsFixed(0)}', color: Colors.white.withValues(alpha: 0.5)),
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
        Text(label, style: AppText.label(size: 10, color: Colors.white.withValues(alpha: 0.28))),
        const SizedBox(height: 3),
        Text(value, style: AppText.mono(size: 16, weight: FontWeight.w600, color: color)),
      ]),
    ));
  }
}
