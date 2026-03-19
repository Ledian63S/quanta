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
  late final TextEditingController _balanceController;
  final _slFocus = FocusNode();
  final _riskFocus = FocusNode();
  final _balanceFocus = FocusNode();
  bool _slFocused = false;
  bool _riskFocused = false;
  bool _balanceFocused = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<QuantaState>();
    _riskController = TextEditingController(text: state.riskAmount.toStringAsFixed(0));
    _balanceController = TextEditingController(text: state.accountBalance.toStringAsFixed(0));
    _slFocus.addListener(() => setState(() => _slFocused = _slFocus.hasFocus));
    _riskFocus.addListener(() => setState(() => _riskFocused = _riskFocus.hasFocus));
    _balanceFocus.addListener(() => setState(() => _balanceFocused = _balanceFocus.hasFocus));
  }

  @override
  void dispose() {
    _slController.dispose();
    _riskController.dispose();
    _balanceController.dispose();
    _slFocus.dispose();
    _riskFocus.dispose();
    _balanceFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + keyboardHeight),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Account strip ────────────────────────────────────────
            _AccountStrip(
              state: state,
              balanceController: _balanceController,
              riskController: _riskController,
              balanceFocus: _balanceFocus,
              riskFocus: _riskFocus,
              slFocus: _slFocus,
              balanceFocused: _balanceFocused,
              riskFocused: _riskFocused,
            ),
            const SizedBox(height: 20),

            // ── Instrument ───────────────────────────────────────────
            Text('INSTRUMENT', style: AppText.label()),
            const SizedBox(height: 8),
            _InstrumentRow(state: state, onChanged: () => _slController.clear()),
            const SizedBox(height: 20),

            // ── Stop loss input ──────────────────────────────────────
            Row(children: [
              Text('STOP LOSS', style: AppText.label()),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1,
                  color: AppColors.border)),
            ]),
            const SizedBox(height: 8),
            _StopLossPanel(
              controller: _slController,
              focusNode: _slFocus,
              focused: _slFocused,
              ticker: state.currentInstrument.ticker,
              onChanged: (v) => state.setStopLoss(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 20),

            // ── Result ───────────────────────────────────────────────
            Row(children: [
              Text('RESULT', style: AppText.label()),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ]),
            const SizedBox(height: 8),
            _ResultPanel(state: state),
          ]),
        ),
      ),

      // Done button
      if (keyboardHeight > 0)
        Positioned(
          bottom: keyboardHeight + 12, right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: (_slFocused || _riskFocused || _balanceFocused) ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !(_slFocused || _riskFocused || _balanceFocused),
              child: Clickable(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('DONE', style: AppText.label(color: Colors.black)),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

// ── Account strip ──────────────────────────────────────────────────────────
class _AccountStrip extends StatelessWidget {
  final QuantaState state;
  final TextEditingController balanceController, riskController;
  final FocusNode balanceFocus, riskFocus, slFocus;
  final bool balanceFocused, riskFocused;
  const _AccountStrip({
    required this.state,
    required this.balanceController, required this.riskController,
    required this.balanceFocus, required this.riskFocus, required this.slFocus,
    required this.balanceFocused, required this.riskFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card(),
      child: Row(children: [
        _AccountField(
          label: 'BALANCE',
          prefix: '\$',
          controller: balanceController,
          focusNode: balanceFocus,
          focused: balanceFocused,
          align: TextAlign.left,
          onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
          onSubmitted: (_) => riskFocus.requestFocus(),
        ),
        Container(width: 1, height: 52, color: AppColors.border),
        _AccountField(
          label: 'RISK/TRADE',
          prefix: '\$',
          controller: riskController,
          focusNode: riskFocus,
          focused: riskFocused,
          align: TextAlign.right,
          onChanged: (v) => state.setSessionRisk(double.tryParse(v) ?? state.riskAmount),
          onSubmitted: (_) => slFocus.requestFocus(),
        ),
      ]),
    );
  }
}

class _AccountField extends StatelessWidget {
  final String label, prefix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final TextAlign align;
  final ValueChanged<String> onChanged, onSubmitted;
  const _AccountField({
    required this.label, required this.prefix, required this.controller,
    required this.focusNode, required this.focused, required this.align,
    required this.onChanged, required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(
              color: focused ? AppColors.accentLight : AppColors.muted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: align == TextAlign.right
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(prefix, style: AppText.mono(size: 16, weight: FontWeight.w600,
                  color: focused ? AppColors.accent : AppColors.muted)),
              IntrinsicWidth(child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.next,
                textAlign: align,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                enableInteractiveSelection: false,
                cursorColor: AppColors.accent,
                style: AppText.mono(size: 16, weight: FontWeight.w600,
                    color: focused ? AppColors.accentLight : AppColors.text),
                decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              )),
            ],
          ),
        ],
      ),
    ));
  }
}

