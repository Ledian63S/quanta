import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

// ── Palette — VOID terminal ────────────────────────────────────────────────────
Color _bg(bool d)   => d ? const Color(0xFF000000) : const Color(0xFFE8E4DF);
Color _card(bool d) => d ? const Color(0xFF0C0C0C) : const Color(0xFFF8F6F3);
Color _text(bool d) => d ? const Color(0xFFF0ECD8) : const Color(0xFF080808);
Color _sub(bool d)  => d ? const Color(0xFF807060) : const Color(0xFF4A4642);
Color _line(bool d) => d ? const Color(0xFF242018) : const Color(0xFFB8B0A6);

// Card shadow — terminal subtle
List<BoxShadow> _shadow(bool d) => d
    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 1))]
    : [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))];

const Color _gold    = Color(0xFFD4AF37);
const Color _goldLt  = Color(0xFFF0CC60);
const Color _green   = Color(0xFF4ADE80);
const Color _red     = Color(0xFFFF6B35);

// Keep _blue alias for any remaining references
const Color _blue = _gold;

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
        color: AppColors.bg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [


            // ── Balance + Risk — single stacked card (matches mobile)
            _AccountStrip(
              state: state,
              balCtrl: _balCtrl,
              riskCtrl: _riskCtrl,
              balFocus: _balFocus,
              riskFocus: _riskFocus,
              slFocus: _slFocus,
              balFocused: _balFocused,
              riskFocused: _riskFocused,
              isDark: d,
            ),
            const SizedBox(height: 12),

            // ── Instrument row (horizontal scroll pills, matches mobile)
            _SectionLabel('Instrument', d),
            const SizedBox(height: 8),
            _InstrumentRow(state: state, isDark: d),
            const SizedBox(height: 12),

            // ── Stop loss
            _SectionLabel('Stop Loss', d),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),

            // ── Result
            Row(children: [
              _SectionLabel('Result', d),
              const Spacer(),
              if (state.hasSessionContracts) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text('MANUAL', style: AppText.mono(
                    size: 9, weight: FontWeight.w600, color: _blue,
                  )),
                ),
              ],
            ]),
            const SizedBox(height: 8),
            _ResultPanel(state: state, isDark: d),
          ]),
        ),
      ),
    );
  }
}

// ── Section label — matches mobile AppText.label() ────────────────────────────
Widget _SectionLabel(String text, bool isDark) => Text(text.toUpperCase(),
  style: AppText.label(),
);

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5) : null,
        boxShadow: _shadow(isDark),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              hasData
                  ? '$contracts contract${contracts == 1 ? '' : 's'} at ${AppFormat.pct(ratio * 100)} of max risk'
                  : 'Enter your stop loss to calculate',
              style: AppText.mono(
                size: 13, weight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            // Progress bar (matches reference)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 4,
                color: AppColors.border,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text(AppFormat.dollar(state.actualRisk),
                style: AppText.mono(
                  size: 12, weight: FontWeight.w700,
                  color: AppColors.text,
                )),
              Text(' / ${AppFormat.dollar(state.effectiveRisk)}',
                style: AppText.mono(
                  size: 12, color: AppColors.muted,
                )),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        // Blue circle icon
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('#', style: AppText.mono(
              size: 20, color: _blue, weight: FontWeight.w700,
            )),
          ),
        ),
      ]),
    );
  }
}

// ── Account strip — single card, balance + risk stacked with divider ──────────
class _AccountStrip extends StatelessWidget {
  final QuantaState state;
  final TextEditingController balCtrl, riskCtrl;
  final FocusNode balFocus, riskFocus, slFocus;
  final bool balFocused, riskFocused, isDark;

  const _AccountStrip({
    required this.state,
    required this.balCtrl, required this.riskCtrl,
    required this.balFocus, required this.riskFocus, required this.slFocus,
    required this.balFocused, required this.riskFocused,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: _shadow(isDark),
      ),
      child: Column(children: [
        _AccountRow(
          label: 'Balance',
          prefix: '\$',
          controller: balCtrl,
          focusNode: balFocus,
          focused: balFocused,
          isDark: isDark,
          onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
          onSubmitted: (_) => riskFocus.requestFocus(),
        ),
        Container(height: 1, color: AppColors.border),
        _AccountRow(
          label: state.riskIsPercent ? 'Risk %' : 'Risk / trade',
          prefix: state.riskIsPercent ? '' : '\$',
          suffix: state.riskIsPercent ? '%' : '',
          controller: riskCtrl,
          focusNode: riskFocus,
          focused: riskFocused,
          isDark: isDark,
          onChanged: (v) {
            if (state.riskIsPercent) {
              final pct = double.tryParse(v) ?? 0;
              state.setSessionRisk(pct / 100 * state.accountBalance);
            } else {
              state.setSessionRisk(double.tryParse(v) ?? state.riskAmount);
            }
          },
          onSubmitted: (_) => slFocus.requestFocus(),
        ),
      ]),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label, prefix;
  final String suffix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused, isDark;
  final ValueChanged<String> onChanged, onSubmitted;

  const _AccountRow({
    required this.label, required this.prefix,
    required this.controller, required this.focusNode,
    required this.focused, required this.isDark,
    required this.onChanged, required this.onSubmitted,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focused ? null : () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) focusNode.requestFocus();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Text('> ', style: AppText.mono(size: 11,
              color: focused ? AppColors.accent : AppColors.subtle)),
          Text(label.toUpperCase(), style: AppText.label(
              size: 10,
              color: focused ? AppColors.accentLight : AppColors.muted)),
          const Spacer(),
          if (prefix.isNotEmpty)
            Text(prefix, style: AppText.mono(size: 14, weight: FontWeight.w600,
              color: focused ? AppColors.accent : AppColors.muted)),
          IntrinsicWidth(child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.next,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            enableInteractiveSelection: false,
            cursorColor: AppColors.accent,
            style: AppText.mono(size: 14, weight: FontWeight.w600,
              color: focused ? AppColors.accentLight : AppColors.text),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true, contentPadding: EdgeInsets.zero,
              hintText: '0',
              hintStyle: AppText.mono(size: 14, weight: FontWeight.w300,
                color: AppColors.muted.withValues(alpha: 0.3)),
            ),
          )),
          if (suffix.isNotEmpty)
            Text(suffix, style: AppText.mono(size: 14, weight: FontWeight.w600,
              color: focused ? AppColors.accent : AppColors.muted)),
        ]),
      ),
    );
  }
}

