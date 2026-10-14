import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/equipment_model.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WIZARD EQUIPMENT & GEAR',
                style:
                    AppTypography.heading(color: AppColors.gold, fontSize: 15)),
            Text('Equip powerful wizard gear to boost stats',
                style: AppTypography.caption()),
            const SizedBox(height: 14),

            // Paper-Doll Equipment Slots Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: EquipmentSlot.values.map((slot) {
                final equippedItem = inventory.firstWhere(
                  (item) => item.slot == slot && item.isEquipped,
                  orElse: () => EquipmentModel(
                    id: '',
                    name: 'Empty Slot',
                    slot: slot,
                    rarity: ItemRarity.common,
                    magicPowerBonus: 0,
                    defenseBonus: 0,
                    healthBonus: 0,
                    manaBonus: 0,
                    critChanceBonus: 0,
                    isEquipped: false,
                  ),
                );

                final isHasItem = equippedItem.id.isNotEmpty;

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHasItem ? AppColors.gold : AppColors.cardBorder,
                      width: isHasItem ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        slot.iconData,
                        size: 22,
                        color: isHasItem ? AppColors.gold : AppColors.textDim,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHasItem ? equippedItem.name : slot.displayName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: isHasItem
                              ? AppColors.textLight
                              : AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('INVENTORY GEAR',
                style: AppTypography.heading(
                    fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 8),

            // Inventory Item List
            Expanded(
              child: ListView.builder(
                itemCount: inventory.length,
                itemBuilder: (context, index) {
                  final item = inventory[index];
                  final rarityColor = Color(item.rarity.colorHex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: rarityColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rarityColor.withValues(alpha: 0.15),
                          ),
                          child: Icon(item.slot.iconData,
                              color: rarityColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: AppTypography.heading(fontSize: 14)),
                              Text(
                                'Magic +${item.magicPowerBonus.toInt()}  Def +${item.defenseBonus.toInt()}  HP +${item.healthBonus.toInt()}',
                                style: AppTypography.caption(
                                    color: AppColors.gold, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => notifier.equipItem(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.isEquipped
                                ? AppColors.cardBorder
                                : AppColors.gold,
                            foregroundColor: item.isEquipped
                                ? AppColors.textMuted
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          child: Text(item.isEquipped ? 'Equipped' : 'Equip',
                              style: AppTypography.statLabel(
                                  color: item.isEquipped
                                      ? AppColors.textMuted
                                      : Colors.black,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