// ── Instrument row ─────────────────────────────────────────────────────────
class _InstrumentRow extends StatelessWidget {
  final QuantaState state;
  final VoidCallback onChanged;
  const _InstrumentRow({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final favs = state.favoriteInstruments;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecor.card(),
        child: Text('> STAR INSTRUMENTS TO ADD HERE',
            style: AppText.body(color: AppColors.muted)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: favs.map((inst) {
        final isActive = inst.ticker == state.selectedTicker;
        return Clickable(
          onTap: () {
            HapticFeedback.selectionClick();
            state.setInstrument(inst.ticker);
            onChanged();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: isActive
                ? AppDecor.activeInstrumentPill()
                : AppDecor.inactiveInstrumentPill(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(inst.ticker, style: AppText.mono(
                size: 13, weight: FontWeight.w700,
                color: isActive ? AppColors.accent : AppColors.text,
              )),
              const SizedBox(width: 6),
              Text('\$${inst.pointValue}', style: AppText.label(
                size: 9,
                color: isActive ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.muted,
              )),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

// ── Stop loss panel ────────────────────────────────────────────────────────
class _StopLossPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String ticker;
  final ValueChanged<String> onChanged;
  const _StopLossPanel({
    required this.controller, required this.focusNode,
    required this.focused, required this.ticker, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: focused ? AppDecor.focusCard() : AppDecor.card(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Prompt line
        Row(children: [
          Text('> ', style: AppText.mono(size: 12,
              color: focused ? AppColors.accent : AppColors.muted)),
          Text('$ticker  ', style: AppText.mono(size: 12,
              color: focused ? AppColors.accentLight : AppColors.subtle)),
          const Spacer(),
          Text('PTS', style: AppText.label(
              color: focused ? AppColors.accent : AppColors.muted)),
        ]),
        const SizedBox(height: 10),

        // Big number input
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.left,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          enableInteractiveSelection: false,
          cursorColor: AppColors.accent,
          cursorWidth: 2,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: focused ? AppColors.accent : AppColors.text,
            height: 1.0,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.0',
            hintStyle: GoogleFonts.jetBrainsMono(
              fontSize: 56, fontWeight: FontWeight.w300,
              color: AppColors.muted.withValues(alpha: 0.3),
              height: 1.0,
            ),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

// ── Result panel ───────────────────────────────────────────────────────────
class _ResultPanel extends StatelessWidget {
  final QuantaState state;
  const _ResultPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasData = state.stopLossPoints > 0;
    return Column(children: [
      // Arc gauge — centered
      Center(
        child: RiskGauge(
          actual: hasData ? state.actualRisk : 0,
          max: hasData ? state.effectiveRisk : 0,
          contracts: hasData ? state.contracts : 0,
        ),
      ),
      const SizedBox(height: 16),

      // Risk readout — table style
      Container(
        decoration: AppDecor.card(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(children: [
          _ReadoutRow('MAX RISK',
              '\$${state.effectiveRisk.toStringAsFixed(0)}', AppColors.muted),
          const SizedBox(height: 8),
          _ReadoutRow('ACTUAL  ',
              '\$${state.actualRisk.toStringAsFixed(0)}', AppColors.green),
          const SizedBox(height: 8),
          _ReadoutRow('UNUSED  ',
              '\$${state.unusedRisk.toStringAsFixed(0)}', AppColors.orange),
        ]),
      ),
    ]);
  }
}

class _ReadoutRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ReadoutRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppText.mono(size: 11, color: AppColors.muted)),
      const SizedBox(width: 4),
      const DotLeader(),
      const SizedBox(width: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(value,
          key: ValueKey(value),
          style: AppText.mono(size: 13, weight: FontWeight.w700, color: color),
        ),
      ),
    ]);
  }
}
