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

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 108 + keyboardHeight),
            child: Column(children: [

              // ── Top bar: Balance | Risk ──────────────────────────────
              _TopBar(
                state: state,
                balanceController: _balanceController,
                riskController: _riskController,
                balanceFocus: _balanceFocus,
                riskFocus: _riskFocus,
                slFocus: _slFocus,
                balanceFocused: _balanceFocused,
                riskFocused: _riskFocused,
              ),
              const SizedBox(height: 14),

              // ── Instrument chips ─────────────────────────────────────
              _InstrumentRow(state: state, onChanged: () => _slController.clear()),
              const SizedBox(height: 14),

              // ── Stop loss hero input ─────────────────────────────────
              _StopLossHero(
                state: state,
                controller: _slController,
                focusNode: _slFocus,
                focused: _slFocused,
                onChanged: (v) => state.setStopLoss(double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 14),

              // ── Result hero ──────────────────────────────────────────
              _ResultHero(state: state),
            ]),
          ),
        ),

        // Done button
        if (keyboardHeight > 0)
          Positioned(
            bottom: keyboardHeight + 12, right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: (_slFocused || _riskFocused || _balanceFocused) ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_slFocused || _riskFocused || _balanceFocused),
                child: Clickable(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Text('Done', style: AppText.label(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final QuantaState state;
  final TextEditingController balanceController, riskController;
  final FocusNode balanceFocus, riskFocus, slFocus;
  final bool balanceFocused, riskFocused;

  const _TopBar({
    required this.state,
    required this.balanceController, required this.riskController,
    required this.balanceFocus, required this.riskFocus, required this.slFocus,
    required this.balanceFocused, required this.riskFocused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card(),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(child: _TopField(
            label: 'Balance',
            prefix: '\$',
            controller: balanceController,
            focusNode: balanceFocus,
            focused: balanceFocused,
            align: TextAlign.left,
            onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
            onSubmitted: (_) => riskFocus.requestFocus(),
          )),
          VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
          Expanded(child: _TopField(
            label: 'Risk / Trade',
            prefix: '\$',
            controller: riskController,
            focusNode: riskFocus,
            focused: riskFocused,
            align: TextAlign.right,
            onChanged: (v) => state.setSessionRisk(double.tryParse(v) ?? state.riskAmount),
            onSubmitted: (_) => slFocus.requestFocus(),
          )),
        ]),
      ),
    );
  }
}

class _TopField extends StatelessWidget {
  final String label, prefix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final TextAlign align;
  final ValueChanged<String> onChanged, onSubmitted;

  const _TopField({
    required this.label, required this.prefix, required this.controller,
    required this.focusNode, required this.focused, required this.align,
    required this.onChanged, required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label(
              color: focused ? AppColors.accentLight : AppColors.muted)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: align == TextAlign.right
                ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(prefix, style: AppText.mono(size: 18, weight: FontWeight.w600,
                  color: focused ? AppColors.accentLight : AppColors.muted)),
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
                style: AppText.mono(size: 18, weight: FontWeight.w700,
                    color: focused ? Colors.white : AppColors.text),
                decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              )),
            ],
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.card(),
        child: Text('★ Star instruments to add here',
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
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: isActive ? AppDecor.activeInstrument() : AppDecor.inactiveInstrument(),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(inst.ticker, style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: isActive ? AppColors.accentLight : AppColors.text,
              )),
              const SizedBox(height: 2),
              Text('\$${inst.pointValue}/pt', style: GoogleFonts.manrope(
                fontSize: 10, fontWeight: FontWeight.w500,
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.7) : AppColors.muted,
              )),
            ]),
          ),
        );
      }).toList()),
    );
  }
}

// ── Stop loss hero ─────────────────────────────────────────────────────────
class _StopLossHero extends StatelessWidget {
  final QuantaState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;

  const _StopLossHero({
    required this.state, required this.controller,
    required this.focusNode, required this.focused, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: focused ? AppColors.elevated : AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: focused
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: focused ? [BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 48, offset: const Offset(0, 8),
          )] : null,
        ),
        child: Column(children: [
          // Ticker + label row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: focused ? AppColors.accentLight : AppColors.muted,
              ),
              child: Text(state.currentInstrument.ticker),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: focused
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: focused
                      ? AppColors.accent.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Text('STOP LOSS', style: AppText.label(
                  color: focused ? AppColors.accentLight : AppColors.muted)),
            ),
          ]),
          const SizedBox(height: 16),

          // The big number
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            enableInteractiveSelection: false,
            style: AppText.mono(
              size: 64,
              weight: FontWeight.w600,
              color: focused ? Colors.white : AppColors.text.withValues(alpha: 0.85),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0.0',
              hintStyle: AppText.mono(
                size: 64, weight: FontWeight.w300,
                color: AppColors.muted.withValues(alpha: 0.2),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // pts label + animated underline
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 1.5,
              width: focused ? 80 : 40,
              decoration: BoxDecoration(
                color: focused
                    ? AppColors.accent
                    : AppColors.muted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text('pts', style: AppText.label(
                color: focused ? AppColors.accent : AppColors.muted)),
          ]),
        ]),
      ),
    );
  }
}

// ── Result hero ────────────────────────────────────────────────────────────
class _ResultHero extends StatelessWidget {
  final QuantaState state;
  const _ResultHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasData = state.stopLossPoints > 0;
    return Container(
      width: double.infinity,
      decoration: AppDecor.glowCard(
          glowColor: hasData ? AppColors.accent : AppColors.subtle),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(children: [
        // Contracts — the hero number
        Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              hasData ? '${state.contracts}' : '--',
              key: ValueKey(hasData ? state.contracts : -1),
              style: AppText.mono(
                size: 88,
                weight: FontWeight.w700,
                color: hasData
                    ? Colors.white
                    : AppColors.subtle,
              ),
            ),
          ),
        ]),

        const SizedBox(height: 2),
        Text('contracts',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 2,
            )),

        const SizedBox(height: 20),

        // Divider
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 16),

        // Risk row
        Row(children: [
          _RiskStat(label: 'MAX RISK',
              value: '\$${state.effectiveRisk.toStringAsFixed(0)}',
              color: AppColors.muted),
          _RiskStat(label: 'ACTUAL',
              value: '\$${state.actualRisk.toStringAsFixed(0)}',
              color: AppColors.green),
          _RiskStat(label: 'UNUSED',
              value: '\$${state.unusedRisk.toStringAsFixed(0)}',
              color: AppColors.orange),
        ]),
      ]),
    );
  }
}

class _RiskStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RiskStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: AppText.label(size: 9, color: AppColors.muted)),
      const SizedBox(height: 5),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(value,
          key: ValueKey(value),
          style: AppText.mono(size: 16, weight: FontWeight.w600, color: color),
        ),
      ),
    ]));
  }
}
