import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

// ── Palette matching reference exactly ───────────────────────────────────────
// Light mode: content bg = #F2F2F2, cards = #FFFFFF with shadow
// Dark mode: content bg = #141414, cards = #1E1E1E
Color _bg(bool d)   => d ? const Color(0xFF141414) : const Color(0xFFF2F2F2);
Color _card(bool d) => d ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
Color _text(bool d) => d ? const Color(0xFFEEEEEE) : const Color(0xFF111111);
Color _sub(bool d)  => d ? const Color(0xFF888888) : const Color(0xFF999999);
Color _line(bool d) => d ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

// Card shadow — subtle lift
List<BoxShadow> _shadow(bool d) => d
    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))]
    : [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8,  offset: const Offset(0, 3)),
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2,  offset: const Offset(0, 1)),
      ];

const Color _gold    = Color(0xFFD4AF37);
const Color _goldLt  = Color(0xFFE8C84A);
const Color _green   = Color(0xFF4ADE80);
const Color _red     = Color(0xFFFF6B35);

// ── Screen ────────────────────────────────────────────────────────────────────
class WebCalcScreen extends StatefulWidget {
  const WebCalcScreen({super.key});
  @override
  State<WebCalcScreen> createState() => _WebCalcScreenState();
}

class _WebCalcScreenState extends State<WebCalcScreen> {
  late TextEditingController _slCtrl, _riskCtrl, _balCtrl;
  final _slFocus   = FocusNode();
  final _riskFocus = FocusNode();
  final _balFocus  = FocusNode();
  bool _slFocused = false, _riskFocused = false, _balFocused = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<QuantaState>();
    _slCtrl   = TextEditingController(
        text: s.stopLossPoints > 0 ? AppFormat.stopLoss(s.stopLossPoints) : '');
    _riskCtrl = TextEditingController(text: s.riskAmount.toStringAsFixed(0));
    _balCtrl  = TextEditingController(text: s.accountBalance.toStringAsFixed(0));
    _slFocus  .addListener(() => setState(() => _slFocused   = _slFocus.hasFocus));
    _riskFocus.addListener(() => setState(() => _riskFocused = _riskFocus.hasFocus));
    _balFocus .addListener(() => setState(() => _balFocused  = _balFocus.hasFocus));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<QuantaState>();
    if (!_balFocused) {
      final v = s.accountBalance.toStringAsFixed(0);
      if (_balCtrl.text != v) _balCtrl.text = v;
    }
    if (!_riskFocused) {
      final v = s.riskIsPercent
          ? s.riskPercent.toStringAsFixed(1)
          : s.effectiveRisk.toStringAsFixed(0);
      if (_riskCtrl.text != v) _riskCtrl.text = v;
    }
  }

  @override
  void dispose() {
    _slCtrl.dispose(); _riskCtrl.dispose(); _balCtrl.dispose();
    _slFocus.dispose(); _riskFocus.dispose(); _balFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final d = AppColors.isDark;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: _bg(d),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Left column ───────────────────────────────────────────────────
          Expanded(
            flex: 58,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 32, 20, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Big heading — matches "Let's start strong!" from reference
                Text('Position\nSize.',
                  style: GoogleFonts.inter(
                    fontSize: 44, fontWeight: FontWeight.w800,
                    color: _text(d), height: 1.05, letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Enter your balance, risk and stop loss to calculate position size.',
                  style: GoogleFonts.inter(
                    fontSize: 13, color: _sub(d),
                    fontWeight: FontWeight.w400, height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // ── "You're set up" progress-style card (matches reference top card)
                _GoalCard(state: state, isDark: d),
                const SizedBox(height: 20),

                // ── Instrument row (matches reference's circular action buttons)
                Text('Instrument', style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _text(d),
                )),
                const SizedBox(height: 12),
                _InstrumentRow(state: state, isDark: d),
                const SizedBox(height: 24),

                // ── "Summary" section (matches reference)
                Row(children: [
                  Text('Inputs', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _text(d),
                  )),
                ]),
                const SizedBox(height: 14),

                // Balance + Risk — two cards side by side
                Row(children: [
                  Expanded(child: _InputCard(
                    label: 'Account balance',
                    prefix: '\$',
                    controller: _balCtrl,
                    focusNode: _balFocus,
                    focused: _balFocused,
                    isDark: d,
                    onChanged: (v) =>
                        state.setBalance(double.tryParse(v) ?? state.accountBalance),
                    onSubmitted: (_) => _riskFocus.requestFocus(),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _InputCard(
                    label: state.riskIsPercent ? 'Risk %' : 'Risk / trade',
                    prefix: state.riskIsPercent ? '' : '\$',
                    suffix: state.riskIsPercent ? '%' : '',
                    controller: _riskCtrl,
                    focusNode: _riskFocus,
                    focused: _riskFocused,
                    isDark: d,
                    onChanged: (v) {
                      if (state.riskIsPercent) {
                        final pct = double.tryParse(v) ?? 0;
                        state.setSessionRisk(pct / 100 * state.accountBalance);
                      } else {
                        state.setSessionRisk(
                            double.tryParse(v) ?? state.riskAmount);
                      }
                    },
                    onSubmitted: (_) => _slFocus.requestFocus(),
                  )),
                ]),
                const SizedBox(height: 12),

                // Stop loss — full width card
                _StopLossCard(
                  controller: _slCtrl,
                  focusNode: _slFocus,
                  focused: _slFocused,
                  isDark: d,
                  ticker: state.currentInstrument.ticker,
                  steps: state.currentInstrument.steps,
                  onChanged: (v) {
                    final n = v.replaceAll(',', '.');
                    state.setStopLoss(
                        n.isEmpty ? 0 : (double.tryParse(n) ?? state.stopLossPoints));
                  },
                  onAdjust: (delta) {
                    final nv = (state.stopLossPoints + delta).clamp(0.0, double.infinity);
                    _slCtrl.text = nv > 0 ? AppFormat.stopLoss(nv) : '';
                    state.setStopLoss(nv);
                  },
                ),
              ]),
            ),
          ),

          // ── Right column ──────────────────────────────────────────────────
          Expanded(
            flex: 42,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 32, 32, 32),
              child: Column(children: [
                // Orange glow "AI Chatbot" style — our Contracts hero
                _ContractsHero(state: state, isDark: d),
                const SizedBox(height: 16),
                _RiskBreakdown(state: state, isDark: d),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Goal card — matches reference "You're 45% to your daily goal" card ────────
class _GoalCard extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _GoalCard({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasData = state.stopLossPoints > 0;
    final contracts = hasData ? state.effectiveContracts : 0;
    final ratio = hasData && state.accountBalance > 0
        ? (state.actualRisk / state.effectiveRisk).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: _shadow(isDark),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              hasData
                  ? '$contracts contract${contracts == 1 ? '' : 's'} at ${AppFormat.pct(ratio * 100)} of max risk'
                  : 'Enter your stop loss to calculate',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: _text(isDark), height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Progress bar (matches reference)
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                height: 6,
                color: _line(isDark),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(AppFormat.dollar(state.actualRisk),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _text(isDark),
                )),
              Text(' / ${AppFormat.dollar(state.effectiveRisk)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13, color: _sub(isDark),
                )),
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        // Gold circle icon (matches reference orange lightning bolt circle)
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                blurRadius: 16, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('#', style: TextStyle(
              fontSize: 20, color: Colors.black, fontWeight: FontWeight.w800,
            )),
          ),
        ),
      ]),
    );
  }
}

