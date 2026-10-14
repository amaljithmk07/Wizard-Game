import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/spell_model.dart';
import '../providers/spells_provider.dart';
import '../../wizard/providers/player_provider.dart';

class SpellBookScreen extends ConsumerWidget {
  const SpellBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spells = ref.watch(spellsProvider);
    final player = ref.watch(playerProvider);
    final spellsNotifier = ref.read(spellsProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SPELL BOOK & ELEMENTAL MAGIC',
                style:
                    AppTypography.heading(color: AppColors.gold, fontSize: 15)),
            Text('Equip up to 4 spells for battle combat',
                style: AppTypography.caption()),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: spells.length,
                itemBuilder: (context, index) {
                  final spell = spells[index];
                  final elementColor = Color(spell.element.colorHex);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: spell.isEquipped
                            ? AppColors.gold
                            : elementColor.withValues(alpha: 0.4),
                        width: spell.isEquipped ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: elementColor.withValues(alpha: 0.2),
                            border: Border.all(color: elementColor),
                          ),
                          alignment: Alignment.center,
                          child: Icon(spell.element.iconData,
                              color: elementColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(spell.name,
                                      style:
                                          AppTypography.heading(fontSize: 15)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(spell.rarity.colorHex)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      spell.rarity.displayName,
                                      style: TextStyle(
                                          color: Color(spell.rarity.colorHex),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text(spell.description,
                                  style: AppTypography.caption()),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Dmg: ${spell.currentDamage.toInt()}  ',
                                      style: AppTypography.caption(
                                          color: AppColors.fireOrange)),
                                  Text('Mana: ${spell.manaCost.toInt()}  ',
                                      style: AppTypography.caption(
                                          color: AppColors.manaBlue)),
                                  Text('Lv.${spell.level}',
                                      style: AppTypography.caption(
                                          color: AppColors.gold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                spellsNotifier.upgradeSpell(
                                  spell.id,
                                  player.coins,
                                  (cost) => ref
                                      .read(playerProvider.notifier)
                                      .addCoins(-cost),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: Text('💰 ${spell.upgradeCost}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton(
                              onPressed: () =>
                                  spellsNotifier.toggleEquip(spell.id),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: spell.isEquipped
                                        ? AppColors.gold
                                        : AppColors.textMuted),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                spell.isEquipped ? 'Equipped' : 'Equip',
                                style: TextStyle(
                                    color: spell.isEquipped
                                        ? AppColors.gold
                                        : AppColors.textMuted,
                                    fontSize: 10),
                              ),
                            ),
                          ],
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
