import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../models/instrument.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';

class InstrumentsScreen extends StatelessWidget {
  const InstrumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final groups = ['Full Size', 'Micro'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LogoRow(subtitle: 'Instruments'),
          ...groups.map((g) {
            final instruments = kAllInstruments.where((i) => i.group == g).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _GroupHeader(label: g),
              const SizedBox(height: 10),
              ...instruments.map((inst) => _InstrumentRow(
                instrument: inst,
                isFav: state.favorites.contains(inst.ticker),
                onToggle: () => state.toggleFavorite(inst.ticker),
              )),
              const SizedBox(height: 20),
            ]);
          }),
        ]),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppText.label(color: AppColors.muted)),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: AppColors.border)),
    ]);
  }
}

class _InstrumentRow extends StatelessWidget {
  final Instrument instrument;
  final bool isFav;
  final VoidCallback onToggle;
  const _InstrumentRow({required this.instrument, required this.isFav, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFav ? AppColors.orange.withOpacity(0.2) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          SizedBox(width: 44, child: Text(instrument.ticker,
            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(instrument.name, style: AppText.body(size: 12, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text('\$${instrument.pointValue}/point', style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.accentBlue)),
          ])),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(isFav ? '★' : '☆',
                style: TextStyle(fontSize: 18, color: isFav ? AppColors.orange : AppColors.muted))),
            ),
          ),
        ]),
      ),
    );
  }
}
