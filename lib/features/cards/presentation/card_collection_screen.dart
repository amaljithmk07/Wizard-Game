import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/game_card_model.dart';
import '../providers/card_collection_provider.dart';
import 'card_detail_dialog.dart';
import 'card_reveal_dialog.dart';
import 'widgets/game_card.dart';

class CardCollectionScreen extends ConsumerStatefulWidget {
  const CardCollectionScreen({super.key});

  @override
  ConsumerState<CardCollectionScreen> createState() =>
      _CardCollectionScreenState();
}

class _CardCollectionScreenState extends ConsumerState<CardCollectionScreen> {
  CardElement? _selectedElement;

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(cardCollectionProvider);
    final cardNotifier = ref.read(cardCollectionProvider.notifier);

    final filteredCards = _selectedElement == null
        ? allCards
        : allCards.where((c) => c.element == _selectedElement).toList();

    final unlockedCount = allCards.where((c) => c.isUnlocked).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Collection Metric
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANCIENT CARD VAULT',
                          style: AppTypography.heading(
                              color: AppColors.gold, fontSize: 16)),
                      Text('Physical fantasy collectible artifacts & spells',
                          style: AppTypography.caption()),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.midnightPurple,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '$unlockedCount / ${allCards.length} UNLOCKED',
                      style: AppTypography.statLabel(
                          color: AppColors.gold, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Elemental Filter Bar with Library Icons & Poppins Font
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('ALL', Icons.all_inclusive_rounded, null),
                    for (final elem in CardElement.values)
                      _buildFilterChip(elem.displayName, elem.iconData, elem),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Cards 2-Column Responsive Grid
              Expanded(
                child: GridView.builder(
                  itemCount: filteredCards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.69,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];

                    return GameCard(
                      card: card,
                      onTap: () {
                        if (card.isUnlocked) {
                          showDialog(
                            context: context,
                            builder: (_) => CardDetailDialog(card: card),
                          );
                        } else {
                          // Trigger Reveal Test for locked cards
                          cardNotifier.unlockCard(card.id);
                          showDialog(
                            context: context,
                            builder: (_) => CardRevealDialog(
                                card: card.copyWith(isUnlocked: true)),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, CardElement? element) {
    final isSelected = _selectedElement == element;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected
              ? Colors.black
              : (element?.accentColor ?? AppColors.gold),
        ),
        label: Text(
          label,
          style: AppTypography.caption(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.gold,
        backgroundColor: AppColors.cardDark,
        onSelected: (_) => setState(() => _selectedElement = element),
      ),
    );
  }
}
