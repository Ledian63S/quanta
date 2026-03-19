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

          // Header
          Row(children: [
            Text('> ', style: AppText.mono(size: 11, color: AppColors.accent)),
            Text('SETTINGS', style: AppText.label(color: AppColors.accentLight)),
          ]),
          const SizedBox(height: 20),

          // ── ACCOUNT ──────────────────────────────────────────────────
          _SectionHeader('ACCOUNT'),
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
          _SectionHeader('RISK'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: _InputRow(
              label: 'Risk / Trade',
              controller: _riskCtrl,
              prefix: '\$',
              onChanged: (v) => state.setRisk(double.tryParse(v) ?? state.riskAmount),
            ),
          ),

          const SizedBox(height: 20),

          // ── PREFERENCES ──────────────────────────────────────────────
          _SectionHeader('PREFERENCES'),
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
          _SectionHeader('APPEARANCE'),
          const SizedBox(height: 8),
          Container(
            decoration: AppDecor.card(),
            child: _AppearanceRow(current: state.themeMode, onChanged: state.setThemeMode),
          ),

          const SizedBox(height: 20),

          // ── ABOUT ────────────────────────────────────────────────────
          _SectionHeader('ABOUT'),
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
              const _LabelRow(label: 'Built for Quantower traders', value: '✦',
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
class _InputRow extends StatelessWidget {
  final String label, prefix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _InputRow({required this.label, required this.controller,
      required this.prefix, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Text('> ', style: AppText.mono(size: 11, color: AppColors.muted)),
        Expanded(child: Text(label, style: AppText.mono(
            size: 13, weight: FontWeight.w500, color: AppColors.text))),
        Text(prefix, style: AppText.mono(size: 13,
            weight: FontWeight.w600, color: AppColors.muted)),
        SizedBox(width: 80, child: TextField(
          controller: controller,
          onChanged: onChanged,
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
      ]),
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
        Expanded(child: Text(label, style: AppText.mono(
            size: 12, weight: FontWeight.w500, color: AppColors.muted))),
        Text(value, style: AppText.mono(size: 12, weight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text('> ', style: AppText.mono(size: 11, color: AppColors.subtle)),
        Expanded(child: Text(label, style: AppText.mono(
            size: 12, weight: FontWeight.w500, color: AppColors.text))),
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
