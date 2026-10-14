import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../wizard/providers/player_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MAGIC SHOP & MYSTERY CHESTS',
                style:
                    AppTypography.heading(color: AppColors.gold, fontSize: 15)),
            Text('Purchase spell chests, crystals, and gold scrolls',
                style: AppTypography.caption()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildShopItem(
                    icon: '📦',
                    name: 'Rare Chest',
                    desc: 'Contains Rare Spells & Coins',
                    price: '💰 500',
                    color: AppColors.arcaneBlue,
                    onBuy: () {
                      if (player.coins >= 500) {
                        notifier.addCoins(-500);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShopItem(
                    icon: '👑',
                    name: 'Mythic Chest',
                    desc: 'Guaranteed Mythic Spell',
                    price: '💎 50',
                    color: AppColors.crystalViolet,
                    onBuy: () {
                      if (player.crystals >= 50) {
                        notifier.addCrystals(-50);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildShopItem(
              icon: '💎',
              name: 'Pouch of Magic Crystals (+100 Crystals)',
              desc: 'Premium wizard currency for legendary unlocks',
              price: '💰 2,500 Coins',
              color: AppColors.gold,
              onBuy: () {
                if (player.coins >= 2500) {
                  notifier.addCoins(-2500);
                  notifier.addCrystals(100);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem({
    required String icon,
    required String name,
    required String desc,
    required String price,
    required Color color,
    required VoidCallback onBuy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(name, style: AppTypography.heading(fontSize: 14)),
          Text(desc, style: AppTypography.caption(fontSize: 10)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: Text(price,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