// ── Instrument row — horizontal scroll pills (matches mobile) ─────────────────
class _InstrumentRow extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _InstrumentRow({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final favs = state.favoriteInstruments;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
          boxShadow: _shadow(isDark),
        ),
        child: Text('Star instruments in Markets to add here',
          style: AppText.mono(size: 13, color: AppColors.muted)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: favs.map((inst) {
        final active = inst.ticker == state.selectedTicker;
        return GestureDetector(
          onTap: () => state.setInstrument(inst.ticker),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.1)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.border),
                  width: active ? 1.5 : 1,
                ),
                boxShadow: active ? null : _shadow(isDark),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(inst.ticker, style: AppText.mono(
                  size: 13, weight: FontWeight.w700,
                  color: active ? AppColors.accent : AppColors.text,
                )),
                const SizedBox(width: 6),
                Text('\$${inst.pointValue}', style: AppText.label(
                  size: 9,
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.6)
                      : AppColors.muted,
                )),
              ]),
            ),
          ),
        );
      }).toList()),
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
      child: AnimatedScale(
        scale: focused ? 1.005 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: focused
              ? Border.all(color: _blue, width: 1.5)
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.border,
                  width: 1,
                ),
          boxShadow: focused ? null : _shadow(isDark),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.mono(
            size: 10, weight: FontWeight.w500,
            color: focused ? _blue : AppColors.muted,
          )),
          const SizedBox(height: 4),
          Row(children: [
            if (prefix.isNotEmpty)
              Text(prefix, style: AppText.mono(
                size: 14, weight: FontWeight.w600,
                color: focused ? _blue : AppColors.text,
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
                cursorColor: _blue,
                style: AppText.mono(
                  size: 14, weight: FontWeight.w600,
                  color: focused ? AppColors.accentLight : AppColors.text,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true, contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: AppText.mono(
                    size: 14, weight: FontWeight.w300,
                    color: AppColors.border,
                  ),
                ),
              ),
            ),
            if (suffix.isNotEmpty)
              Text(suffix, style: AppText.mono(
                size: 14, weight: FontWeight.w600,
                color: focused ? _blue : AppColors.text,
              )),
          ]),
        ]),
        ),   // AnimatedContainer
      ),     // AnimatedScale
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
    return AnimatedScale(
      scale: focused ? 1.005 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: focused
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.7), width: 1)
            : Border.all(color: AppColors.border, width: 1),
        boxShadow: focused ? null : _shadow(isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('> ', style: AppText.mono(size: 12,
              color: focused ? AppColors.accent : AppColors.muted)),
          Text('$ticker  ', style: AppText.mono(size: 12,
              color: focused ? AppColors.accentLight : AppColors.subtle)),
          const Spacer(),
          Text('PTS', style: AppText.label(
              color: focused ? AppColors.accent : AppColors.muted)),
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
          cursorColor: AppColors.accent, cursorWidth: 2,
          style: AppText.mono(
            size: 22, weight: FontWeight.w700,
            color: focused ? AppColors.accent : AppColors.text,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '0.0',
            hintStyle: AppText.mono(
              size: 22, weight: FontWeight.w300,
              color: AppColors.muted.withValues(alpha: 0.3),
            ),
            isDense: true, contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 8),
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
      ]),      // AnimatedContainer
    ),         // AnimatedScale
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
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E5EA))
                : _bg(widget.isDark),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(widget.label,
            textAlign: TextAlign.center,
            style: AppText.mono(size: 12, weight: FontWeight.w600,
              color: _hovered ? AppColors.text : AppColors.muted),
          ),
        ),  // AnimatedContainer
        ),  // AnimatedScale
      ),
    );
  }
}

