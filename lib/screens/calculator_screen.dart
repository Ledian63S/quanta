import 'dart:io';
import 'package:flutter/gestures.dart';
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
  late final TextEditingController _slController;
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
    _slController = TextEditingController(
        text: state.stopLossPoints > 0 ? AppFormat.stopLoss(state.stopLossPoints) : '');
    _riskController = TextEditingController(text: state.riskAmount.toStringAsFixed(0));
    _balanceController = TextEditingController(text: state.accountBalance.toStringAsFixed(0));
    _slFocus.addListener(() => setState(() => _slFocused = _slFocus.hasFocus));
    _riskFocus.addListener(() => setState(() => _riskFocused = _riskFocus.hasFocus));
    _balanceFocus.addListener(() => setState(() => _balanceFocused = _balanceFocus.hasFocus));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<QuantaState>();
    if (!_balanceFocused) {
      final expected = state.accountBalance.toStringAsFixed(0);
      if (_balanceController.text != expected) _balanceController.text = expected;
    }
    if (!_riskFocused) {
      final expected = state.riskIsPercent
          ? state.riskPercent.toStringAsFixed(1)
          : state.effectiveRisk.toStringAsFixed(0);
      if (_riskController.text != expected) _riskController.text = expected;
    }
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
    Theme.of(context); // depend on theme so StatelessWidget children repaint on brightness change
    final state = context.watch<QuantaState>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 72 + keyboardHeight),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Account strip ────────────────────────────────────────
            _AccountStrip(
              state: state,
              balanceController: _balanceController,
              riskController: _riskController,
              balanceFocus: _balanceFocus,
              riskFocus: _riskFocus,
              slFocus: _slFocus,
            ),
            const SizedBox(height: 12),

            // ── Instrument ───────────────────────────────────────────
            Text('INSTRUMENT', style: AppText.label()),
            const SizedBox(height: 8),
            _InstrumentRow(state: state, onChanged: () => _slController.clear()),
            const SizedBox(height: 12),

            // ── Stop loss input ──────────────────────────────────────
            Row(children: [
              Text('STOP LOSS', style: AppText.label()),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ]),
            const SizedBox(height: 8),
            _StopLossPanel(
              controller: _slController,
              focusNode: _slFocus,
              focused: _slFocused,
              ticker: state.currentInstrument.ticker,
              onChanged: (v) {
                final normalized = v.replaceAll(',', '.');
                state.setStopLoss(
                    normalized.isEmpty ? 0 : (double.tryParse(normalized) ?? state.stopLossPoints));
              },
              onAdjust: (delta) {
                final newVal = (state.stopLossPoints + delta).clamp(0.0, double.infinity);
                _slController.text = newVal > 0 ? AppFormat.stopLoss(newVal) : '';
                state.setStopLoss(newVal);
                HapticFeedback.selectionClick();
              },
            ),
            const SizedBox(height: 12),

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

      // Done button — mobile only (desktop uses Tab/Enter to dismiss focus)
      if (!Platform.isMacOS && !Platform.isWindows) Positioned(
        bottom: keyboardHeight > 0 ? keyboardHeight + 12 : 100,
        right: 16,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: (_slFocused || _riskFocused || _balanceFocused) ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !(_slFocused || _riskFocused || _balanceFocused),
            child: Clickable(
              onTap: () {
                HapticFeedback.selectionClick();
                FocusManager.instance.primaryFocus?.unfocus();
              },
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
  const _AccountStrip({
    required this.state,
    required this.balanceController, required this.riskController,
    required this.balanceFocus, required this.riskFocus, required this.slFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card(),
      child: Column(children: [
        _AccountRow(
          label: 'BALANCE',
          prefix: '\$',
          controller: balanceController,
          focusNode: balanceFocus,
          onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
          onSubmitted: (_) => riskFocus.requestFocus(),
        ),
        Container(height: 1, color: AppColors.border),
        _AccountRow(
          label: 'RISK / TRADE',
          prefix: state.riskIsPercent ? '%' : '\$',
          isPercent: state.riskIsPercent,
          controller: riskController,
          focusNode: riskFocus,
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

class _AccountRow extends StatefulWidget {
  final String label, prefix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPercent;
  final ValueChanged<String> onChanged, onSubmitted;
  const _AccountRow({
    required this.label, required this.prefix, required this.controller,
    required this.focusNode,
    required this.onChanged, required this.onSubmitted,
    this.isPercent = false,
  });

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void didUpdateWidget(_AccountRow old) {
    super.didUpdateWidget(old);
    if (old.isPercent != widget.isPercent) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  static String _fmt(String raw) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    return v.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // depend on theme so colors update on brightness change
    final displayText = widget.isPercent
        ? '${widget.controller.text}%'
        : '${widget.prefix}${_fmt(widget.controller.text)}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focused ? null : () {
        setState(() => _focused = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.focusNode.requestFocus();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Text('> ', style: AppText.mono(size: 11,
              color: _focused ? AppColors.accent : AppColors.subtle)),
          Text(widget.label, style: AppText.label(
              size: 10,
              color: _focused ? AppColors.accentLight : AppColors.muted)),
          const Spacer(),
          if (_focused) ...[
            if (!widget.isPercent)
              Text(widget.prefix, style: AppText.mono(size: 20, weight: FontWeight.w600,
                  color: _focused ? AppColors.accent : AppColors.muted)),
            IntrinsicWidth(child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              enableInteractiveSelection: false,
              autofocus: false,
              cursorColor: AppColors.accent,
              style: AppText.mono(size: 20, weight: FontWeight.w600,
                  color: _focused ? AppColors.accentLight : AppColors.text),
              decoration: const InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            )),
            if (widget.isPercent)
              Text('%', style: AppText.mono(size: 20, weight: FontWeight.w600,
                  color: _focused ? AppColors.accent : AppColors.muted)),
          ] else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(displayText,
                key: ValueKey(displayText),
                style: AppText.mono(size: 20, weight: FontWeight.w600,
                    color: AppColors.text)),
            ),
        ]),
      ),
    );
  }
}

// ── Instrument row ─────────────────────────────────────────────────────────
class _InstrumentRow extends StatefulWidget {
  final QuantaState state;
  final VoidCallback onChanged;
  const _InstrumentRow({required this.state, required this.onChanged});
  @override
  State<_InstrumentRow> createState() => _InstrumentRowState();
}

class _InstrumentRowState extends State<_InstrumentRow> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favs = widget.state.favoriteInstruments;
    if (favs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecor.card(),
        child: Text('> STAR INSTRUMENTS TO ADD HERE',
            style: AppText.body(color: AppColors.muted)),
      );
    }
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final pos = _scrollController.position;
          final next = (_scrollController.offset + event.scrollDelta.dy)
              .clamp(pos.minScrollExtent, pos.maxScrollExtent);
          _scrollController.jumpTo(next);
        }
      },
      child: SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(children: favs.map((inst) {
        final isActive = inst.ticker == widget.state.selectedTicker;
        return Clickable(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.state.setInstrument(inst.ticker);
            widget.onChanged();
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
    ));
  }
}

