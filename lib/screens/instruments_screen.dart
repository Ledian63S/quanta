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
              const SizedBox(width: 8),
              if (state.favoriteInstruments.length > 1)
                Text('DRAG · SWIPE TO REMOVE',
                    style: AppText.mono(size: 9, color: AppColors.subtle)),
            ]),
            const SizedBox(height: 10),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: state.reorderFavorites,
              itemCount: state.favoriteInstruments.length,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemBuilder: (context, i) {
                final inst = state.favoriteInstruments[i];
                final isSelected = inst.ticker == state.selectedTicker;
                return _WatchlistItem(
                  key: ValueKey(inst.ticker),
                  instrument: inst,
                  isSelected: isSelected,
                  index: i,
                  onRemove: state.favorites.length > 1
                      ? () => state.toggleFavorite(inst.ticker)
                      : null,
                );
              },
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

class _WatchlistItem extends StatelessWidget {
  final Instrument instrument;
  final bool isSelected;
  final int index;
  final VoidCallback? onRemove;
  const _WatchlistItem({
    super.key,
    required this.instrument,
    required this.isSelected,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(children: [
        // Drag handle
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Text('≡', style: AppText.mono(size: 16, color: AppColors.muted)),
          ),
        ),
        // Left accent bar
        Container(
          width: 2, height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.subtle,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 12),
        // Ticker + name
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(instrument.ticker, style: AppText.mono(
            size: 14, weight: FontWeight.w700,
            color: isSelected ? AppColors.accentLight : AppColors.text,
          )),
          const SizedBox(height: 2),
          Text(instrument.name, style: AppText.mono(size: 10, color: AppColors.muted)),
        ])),
        // Point value
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('\$${instrument.pointValue}/PT', style: AppText.mono(
            size: 12, weight: FontWeight.w700,
            color: isSelected ? AppColors.accent : AppColors.muted,
          )),
        ),
      ]),
    );

    if (onRemove == null) return card;
    return Dismissible(
      key: ValueKey('dismiss_${instrument.ticker}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: isSelected ? (_) async {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SWITCH INSTRUMENT FIRST',
              style: AppText.label(color: Colors.black)),
          backgroundColor: AppColors.orange,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        ));
        return false;
      } : null,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onRemove!();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
        ),
        child: Text('REMOVE', style: AppText.label(size: 9, color: AppColors.orange)),
      ),
      child: card,
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
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Left accent bar
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 3,
        decoration: BoxDecoration(
          color: isFav ? AppColors.accent : AppColors.subtle,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
      ),

      // Content
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(children: [
            // Ticker + name
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(instrument.ticker, style: AppText.mono(
                  size: 14, weight: FontWeight.w700,
                  color: isFav ? AppColors.accentLight : AppColors.text)),
              const SizedBox(height: 2),
              Text(instrument.name, style: AppText.mono(
                  size: 10, color: AppColors.muted)),
            ])),

            // Point value with dot leader
            Row(children: [
              Text('\$${instrument.pointValue}/pt',
                  style: AppText.mono(size: 12, weight: FontWeight.w700,
                      color: isFav ? AppColors.accent : AppColors.muted)),
            ]),

            const SizedBox(width: 14),

            // Star toggle — circular
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
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFav
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Center(child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    isFav ? '★' : '☆',
                    key: ValueKey(isFav),
                    style: TextStyle(
                        fontSize: 14,
                        color: isFav ? AppColors.accent : AppColors.muted),
                  ),
                )),
              ),
            ),
          ]),
        ),
      ),
    ]));
  }
}