// ── Instrument row — mini cards with arc ring (like "Push up 200kcal" card) ───
class _InstrumentRow extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _InstrumentRow({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final favs = state.favoriteInstruments;
    if (favs.isEmpty) {
      return Text('No instruments — add in Markets',
        style: GoogleFonts.inter(fontSize: 13, color: _sub(isDark)));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: favs.take(6).map((inst) {
        final active = inst.ticker == state.selectedTicker;
        return GestureDetector(
          onTap: () => state.setInstrument(inst.ticker),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 130, height: 68,
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: _card(isDark),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? _gold.withValues(alpha: 0.55)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.07)),
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 10, offset: const Offset(0, 3),
                  ),
                ] : _shadow(isDark),
              ),
              child: Row(children: [
                // Left: label + ticker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inst.name.length > 12
                            ? inst.name.substring(0, 12)
                            : inst.name,
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: active ? _gold : _sub(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(inst.ticker,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: active ? _text(isDark) : _sub(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: circular arc ring
                SizedBox(
                  width: 36, height: 36,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 36, height: 36,
                      child: CircularProgressIndicator(
                        value: active ? 0.72 : 0.25,
                        strokeWidth: 4.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: active
                            ? _gold.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08)),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          active ? _gold : _sub(isDark),
                        ),
                      ),
                    ),
                    Text(
                      inst.ticker.substring(0, 1),
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: active ? _gold : _sub(isDark),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Input card ────────────────────────────────────────────────────────────────
class _InputCard extends StatelessWidget {
  final String label, prefix, suffix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused, isDark;
  final ValueChanged<String> onChanged, onSubmitted;

  const _InputCard({
    required this.label, required this.prefix,
    required this.controller, required this.focusNode,
    required this.focused, required this.isDark,
    required this.onChanged, required this.onSubmitted,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!focused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) focusNode.requestFocus();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: focused
              ? Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5)
              : (isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null),
          boxShadow: focused ? [] : _shadow(isDark),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: focused ? _gold : _sub(isDark),
          )),
          const SizedBox(height: 6),
          Row(children: [
            if (prefix.isNotEmpty)
              Text(prefix, style: GoogleFonts.jetBrainsMono(
                fontSize: 22, fontWeight: FontWeight.w600,
                color: focused ? _gold : _text(isDark),
              )),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                enableInteractiveSelection: false,
                cursorColor: _gold,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22, fontWeight: FontWeight.w600,
                  color: focused ? _goldLt : _text(isDark),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true, contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 22, fontWeight: FontWeight.w300,
                    color: _line(isDark),
                  ),
                ),
              ),
            ),
            if (suffix.isNotEmpty)
              Text(suffix, style: GoogleFonts.jetBrainsMono(
                fontSize: 22, fontWeight: FontWeight.w600,
                color: focused ? _gold : _text(isDark),
              )),
          ]),
        ]),
      ),
    );
  }
}