// ── Stop loss panel ────────────────────────────────────────────────────────
class _StopLossPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final String ticker;
  final ValueChanged<String> onChanged;
  final void Function(double delta) onAdjust;
  const _StopLossPanel({
    required this.controller, required this.focusNode,
    required this.focused, required this.ticker,
    required this.onChanged, required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: focused ? AppDecor.focusCard() : AppDecor.card(),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
        const SizedBox(height: 6),

        // Big number input
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.left,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            _CommaToDotFormatter(),
          ],
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
        const SizedBox(height: 8),

        // Quick-adjust buttons
        Row(children: [
          for (final delta in [-1.0, -0.25, 0.25, 1.0]) ...[
            Expanded(child: _AdjustButton(
              label: delta > 0 ? '+${AppFormat.stopLoss(delta)}' : AppFormat.stopLoss(delta),
              onTap: () => onAdjust(delta),
            )),
            if (delta != 1.0) const SizedBox(width: 6),
          ],
        ]),
      ]),
    );
  }
}

class _CommaToDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '.');
    return newValue.copyWith(text: text);
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: AppText.mono(size: 12, weight: FontWeight.w600,
              color: AppColors.muted)),
      ),
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
    final noContracts = hasData && state.contracts == 0;
    final riskPct = state.accountBalance > 0
        ? state.actualRisk / state.accountBalance * 100 : 0.0;

    return Column(children: [
      // Gauge — tap to copy contracts
      Clickable(
        onTap: hasData && !noContracts ? () {
          HapticFeedback.mediumImpact();
          Clipboard.setData(ClipboardData(text: '${state.contracts}'));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${state.contracts} CONTRACTS COPIED',
                style: AppText.label(color: Colors.black)),
            backgroundColor: AppColors.accent,
            duration: const Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          ));
        } : null,
        child: PacManGauge(
          contracts: hasData ? state.contracts : 0,
          hasData: hasData,
        ),
      ),

      // Zero-contracts warning
      if (noContracts) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(children: [
            Text('! ', style: AppText.mono(size: 12,
                weight: FontWeight.w700, color: AppColors.orange)),
            Expanded(child: Text('STOP TOO LARGE — REDUCE SL OR INCREASE RISK',
                style: AppText.label(size: 10, color: AppColors.orange))),
          ]),
        ),
      ],

      const SizedBox(height: 10),
      Container(
        decoration: AppDecor.card(),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(children: [
          _ReadoutRow('MAX RISK',
              AppFormat.dollar(state.effectiveRisk), AppColors.muted),
          const SizedBox(height: 8),
          _ReadoutRow('ACTUAL  ',
              AppFormat.dollar(state.actualRisk), AppColors.green,
              onTap: hasData && !noContracts ? () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(
                    text: AppFormat.dollar(state.actualRisk)));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${AppFormat.dollar(state.actualRisk)} COPIED',
                      style: AppText.label(color: Colors.black)),
                  backgroundColor: AppColors.accent,
                  duration: const Duration(milliseconds: 1200),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                ));
              } : null),
          const SizedBox(height: 8),
          _ReadoutRow('UNUSED  ',
              AppFormat.dollar(state.unusedRisk), AppColors.orange),
          if (hasData && !noContracts) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _ReadoutRow('RISK %  ',
                AppFormat.pct(riskPct), AppColors.muted),
          ],
        ]),
      ),
    ]);
  }
}

class _ReadoutRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final VoidCallback? onTap;
  const _ReadoutRow(this.label, this.value, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Row(children: [
      Text(label, style: AppText.mono(size: 12, color: AppColors.muted)),
      const SizedBox(width: 4),
      const DotLeader(),
      const SizedBox(width: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(value,
          key: ValueKey(value),
          style: AppText.mono(size: 14, weight: FontWeight.w700, color: color),
        ),
      ),
    ]);
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}
