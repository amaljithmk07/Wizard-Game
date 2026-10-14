import 'package:flutter/material.dart';

// Spell Data Model for Wizard RPG Game

enum ElementType { fire, ice, lightning, nature, arcane, dark, healing }

enum SpellRarity { common, rare, epic, legendary, mythic }

extension ElementTypeExtension on ElementType {
  String get displayName {
    switch (this) {
      case ElementType.fire:
        return 'Fire Magic';
      case ElementType.ice:
        return 'Ice Magic';
      case ElementType.lightning:
        return 'Lightning';
      case ElementType.nature:
        return 'Nature';
      case ElementType.arcane:
        return 'Arcane';
      case ElementType.dark:
        return 'Dark Magic';
      case ElementType.healing:
        return 'Healing';
    }
  }

  IconData get iconData {
    switch (this) {
      case ElementType.fire:
        return Icons.local_fire_department_rounded;
      case ElementType.ice:
        return Icons.ac_unit_rounded;
      case ElementType.lightning:
        return Icons.bolt_rounded;
      case ElementType.nature:
        return Icons.eco_rounded;
      case ElementType.arcane:
        return Icons.auto_awesome_rounded;
      case ElementType.dark:
        return Icons.shield_moon_rounded;
      case ElementType.healing:
        return Icons.favorite_rounded;
    }
  }

  String get symbol {
    switch (this) {
      case ElementType.fire:
        return '🔥';
      case ElementType.ice:
        return '❄️';
      case ElementType.lightning:
        return '⚡';
      case ElementType.nature:
        return '🍃';
      case ElementType.arcane:
        return '✨';
      case ElementType.dark:
        return '💀';
      case ElementType.healing:
        return '💖';
    }
  }

  int get colorHex {
    switch (this) {
      case ElementType.fire:
        return 0xFFF97316;
      case ElementType.ice:
        return 0xFF38BDF8;
      case ElementType.lightning:
        return 0xFFEAB308;
      case ElementType.nature:
        return 0xFF22C55E;
      case ElementType.arcane:
        return 0xFFA855F7;
      case ElementType.dark:
        return 0xFFEF4444;
      case ElementType.healing:
        return 0xFFEC4899;
    }
  }
}

extension SpellRarityExtension on SpellRarity {
  String get displayName => name.toUpperCase();
  int get colorHex {
    switch (this) {
      case SpellRarity.common:
        return 0xFF94A3B8;
      case SpellRarity.rare:
        return 0xFF3B82F6;
      case SpellRarity.epic:
        return 0xFFA855F7;
      case SpellRarity.legendary:
        return 0xFFF5C451;
      case SpellRarity.mythic:
        return 0xFFEF4444;
    }
  }
}

class SpellModel {
  final String id;
  final String name;
  final String description;
  final ElementType element;
  final SpellRarity rarity;
  final double baseDamage;
  final double manaCost;
  final double cooldown; // seconds
  final int level;
  final int maxLevel;
  final bool isEquipped;
  final bool isUnlocked;

  const SpellModel({
    required this.id,
    required this.name,
    required this.description,
    required this.element,
    required this.rarity,
    required this.baseDamage,
    required this.manaCost,
    required this.cooldown,
    required this.level,
    required this.maxLevel,
    required this.isEquipped,
    required this.isUnlocked,
  });

  double get currentDamage => baseDamage + (level - 1) * (baseDamage * 0.25);
  int get upgradeCost => level * 300;

  SpellModel copyWith({
    int? level,
    bool? isEquipped,
    bool? isUnlocked,
  }) {
    return SpellModel(
      id: id,
      name: name,
      description: description,
      element: element,
      rarity: rarity,
      baseDamage: baseDamage,
      manaCost: manaCost,
      cooldown: cooldown,
      level: level ?? this.level,
      maxLevel: maxLevel,
      isEquipped: isEquipped ?? this.isEquipped,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  static List<SpellModel> initialSpells() {
    return const [
      SpellModel(
        id: 'fireball',
        name: 'Fireball',
        description: 'Launches an explosive orb of dragon fire.',
        element: ElementType.fire,
        rarity: SpellRarity.common,
        baseDamage: 35,
        manaCost: 15,
        cooldown: 1.5,
        level: 1,
        maxLevel: 20,
        isEquipped: true,
        isUnlocked: true,
      ),
      SpellModel(
        id: 'ice_spike',
        name: 'Ice Spike',
        description: 'Pierces enemies with freezing frost shards.',
        element: ElementType.ice,
        rarity: SpellRarity.rare,
        baseDamage: 45,
        manaCost: 20,
        cooldown: 2.5,
        level: 1,
        maxLevel: 20,
        isEquipped: true,
        isUnlocked: true,
      ),
      SpellModel(
        id: 'lightning_strike',
        name: 'Lightning Bolt',
        description: 'Calls down thunder from the storm clouds.',
        element: ElementType.lightning,
        rarity: SpellRarity.epic,
        baseDamage: 75,
        manaCost: 35,
        cooldown: 4.0,
        level: 1,
        maxLevel: 20,
        isEquipped: true,
        isUnlocked: true,
      ),
      SpellModel(
        id: 'healing_aura',
        name: 'Healing Light',
        description: 'Restores wizard health and shields against damage.',
        element: ElementType.healing,
        rarity: SpellRarity.rare,
        baseDamage: -30, // Negative damage = heal
        manaCost: 25,
        cooldown: 6.0,
        level: 1,
        maxLevel: 20,
        isEquipped: true,
        isUnlocked: true,
      ),
      SpellModel(
        id: 'meteor',
        name: 'Meteor Rain',
        description: 'Summons blazing cosmic meteors upon all enemies.',
        element: ElementType.fire,
        rarity: SpellRarity.legendary,
        baseDamage: 140,
        manaCost: 60,
        cooldown: 10.0,
        level: 1,
        maxLevel: 20,
        isEquipped: false,
        isUnlocked: false,
      ),
      SpellModel(
        id: 'dark_void',
        name: 'Shadow Void',
        description: 'Opens a vortex absorbing enemy souls.',
        element: ElementType.dark,
        rarity: SpellRarity.mythic,
        baseDamage: 220,
        manaCost: 80,
        cooldown: 14.0,
        level: 1,
        maxLevel: 20,
        isEquipped: false,
        isUnlocked: false,
      ),
    ];
  }
}
