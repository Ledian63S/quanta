import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LogoRow(subtitle: 'Settings'),
          _Section(title: 'Account', children: [
            _InputRow(
              label: 'Account Balance',
              subtitle: 'Your trading account size',
              controller: _balCtrl,
              prefix: '',
              suffix: '',
              onChanged: (v) => state.setBalance(double.tryParse(v) ?? state.accountBalance),
            ),
            _DividerLine(),
            _LabelRow(label: 'Currency', value: 'USD ›'),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'Risk', children: [
            _InputRow(
              label: 'Risk per Trade',
              subtitle: 'Fixed USD amount',
              controller: _riskCtrl,
              prefix: '\$',
              suffix: '',
              onChanged: (v) => state.setRisk(double.tryParse(v) ?? state.riskAmount),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'Preferences', children: [
            _ToggleRow(label: 'Remember Balance',    value: state.rememberBalance,    onChanged: state.setRememberBalance),
            _DividerLine(),
            _ToggleRow(label: 'Remember Risk',       value: state.rememberRisk,       onChanged: state.setRememberRisk),
            _DividerLine(),
            _ToggleRow(label: 'Remember Instrument', value: state.rememberInstrument, onChanged: state.setRememberInstrument),
          ]),
          const SizedBox(height: 20),
          _Section(title: 'About', children: [
            _LabelRow(label: 'Version', value: '1.0.0'),
            _DividerLine(),
            _LabelRow(label: 'Built for Quantower', value: '✦', valueColor: AppColors.accent),
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
      Text(title, style: AppText.label(color: AppColors.muted)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _InputRow extends StatelessWidget {
  final String label, subtitle, prefix, suffix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _InputRow({required this.label, required this.subtitle, required this.controller, required this.prefix, required this.suffix, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.text)),
          Text(subtitle, style: AppText.body(size: 10, color: AppColors.muted)),
        ])),
        Row(children: [
          if (prefix.isNotEmpty) Text(prefix, style: AppText.body(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
          SizedBox(width: 90, child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppText.mono(size: 15, weight: FontWeight.w600, color: AppColors.accentBlue),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
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
        Text(value, style: AppText.body(size: 13, weight: FontWeight.w700, color: valueColor ?? AppColors.accentBlue)),
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
          onChanged: onChanged,
          activeColor: AppColors.accent,
          activeTrackColor: AppColors.navyMid,
        ),
      ]),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}
