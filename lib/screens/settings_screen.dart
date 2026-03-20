import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _balCtrl;
  late TextEditingController _riskCtrl;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<QuantaState>();
      _balCtrl  = TextEditingController(text: state.accountBalance.toStringAsFixed(0));
      _riskCtrl = TextEditingController(
        text: state.riskIsPercent
            ? state.riskPercent.toStringAsFixed(1)
            : state.riskAmount.toStringAsFixed(0),
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _balCtrl.dispose();
    _riskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Row(children: [
            Text('> ', style: AppText.mono(size: 11, color: AppColors.accent)),
            Text('SETTINGS', style: AppText.label(color: AppColors.accentLight)),
          ]),
          const SizedBox(height: 20),

          // ── ACCOUNT ──────────────────────────────────────────────────
          const _SectionHeader('ACCOUNT'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: Column(children: [
              _InputRow(
                label: 'Balance',
                controller: _balCtrl,
                prefix: '\$',
                onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
              ),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              const _LabelRow(label: 'Currency', value: 'USD'),
            ]),
          ),

          const SizedBox(height: 20),

          // ── RISK ─────────────────────────────────────────────────────
          const _SectionHeader('RISK'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: Column(children: [
              _ToggleRow(
                label: '% of Balance',
                value: state.riskIsPercent,
                onChanged: (v) {
                  state.setRiskIsPercent(v);
                  _riskCtrl.text = v
                      ? state.riskPercent.toStringAsFixed(1)
                      : state.riskAmount.toStringAsFixed(0);
                },
              ),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              _InputRow(
                label: 'Risk / Trade',
                controller: _riskCtrl,
                prefix: state.riskIsPercent ? '%' : '\$',
                isPercent: state.riskIsPercent,
                onChanged: (v) {
                  if (state.riskIsPercent) {
                    final pct = double.tryParse(v) ?? 0;
                    state.setRisk(pct / 100 * state.accountBalance);
                  } else {
                    state.setRisk(double.tryParse(v) ?? state.riskAmount);
                  }
                },
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── PREFERENCES ──────────────────────────────────────────────
          const _SectionHeader('PREFERENCES'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: Column(children: [
              _ToggleRow(label: 'Remember Balance',
                  value: state.rememberBalance, onChanged: state.setRememberBalance),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              _ToggleRow(label: 'Remember Risk',
                  value: state.rememberRisk, onChanged: state.setRememberRisk),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              _ToggleRow(label: 'Remember Instrument',
                  value: state.rememberInstrument, onChanged: state.setRememberInstrument),
            ]),
          ),

          const SizedBox(height: 20),

          // ── APPEARANCE ───────────────────────────────────────────────
          const _SectionHeader('APPEARANCE'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: _AppearanceRow(current: state.themeMode, onChanged: state.setThemeMode),
          ),

          const SizedBox(height: 20),

          // ── ABOUT ────────────────────────────────────────────────────
          const _SectionHeader('ABOUT'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: Column(children: [
              const _LabelRow(label: 'Version', value: '1.0.0'),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              const _LabelRow(label: 'Developer', value: 'Ledian Leka'),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              const _LabelRow(label: 'Website', value: 'ledian63s.github.io',
                  valueColor: AppColors.accentLight),
              Container(height: 1, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              const _LabelRow(label: 'Built by traders, for traders', value: '✦',
                  valueColor: AppColors.accent),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: AppText.label()),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: AppColors.border)),
    ]);
  }
}

// ── Input row ───────────────────────────────────────────────────────────────
class _InputRow extends StatefulWidget {
  final String label, prefix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isPercent;
  const _InputRow({required this.label, required this.controller,
      required this.prefix, required this.onChanged, this.isPercent = false});
  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  static String _fmt(String raw, {bool isPercent = false}) {
    final v = double.tryParse(raw);
    if (v == null) return raw;
    if (isPercent) return v.toStringAsFixed(1);
    return v.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.isPercent
        ? '${_fmt(widget.controller.text, isPercent: true)}%'
        : '${widget.prefix}${_fmt(widget.controller.text)}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focused ? null : () {
        setState(() => _focused = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Text('> ', style: AppText.mono(size: 11, color: AppColors.muted)),
          Text(widget.label, style: AppText.mono(
              size: 13, weight: FontWeight.w500, color: AppColors.text)),
          const SizedBox(width: 4),
          const DotLeader(),
          const SizedBox(width: 4),
          if (_focused) ...[
            if (!widget.isPercent)
              Text(widget.prefix, style: AppText.mono(size: 13,
                  weight: FontWeight.w600, color: AppColors.muted)),
            SizedBox(width: 80, child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              enableInteractiveSelection: false,
              cursorColor: AppColors.accent,
              style: AppText.mono(size: 13, weight: FontWeight.w700,
                  color: AppColors.accentLight),
              decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            )),
            if (widget.isPercent)
              Text('%', style: AppText.mono(size: 13,
                  weight: FontWeight.w600, color: AppColors.muted)),
          ] else
            Text(displayText,
              style: AppText.mono(size: 13, weight: FontWeight.w700,
                  color: AppColors.accentLight)),
        ]),
      ),
    );
  }
}

// ── Label row ───────────────────────────────────────────────────────────────
class _LabelRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _LabelRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Text('> ', style: AppText.mono(size: 11, color: AppColors.subtle)),
        Text(label, style: AppText.mono(
            size: 13, weight: FontWeight.w500, color: AppColors.muted)),
        const SizedBox(width: 4),
        const DotLeader(),
        const SizedBox(width: 4),
        Text(value, style: AppText.mono(size: 13, weight: FontWeight.w700,
            color: valueColor ?? AppColors.text)),
      ]),
    );
  }
}

// ── Toggle row ──────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Text('> ', style: AppText.mono(size: 11, color: AppColors.subtle)),
        Expanded(child: Text(label, style: AppText.mono(
            size: 13, weight: FontWeight.w500, color: AppColors.text))),
        _AppToggle(value: value, onChanged: onChanged),
      ]),
    );
  }
}

// ── Custom amber terminal toggle ─────────────────────────────────────────────
class _AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AppToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48, height: 26,
        decoration: BoxDecoration(
          color: value
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: 3, bottom: 3,
            left: value ? 23 : 3,
            right: value ? 3 : 23,
            child: Container(
              decoration: BoxDecoration(
                color: value ? AppColors.accent : AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Appearance picker ───────────────────────────────────────────────────────
class _AppearanceRow extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _AppearanceRow({required this.current, required this.onChanged});

  static const _options = [
    (ThemeMode.system, 'AUTO'),
    (ThemeMode.light,  'LIGHT'),
    (ThemeMode.dark,   'DARK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: _options.map((opt) {
          final (mode, label) = opt;
          final active = current == mode;
          return Expanded(
            child: Clickable(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(mode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: active
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppText.label(
                    color: active ? AppColors.accent : AppColors.muted,
                  )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