// ── Stop loss card ────────────────────────────────────────────────────────────
class _StopLossCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused, isDark;
  final String ticker;
  final List<double> steps;
  final ValueChanged<String> onChanged;
  final void Function(double) onAdjust;

  const _StopLossCard({
    required this.controller, required this.focusNode,
    required this.focused, required this.isDark,
    required this.ticker, required this.steps,
    required this.onChanged, required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final deltas = [-steps[1], -steps[0], steps[0], steps[1]];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: focused
            ? Border.all(color: _gold.withValues(alpha: 0.5), width: 1.5)
            : (isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null),
        boxShadow: focused ? [] : _shadow(isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Stop loss', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: focused ? _gold : _sub(isDark),
          )),
          const Spacer(),
          Text('$ticker · pts', style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w400,
            color: focused ? _gold.withValues(alpha: 0.6) : _sub(isDark),
          )),
        ]),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: TextInputAction.done,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          enableInteractiveSelection: false,
          cursorColor: _gold, cursorWidth: 2.5,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 46, fontWeight: FontWeight.w700,
            color: focused ? _gold : _text(isDark), height: 1.1,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '—',
            hintStyle: GoogleFonts.jetBrainsMono(
              fontSize: 46, fontWeight: FontWeight.w200,
              color: _line(isDark), height: 1.1,
            ),
            isDense: true, contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          for (int i = 0; i < deltas.length; i++) ...[
            Expanded(child: _StepBtn(
              label: deltas[i] > 0
                  ? '+${AppFormat.stopLoss(deltas[i])}'
                  : AppFormat.stopLoss(deltas[i]),
              isDark: isDark,
              onTap: () => onAdjust(deltas[i]),
            )),
            if (i < deltas.length - 1) const SizedBox(width: 6),
          ],
        ]),
      ]),
    );
  }
}

