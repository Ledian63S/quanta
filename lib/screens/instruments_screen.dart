import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

          // ── Favorites strip ──────────────────────────────────────────
          if (state.favoriteInstruments.isNotEmpty) ...[
            Text('WATCHLIST', style: AppText.label()),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: state.favoriteInstruments.map((inst) {
                final isSelected = inst.ticker == state.selectedTicker;
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inst.ticker, style: GoogleFonts.manrope(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.accentLight : AppColors.text,
                    )),
                    const SizedBox(height: 3),
                    Text('\$${inst.pointValue}/pt', style: AppText.mono(
                      size: 11, weight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.7) : AppColors.muted,
                    )),
                  ]),
                );
              }).toList()),
            ),
            const SizedBox(height: 28),
          ],

          // ── All instruments ──────────────────────────────────────────
          Text('ALL INSTRUMENTS', style: AppText.label()),
          const SizedBox(height: 10),
          ...groups.map((g) {
            final instruments = kAllInstruments.where((i) => i.group == g).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(children: [
                  Text(g, style: AppText.body(
                      size: 12, weight: FontWeight.w600, color: AppColors.muted)),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                ]),
              ),
              ...instruments.map((inst) => _InstrumentRow(
                instrument: inst,
                isFav: state.favorites.contains(inst.ticker),
                onToggle: () => state.toggleFavorite(inst.ticker),
              )),
              const SizedBox(height: 8),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFav
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(children: [
          // Ticker + name
          Expanded(child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isFav
                    ? AppColors.orange.withValues(alpha: 0.08)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFav
                      ? AppColors.orange.withValues(alpha: 0.2)
                      : AppColors.border,
                ),
              ),
              child: Center(child: Text(
                instrument.ticker.substring(0, 1),
                style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: isFav ? AppColors.orange : AppColors.muted,
                ),
              )),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(instrument.ticker, style: GoogleFonts.manrope(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 2),
              Text(instrument.name, style: AppText.body(
                  size: 11, color: AppColors.muted)),
            ]),
          ])),

          // Point value
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${instrument.pointValue}',
                style: AppText.mono(size: 15, weight: FontWeight.w700,
                    color: AppColors.accentLight)),
            const SizedBox(height: 2),
            Text('per point', style: AppText.label(size: 9)),
          ]),

          const SizedBox(width: 14),

          // Star button
          Clickable(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: isFav
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFav
                      ? AppColors.orange.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Center(child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isFav ? '★' : '☆',
                  key: ValueKey(isFav),
                  style: TextStyle(
                      fontSize: 17,
                      color: isFav ? AppColors.orange : AppColors.muted),
                ),
              )),
            ),
          ),
        ]),
      ),
    );
  }
}
