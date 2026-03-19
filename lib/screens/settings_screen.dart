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
      _riskCtrl = TextEditingController(text: state.riskAmount.toStringAsFixed(0));
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
          _Section(title: 'ACCOUNT', children: [
            _InputRow(
              label: 'Account Balance',
              subtitle: 'Your trading account size',
              controller: _balCtrl,
              prefix: '\$',
              onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
            ),
            _Divider(),
            const _LabelRow(label: 'Currency', value: 'USD'),
          ]),
          const SizedBox(height: 24),
          _Section(title: 'RISK', children: [
            _InputRow(
              label: 'Risk per Trade',
              subtitle: 'Fixed USD amount',
              controller: _riskCtrl,
              prefix: '\$',
              onChanged: (v) => state.setRisk(double.tryParse(v) ?? state.riskAmount),
            ),
          ]),
          const SizedBox(height: 24),
          _Section(title: 'PREFERENCES', children: [
            _ToggleRow(label: 'Remember Balance',    value: state.rememberBalance,    onChanged: state.setRememberBalance),
            _Divider(),
            _ToggleRow(label: 'Remember Risk',       value: state.rememberRisk,       onChanged: state.setRememberRisk),
            _Divider(),
            _ToggleRow(label: 'Remember Instrument', value: state.rememberInstrument, onChanged: state.setRememberInstrument),
          ]),
          const SizedBox(height: 24),
          _Section(title: 'APPEARANCE', children: [
            _AppearanceRow(current: state.themeMode, onChanged: state.setThemeMode),
          ]),
          const SizedBox(height: 24),
          _Section(title: 'ABOUT', children: [
            const _LabelRow(label: 'Version', value: '1.0.0'),
            _Divider(),
            _LabelRow(label: 'Built for Quantower', value: '✦',
                valueColor: AppColors.accent),
          ]),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(title, style: AppText.label()),
      ),
      Container(
        decoration: AppDecor.card(radius: 16),
        child: Column(children: children),
      ),
    ]);
  }
}

class _InputRow extends StatelessWidget {
  final String label, subtitle, prefix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _InputRow({required this.label, required this.subtitle, required this.controller,
      required this.prefix, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.body(size: 11, color: AppColors.muted)),
        ])),
        Row(children: [
          Text(prefix, style: AppText.mono(size: 15, weight: FontWeight.w600, color: AppColors.muted)),
          SizedBox(width: 90, child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            enableInteractiveSelection: false,
            style: AppText.mono(size: 15, weight: FontWeight.w600, color: AppColors.accentLight),
            decoration: const InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          )),
        ]),
      ]),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _LabelRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.text)),
        Text(value, style: AppText.body(size: 13, weight: FontWeight.w700,
            color: valueColor ?? AppColors.accentLight)),
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.text)),
        Switch.adaptive(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border,
        margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}

class _AppearanceRow extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _AppearanceRow({required this.current, required this.onChanged});

  static const _options = [
    (ThemeMode.system,  'Auto'),
    (ThemeMode.light,   'Light'),
    (ThemeMode.dark,    'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(3),
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
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: active
                        ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 12, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(label,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      size: 13,
                      weight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.muted,
                    )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