class _StepBtn extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _StepBtn({required this.label, required this.isDark, required this.onTap});
  @override
  State<_StepBtn> createState() => _StepBtnState();
}
class _StepBtnState extends State<_StepBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? _gold.withValues(alpha: 0.1) : _bg(widget.isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? _gold.withValues(alpha: 0.4) : _line(widget.isDark),
            ),
          ),
          child: Text(widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: _hovered ? _gold : _sub(widget.isDark),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Contracts hero — matches reference "AI Chatbot" pill + glow ───────────────
class _ContractsHero extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _ContractsHero({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasData = state.stopLossPoints > 0;
    final noCont  = hasData && state.effectiveContracts == 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: _shadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          // Radial gold glow — top-right corner, matches reference orange glow
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _gold.withValues(alpha: hasData && !noCont
                      ? (isDark ? 0.22 : 0.15)
                      : 0.04),
                  _gold.withValues(alpha: 0),
                ]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // "AI Chatbot" style pill — our "Contracts" badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFF9E7C1A)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('#', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: Colors.black,
                    )),
                    const SizedBox(width: 6),
                    Text('Contracts', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.black,
                    )),
                    if (state.hasSessionContracts) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('MANUAL', style: GoogleFonts.inter(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: Colors.black,
                        )),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Number + controls — matches reference's big result display
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ContractBtn('−',
                  enabled: hasData && state.effectiveContracts > 0,
                  onTap: () => state.setSessionContracts(state.effectiveContracts - 1),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onDoubleTap: state.hasSessionContracts
                      ? () => state.resetSessionContracts()
                      : null,
                  child: ContractsOdometer(
                    contracts: hasData ? state.effectiveContracts : 0,
                    hasData: hasData,
                  ),
                ),
                const SizedBox(width: 16),
                _ContractBtn('+',
                  enabled: hasData,
                  onTap: () => state.setSessionContracts(state.effectiveContracts + 1),
                ),
              ]),
              const SizedBox(height: 8),

              if (noCont) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: Text('Stop too large — reduce SL or increase risk',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w500, color: _red,
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ContractBtn extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ContractBtn(this.label, {required this.enabled, required this.onTap});
  @override
  State<_ContractBtn> createState() => _ContractBtnState();
}
class _ContractBtnState extends State<_ContractBtn> {
  Timer? _timer;
  void _start() {
    widget.onTap();
    _timer = Timer.periodic(
        const Duration(milliseconds: 120), (_) { if (mounted) widget.onTap(); });
  }
  void _stop() { _timer?.cancel(); _timer = null; }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPressStart: widget.enabled ? (_) => _start() : null,
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: SizedBox(
        width: 48, height: 48,
        child: Center(
          child: Text(widget.label, style: GoogleFonts.jetBrainsMono(
            fontSize: 26, fontWeight: FontWeight.w300,
            color: widget.enabled
                ? _gold.withValues(alpha: 0.7)
                : _line(AppColors.isDark),
          )),
        ),
      ),
    );
  }
}

// ── Risk breakdown — matches reference's data card rows ───────────────────────
class _RiskBreakdown extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _RiskBreakdown({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasData = state.stopLossPoints > 0;
    final noCont  = hasData && state.effectiveContracts == 0;
    final isOver  = hasData && state.isOverRisk;
    final riskPct = state.accountBalance > 0
        ? state.actualRisk / state.accountBalance * 100
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: _shadow(isDark),
      ),
      child: Column(children: [
        _BRow('Max risk',  AppFormat.dollar(state.effectiveRisk),
            _sub(isDark), isDark),
        const SizedBox(height: 10),
        _BRow(
          'Actual',
          AppFormat.dollar(state.actualRisk),
          hasData && !noCont ? (isOver ? _red : _green) : _sub(isDark),
          isDark,
        ),
        if (isOver) ...[
          const SizedBox(height: 10),
          _BRow('Over', '+${AppFormat.dollar(state.overRisk)}', _red, isDark),
        ],
        if (hasData && !noCont) ...[
          const SizedBox(height: 14),
          Divider(color: _line(isDark), height: 1),
          const SizedBox(height: 14),
          // Two mini stat cards like reference's "Running 120kcal / Push up 200kcal"
          Row(children: [
            Expanded(child: _MiniStat(
              label: 'Risk %',
              value: AppFormat.pct(riskPct),
              color: _text(isDark),
              isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(
              label: 'Stop loss',
              value: '${AppFormat.stopLoss(state.stopLossPoints)} pts',
              color: _text(isDark),
              isDark: isDark,
            )),
          ]),
        ],
      ]),
    );
  }
}

class _BRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _BRow(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: _sub(isDark),
      )),
      const Spacer(),
      Text(value, style: GoogleFonts.jetBrainsMono(
        fontSize: 14, fontWeight: FontWeight.w700, color: color,
      )),
    ]);
  }
}

// Mini stat card — matches reference "Running 120kcal" mini cards
class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _MiniStat({required this.label, required this.value,
      required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: _sub(isDark), fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.jetBrainsMono(
          fontSize: 14, fontWeight: FontWeight.w700, color: color,
        )),
      ]),
    );
  }
}
