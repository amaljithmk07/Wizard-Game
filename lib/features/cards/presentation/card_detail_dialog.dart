import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../wizard/providers/player_provider.dart';
import '../models/game_card_model.dart';
import '../providers/card_collection_provider.dart';
import 'widgets/game_card.dart';

class CardDetailDialog extends ConsumerWidget {
  final GameCardModel card;

  const CardDetailDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cardNotifier = ref.read(cardCollectionProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);

    final isMaxLevel = card.level >= card.maxLevel;
    final canAfford = player.coins >= card.upgradeCostCoins &&
        player.crystals >= card.upgradeCostCrystals;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0C1B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: card.rarity.primaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: card.rarity.glowColor,
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.rarity.materialDescription,
                          style: AppTypography.caption(
                              color: card.rarity.primaryColor, fontSize: 10)),
                      Text(card.name,
                          style: AppTypography.heading(
                              color: AppColors.gold, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive 3D Realistic Card Preview
              SizedBox(
                height: 320,
                child: Center(
                  child: GameCard(card: card, isInteractive: true),
                ),
              ),
              const SizedBox(height: 16),

              // Level Progress Bar
              Row(
                children: [
                  Text('LEVEL ${card.level}/${card.maxLevel}',
                      style: AppTypography.heading(
                          fontSize: 12, color: AppColors.gold)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: card.level / card.maxLevel,
                        minHeight: 10,
                        color: card.element.accentColor,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Detailed Stat Boost Matrix
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Damage', '${card.damage.toInt()}',
                        AppColors.fireOrange),
                    _buildStatCol(
                        'Crit Chance',
                        '+${(card.criticalChance * 100).toInt()}%',
                        AppColors.gold),
                    _buildStatCol(
                        'Cooldown', '${card.cooldown}s', AppColors.magicCyan),
                    if (card.defense > 0)
                      _buildStatCol('Defense', '${card.defense.toInt()}',
                          AppColors.arcaneBlue),
                    if (card.healing > 0)
                      _buildStatCol('Healing', '${card.healing.toInt()}',
                          const Color(0xFF22C55E)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons (Equip & Upgrade)
              Row(
                children: [
                  // Equip Toggle Button
                  if (card.isUnlocked)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          cardNotifier.toggleEquipCard(card.id);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: card.isEquipped
                              ? AppColors.cardBorder
                              : card.element.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          card.isEquipped ? 'UNEQUIP' : 'EQUIP DECK',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),

                  if (card.isUnlocked) const SizedBox(width: 12),

                  // Upgrade Button with Coin / Crystal Costs
                  if (card.isUnlocked && !isMaxLevel)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canAfford
                            ? () {
                                playerNotifier
                                    .spendCoins(card.upgradeCostCoins);
                                cardNotifier.upgradeCard(card.id);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'UPGRADE ',
                              style: AppTypography.statLabel(
                                  color: Colors.black, fontSize: 12),
                            ),
                            const Icon(Icons.monetization_on_rounded,
                                size: 14, color: Colors.black),
                            Text(
                              ' ${card.upgradeCostCoins}',
                              style: AppTypography.statLabel(
                                  color: Colors.black, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: AppTypography.caption(fontSize: 10)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
  }
}
