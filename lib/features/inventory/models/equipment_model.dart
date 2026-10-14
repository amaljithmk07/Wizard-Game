import 'package:flutter/material.dart';

// Equipment Item Model for Wizard RPG Game

enum EquipmentSlot { hat, robe, staff, ring, amulet, boots }

enum ItemRarity { common, rare, epic, legendary, mythic }

extension ItemRarityExtension on ItemRarity {
  int get colorHex {
    switch (this) {
      case ItemRarity.common:
        return 0xFF9E9E9E;
      case ItemRarity.rare:
        return 0xFF3B82F6;
      case ItemRarity.epic:
        return 0xFFA855F7;
      case ItemRarity.legendary:
        return 0xFFF59E0B;
      case ItemRarity.mythic:
        return 0xFFEF4444;
    }
  }
}

extension EquipmentSlotExtension on EquipmentSlot {
  String get displayName {
    switch (this) {
      case EquipmentSlot.hat:
        return 'Wizard Hat';
      case EquipmentSlot.robe:
        return 'Magical Robe';
      case EquipmentSlot.staff:
        return 'Arcane Staff';
      case EquipmentSlot.ring:
        return 'Spell Ring';
      case EquipmentSlot.amulet:
        return 'Amulet';
      case EquipmentSlot.boots:
        return 'Boots';
    }
  }

  IconData get iconData {
    switch (this) {
      case EquipmentSlot.hat:
        return Icons.workspace_premium_rounded;
      case EquipmentSlot.robe:
        return Icons.checkroom_rounded;
      case EquipmentSlot.staff:
        return Icons.auto_awesome_rounded;
      case EquipmentSlot.ring:
        return Icons.diamond_rounded;
      case EquipmentSlot.amulet:
        return Icons.shield_moon_rounded;
      case EquipmentSlot.boots:
        return Icons.hiking_rounded;
    }
  }

  String get icon {
    switch (this) {
      case EquipmentSlot.hat:
        return '🎩';
      case EquipmentSlot.robe:
        return '🥋';
      case EquipmentSlot.staff:
        return '🪄';
      case EquipmentSlot.ring:
        return '💍';
      case EquipmentSlot.amulet:
        return '📿';
      case EquipmentSlot.boots:
        return '🥾';
    }
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final EquipmentSlot slot;
  final ItemRarity rarity;
  final double magicPowerBonus;
  final double defenseBonus;
  final double healthBonus;
  final double manaBonus;
  final double critChanceBonus;
  final bool isEquipped;

  const EquipmentModel({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.magicPowerBonus,
    required this.defenseBonus,
    required this.healthBonus,
    required this.manaBonus,
    required this.critChanceBonus,
    required this.isEquipped,
  });

  static List<EquipmentModel> initialInventory() {
    return const [
      EquipmentModel(
        id: 'staff_1',
        name: 'Apprentice Oak Staff',
        slot: EquipmentSlot.staff,
        rarity: ItemRarity.common,
        magicPowerBonus: 15.0,
        defenseBonus: 0,
        healthBonus: 0,
        manaBonus: 10,
        critChanceBonus: 0.02,
        isEquipped: true,
      ),
      EquipmentModel(
        id: 'hat_1',
        name: 'Novice Wizard Hat',
        slot: EquipmentSlot.hat,
        rarity: ItemRarity.common,
        magicPowerBonus: 5.0,
        defenseBonus: 3.0,
        healthBonus: 15.0,
        manaBonus: 15.0,
        critChanceBonus: 0.01,
        isEquipped: true,
      ),
      EquipmentModel(
        id: 'robe_1',
        name: 'Silk Archmage Robe',
        slot: EquipmentSlot.robe,
        rarity: ItemRarity.epic,
        magicPowerBonus: 28.0,
        defenseBonus: 12.0,
        healthBonus: 50.0,
        manaBonus: 40.0,
        critChanceBonus: 0.04,
        isEquipped: false,
      ),
      EquipmentModel(
        id: 'ring_1',
        name: 'Ruby Ember Ring',
        slot: EquipmentSlot.ring,
        rarity: ItemRarity.rare,
        magicPowerBonus: 18.0,
        defenseBonus: 0,
        healthBonus: 0,
        manaBonus: 20.0,
        critChanceBonus: 0.05,
        isEquipped: true,
      ),
    ];
  }
}
