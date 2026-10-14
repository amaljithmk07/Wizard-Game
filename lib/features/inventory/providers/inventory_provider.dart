import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment_model.dart';

class InventoryNotifier extends StateNotifier<List<EquipmentModel>> {
  InventoryNotifier() : super(EquipmentModel.initialInventory());

  void equipItem(EquipmentModel item) {
    state = [
      for (final eq in state)
        if (eq.slot == item.slot)
          EquipmentModel(
            id: eq.id,
            name: eq.name,
            slot: eq.slot,
            rarity: eq.rarity,
            magicPowerBonus: eq.magicPowerBonus,
            defenseBonus: eq.defenseBonus,
            healthBonus: eq.healthBonus,
            manaBonus: eq.manaBonus,
            critChanceBonus: eq.critChanceBonus,
            isEquipped: eq.id == item.id,
          )
        else
          eq,
    ];
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<EquipmentModel>>((ref) {
  return InventoryNotifier();
});
