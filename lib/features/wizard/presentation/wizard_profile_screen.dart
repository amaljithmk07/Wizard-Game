import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/player_model.dart';
import '../providers/player_provider.dart';

class WizardProfileScreen extends ConsumerWidget {
  const WizardProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.magicPurple.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: Icon(player.title.iconData,
                        color: AppColors.gold, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name,
                          style: AppTypography.heading(fontSize: 18)),
                      Text(player.title.displayName,
                          style: AppTypography.caption(
                              color: AppColors.gold, fontSize: 13)),
                      Text('Wizard Level ${player.level}',
                          style: AppTypography.caption()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('CHARACTER STAT UPGRADES',
                  style: AppTypography.heading(
                      color: AppColors.gold, fontSize: 15)),
            ),
            const SizedBox(height: 12),
            _buildUpgradeCard(
              title: 'Health Capacity',
              statText: 'Max HP: ${player.maxHealth.toInt()}',
              level: player.healthLevel,
              cost: player.healthLevel * 200,
              icon: '❤️',
              color: AppColors.healthRed,
              onUpgrade: () => notifier.upgradeHealth(),
            ),
            const SizedBox(height: 10),
            _buildUpgradeCard(
              title: 'Magic Power',
              statText: 'Magic Power: ${player.magicPower.toInt()}',
              level: player.magicLevel,
              cost: player.magicLevel * 250,
              icon: '🔮',
              color: AppColors.magicPurple,
              onUpgrade: () => notifier.upgradeMagic(),
            ),
            const SizedBox(height: 10),
            _buildUpgradeCard(
              title: 'Mana Pool',
              statText: 'Max Mana: ${player.maxMana.toInt()}',
              level: player.manaLevel,
              cost: player.manaLevel * 180,
              icon: '💧',
              color: AppColors.manaBlue,
              onUpgrade: () => notifier.upgradeMana(),
            ),
            const SizedBox(height: 10),
            _buildUpgradeCard(
              title: 'Arcane Armor',
              statText: 'Defense: ${player.defense.toInt()}',
              level: player.defenseLevel,
              cost: player.defenseLevel * 220,
              icon: '🛡️',
              color: AppColors.shieldCyan,
              onUpgrade: () => notifier.upgradeDefense(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard({
    required String title,
    required String statText,
    required int level,
    required int cost,
    required String icon,
    required Color color,
    required VoidCallback onUpgrade,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading(fontSize: 14)),
                Text(statText,
                    style: AppTypography.caption(color: AppColors.textLight)),
                Text('Lv. $level', style: AppTypography.caption(color: color)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('💰 $cost',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
