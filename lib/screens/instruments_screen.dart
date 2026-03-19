import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/quanta_state.dart';
import '../models/instrument.dart';
import '../theme/app_theme.dart';

class InstrumentsScreen extends StatelessWidget {
  const InstrumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuantaState>();
    final groups = ['Full Size', 'Micro'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ───────────────────────────────────────────────────
          Row(children: [
            Text('> ', style: AppText.mono(size: 11, color: AppColors.accent)),
            Text('MARKETS', style: AppText.label(color: AppColors.accentLight)),
          ]),
          const SizedBox(height: 16),

          // ── Watchlist strip ──────────────────────────────────────────
          if (state.favoriteInstruments.isNotEmpty) ...[
            Row(children: [
              Text('WATCHLIST', style: AppText.label()),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.border)),
            ]),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: state.favoriteInstruments.map((inst) {
                final isSelected = inst.ticker == state.selectedTicker;
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: isSelected
                      ? AppDecor.activeInstrument()
                      : AppDecor.inactiveInstrument(),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inst.ticker, style: AppText.mono(
                      size: 14, weight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : AppColors.text,
                    )),
                    const SizedBox(height: 3),
                    Text('\$${inst.pointValue}/PT', style: AppText.label(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.6) : AppColors.muted,
                    )),
                  ]),
                );
              }).toList()),
            ),
            const SizedBox(height: 24),
          ],

          // ── All instruments ──────────────────────────────────────────
          Row(children: [
            Text('ALL INSTRUMENTS', style: AppText.label()),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: AppColors.border)),
          ]),
          const SizedBox(height: 10),

          ...groups.map((g) {
            final instruments = kAllInstruments.where((i) => i.group == g).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text('// $g', style: AppText.mono(
                    size: 11, color: AppColors.muted)),
              ),
              Container(
                decoration: AppDecor.card(),
                child: Column(children: [
                  ...instruments.asMap().entries.map((e) {
                    final i = e.key;
                    final inst = e.value;
                    final isFav = state.favorites.contains(inst.ticker);
                    return Column(children: [
                      _InstrumentRow(
                        instrument: inst,
                        isFav: isFav,
                        onToggle: () => state.toggleFavorite(inst.ticker),
                      ),
                      if (i < instruments.length - 1)
                        Container(height: 1, color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 12)),
                    ]);
                  }),
                ]),
              ),
              const SizedBox(height: 12),
            ]);
          }),
        ]),
      ),
    );
  }
}

class _InstrumentRow extends StatelessWidget {
  final Instrument instrument;
  final bool isFav;
  final VoidCallback onToggle;
  const _InstrumentRow({required this.instrument, required this.isFav, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(children: [
        // Ticker prefix
        Text('> ', style: AppText.mono(size: 11,
            color: isFav ? AppColors.accent : AppColors.subtle)),

        // Ticker + name
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(instrument.ticker, style: AppText.mono(
              size: 14, weight: FontWeight.w700,
              color: isFav ? AppColors.accentLight : AppColors.text)),
          const SizedBox(height: 2),
          Text(instrument.name, style: AppText.mono(
              size: 10, color: AppColors.muted)),
        ])),

        // Point value
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${instrument.pointValue}',
              style: AppText.mono(size: 13, weight: FontWeight.w700,
                  color: isFav ? AppColors.accent : AppColors.muted)),
          Text('per pt', style: AppText.label(size: 9)),
        ]),

        const SizedBox(width: 14),

        // Star toggle
        Clickable(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: isFav
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isFav
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Center(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                isFav ? '★' : '☆',
                key: ValueKey(isFav),
                style: TextStyle(
                    fontSize: 15,
                    color: isFav ? AppColors.accent : AppColors.muted),
              ),
            )),
          ),
        ),
      ]),
    );
  }
}