// ── Result panel — matches mobile layout exactly ──────────────────────────────
class _ResultPanel extends StatelessWidget {
  final QuantaState state;
  final bool isDark;
  const _ResultPanel({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasData  = state.stopLossPoints > 0;
    final noCont   = hasData && state.effectiveContracts == 0;
    final isOver   = hasData && state.isOverRisk;
    final riskPct  = state.accountBalance > 0
        ? state.actualRisk / state.accountBalance * 100
        : 0.0;

    return Column(children: [

      // Contracts +/- row (bare, no card wrapper)
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ContractBtn('−',
          enabled: hasData && state.effectiveContracts > 0,
          onTap: () => state.setSessionContracts(state.effectiveContracts - 1),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onDoubleTap: state.hasSessionContracts
              ? () => state.resetSessionContracts()
              : null,
          child: ContractsOdometer(
            contracts: hasData ? state.effectiveContracts : 0,
            hasData: hasData,
            digitSize: 56,
          ),
        ),
        const SizedBox(width: 20),
        _ContractBtn('+',
          enabled: hasData,
          onTap: () => state.setSessionContracts(state.effectiveContracts + 1),
        ),
      ]),

      // Zero-contracts warning
      if (noCont) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _red.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: _red),
            const SizedBox(width: 8),
            Expanded(child: Text('Stop too large — reduce SL or increase risk',
              style: AppText.mono(
                size: 11, weight: FontWeight.w500, color: _red,
              ))),
          ]),
        ),
      ],

      const SizedBox(height: 10),

      // Readout card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: _shadow(isDark),
        ),
        child: Column(children: [
          _BRow('MAX RISK', AppFormat.dollar(state.effectiveRisk),
              AppColors.muted, isDark),
          const SizedBox(height: 8),
          _BRow('ACTUAL', AppFormat.dollar(state.actualRisk),
              hasData && !noCont ? (isOver ? _red : _green) : AppColors.muted,
              isDark),
          if (isOver) ...[
            const SizedBox(height: 8),
            _BRow('OVER', '+${AppFormat.dollar(state.overRisk)}', _red, isDark),
          ],
          if (hasData && !noCont) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _BRow('RISK %', AppFormat.pct(riskPct), AppColors.muted, isDark),
          ],
        ]),
      ),
    ]);
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5) : null,
        boxShadow: _shadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          // Subtle blue radial glow — top-right corner
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accent.withValues(alpha: hasData && !noCont
                      ? (isDark ? 0.12 : 0.08)
                      : 0.02),
                  AppColors.accent.withValues(alpha: 0),
                ]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // "AI Chatbot" style pill — our "Contracts" badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calculate_outlined, size: 14, color: _blue),
                    const SizedBox(width: 6),
                    Text('Contracts', style: AppText.mono(
                      size: 13, weight: FontWeight.w600,
                      color: _blue,
                    )),
                    if (state.hasSessionContracts) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('manual', style: AppText.mono(
                          size: 9, weight: FontWeight.w600,
                          color: _blue,
                        )),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Number + controls
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
                    digitSize: 56,
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
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: Text('Stop too large — reduce SL or increase risk',
                    textAlign: TextAlign.center,
                    style: AppText.mono(
                      size: 11, weight: FontWeight.w500, color: _red,
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
        width: 40, height: 40,
        child: Center(
          child: Text(widget.label, style: AppText.mono(
            size: 22, weight: FontWeight.w300,
            color: widget.enabled
                ? AppColors.muted
                : AppColors.subtle.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5) : null,
        boxShadow: _shadow(isDark),
      ),
      child: Column(children: [
        _BRow('Max risk',  AppFormat.dollar(state.effectiveRisk),
            AppColors.muted, isDark),
        const SizedBox(height: 10),
        _BRow(
          'Actual',
          AppFormat.dollar(state.actualRisk),
          hasData && !noCont ? (isOver ? _red : _green) : AppColors.muted,
          isDark,
        ),
        if (isOver) ...[
          const SizedBox(height: 10),
          _BRow('Over', '+${AppFormat.dollar(state.overRisk)}', _red, isDark),
        ],
        if (hasData && !noCont) ...[
          const SizedBox(height: 14),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          // Two mini stat cards like reference's "Running 120kcal / Push up 200kcal"
          Row(children: [
            Expanded(child: _MiniStat(
              label: 'Risk %',
              value: AppFormat.pct(riskPct),
              color: AppColors.text,
              isDark: isDark,
            )),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(
              label: 'Stop loss',
              value: '${AppFormat.stopLoss(state.stopLossPoints)} pts',
              color: AppColors.text,
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
      Text(label, style: AppText.label(size: 10)),
      const SizedBox(width: 4),
      const DotLeader(),
      const SizedBox(width: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(value,
          key: ValueKey(value),
          style: AppText.mono(
            size: 13, weight: FontWeight.w700, color: color,
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(4),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.mono(
          size: 11, color: AppColors.muted, weight: FontWeight.w500,
        )),
        const SizedBox(height: 4),
        Text(value, style: AppText.mono(
          size: 14, weight: FontWeight.w700, color: color,
        )),
      ]),
    );
  }
}
