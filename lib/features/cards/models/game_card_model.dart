import 'package:flutter/material.dart';

enum CardRarity {
  common,
  rare,
  epic,
  legendary,
  mythic,
}

extension CardRarityExtension on CardRarity {
  String get displayName {
    switch (this) {
      case CardRarity.common:
        return 'Common';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.epic:
        return 'Epic';
      case CardRarity.legendary:
        return 'Legendary';
      case CardRarity.mythic:
        return 'Mythic';
    }
  }

  String get materialDescription {
    switch (this) {
      case CardRarity.common:
        return 'Weathered Iron & Steel';
      case CardRarity.rare:
        return 'Cold Cobalt & Silver Engraved';
      case CardRarity.epic:
        return 'Amethyst Crystal & Dark Silver';
      case CardRarity.legendary:
        return 'Antique Gold & Polished Brass';
      case CardRarity.mythic:
        return 'Obsidian Arcana & Star Gold';
    }
  }

  Color get primaryColor {
    switch (this) {
      case CardRarity.common:
        return const Color(0xFF78909C);
      case CardRarity.rare:
        return const Color(0xFF3B82F6);
      case CardRarity.epic:
        return const Color(0xFFA855F7);
      case CardRarity.legendary:
        return const Color(0xFFF59E0B);
      case CardRarity.mythic:
        return const Color(0xFFEC4899);
    }
  }

  Color get frameColor {
    switch (this) {
      case CardRarity.common:
        return const Color(0xFF2E3748);
      case CardRarity.rare:
        return const Color(0xFF1E293B);
      case CardRarity.epic:
        return const Color(0xFF2A1B3D);
      case CardRarity.legendary:
        return const Color(0xFF3E2723);
      case CardRarity.mythic:
        return const Color(0xFF180E29);
    }
  }

  Color get glowColor {
    switch (this) {
      case CardRarity.common:
        return const Color(0x339E9E9E);
      case CardRarity.rare:
        return const Color(0x803B82F6);
      case CardRarity.epic:
        return const Color(0x99A855F7);
      case CardRarity.legendary:
        return const Color(0xCCF59E0B);
      case CardRarity.mythic:
        return const Color(0xE6EC4899);
    }
  }

  bool get hasFoil => this == CardRarity.legendary || this == CardRarity.mythic;
  bool get hasParticles =>
      this == CardRarity.epic ||
      this == CardRarity.legendary ||
      this == CardRarity.mythic;
}

enum CardElement {
  fire, // Human Suit (Red)
  nature, // Elf Suit (Green)
  dwarfShield, // Dwarf Suit (Yellow/Gold)
  giantOcean, // Giant Suit (Blue)
  arcane, // Wizard Card ('W')
  darkMagic, // Jester Card ('Z')
}

extension CardElementExtension on CardElement {
  String get displayName {
    switch (this) {
      case CardElement.fire:
        return 'Humans (Fire)';
      case CardElement.nature:
        return 'Elves (Nature)';
      case CardElement.dwarfShield:
        return 'Dwarves (Shield)';
      case CardElement.giantOcean:
        return 'Giants (Ocean)';
      case CardElement.arcane:
        return 'Wizard Archmage';
      case CardElement.darkMagic:
        return 'Court Jester';
    }
  }

  IconData get iconData {
    switch (this) {
      case CardElement.fire:
        return Icons.local_fire_department_rounded;
      case CardElement.nature:
        return Icons.eco_rounded;
      case CardElement.dwarfShield:
        return Icons.shield_outlined;
      case CardElement.giantOcean:
        return Icons.tsunami_rounded;
      case CardElement.arcane:
        return Icons.auto_awesome_rounded;
      case CardElement.darkMagic:
        return Icons.theater_comedy_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case CardElement.fire:
        return const Color(0xFFFF4D4D);
      case CardElement.nature:
        return const Color(0xFF2ECC71);
      case CardElement.dwarfShield:
        return const Color(0xFFF1C40F);
      case CardElement.giantOcean:
        return const Color(0xFF3498DB);
      case CardElement.arcane:
        return const Color(0xFFA855F7);
      case CardElement.darkMagic:
        return const Color(0xFF06B6D4);
    }
  }

  Color get particleColor {
    switch (this) {
      case CardElement.fire:
        return const Color(0xFFFF6B00);
      case CardElement.nature:
        return const Color(0xFF86EFAC);
      case CardElement.dwarfShield:
        return const Color(0xFFFEF08A);
      case CardElement.giantOcean:
        return const Color(0xFF7DD3FC);
      case CardElement.arcane:
        return const Color(0xFFE879F9);
      case CardElement.darkMagic:
        return const Color(0xFF22D3EE);
    }
  }
}

enum CardType { wizard, jester, suit }

extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.wizard:
        return 'WIZARD (W)';
      case CardType.jester:
        return 'JESTER (Z)';
      case CardType.suit:
        return 'SUIT CARD';
    }
  }
}

class GameCardModel {
  final String id;
  final String name;
  final String indexSymbol; // 'W', 'Z', '1'-'13'
  final String description;
  final String abilityName;
  final CardType cardType;
  final CardRarity rarity;
  final CardElement element;
  final int level;
  final int maxLevel;
  final int manaCost;
  final double damage;
  final double defense;
  final double healing;
  final double criticalChance;
  final double cooldown;
  final IconData iconData;
  final bool isUnlocked;
  final bool isEquipped;
  final int upgradeCostCoins;
  final int upgradeCostCrystals;

  const GameCardModel({
    required this.id,
    required this.name,
    required this.indexSymbol,
    required this.description,
    required this.abilityName,
    required this.cardType,
    required this.rarity,
    required this.element,
    required this.level,
    this.maxLevel = 10,
    required this.manaCost,
    required this.damage,
    this.defense = 0,
    this.healing = 0,
    required this.criticalChance,
    required this.cooldown,
    required this.iconData,
    required this.isUnlocked,
    required this.isEquipped,
    required this.upgradeCostCoins,
    required this.upgradeCostCrystals,
  });

  GameCardModel copyWith({
    int? level,
    bool? isUnlocked,
    bool? isEquipped,
    double? damage,
    double? defense,
    double? healing,
    int? upgradeCostCoins,
  }) {
    return GameCardModel(
      id: id,
      name: name,
      indexSymbol: indexSymbol,
      description: description,
      abilityName: abilityName,
      cardType: cardType,
      rarity: rarity,
      element: element,
      level: level ?? this.level,
      maxLevel: maxLevel,
      manaCost: manaCost,
      damage: damage ?? this.damage,
      defense: defense ?? this.defense,
      healing: healing ?? this.healing,
      criticalChance: criticalChance,
      cooldown: cooldown,
      iconData: iconData,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      upgradeCostCoins: upgradeCostCoins ?? this.upgradeCostCoins,
      upgradeCostCrystals: upgradeCostCrystals,
    );
  }

  static List<GameCardModel> presetCards() {
    return const [
      // 1. Wizard 'W' Card
      GameCardModel(
        id: 'wizard_card_w',
        name: 'ARCHMAGE WIZARD',
        indexSymbol: 'W',
        abilityName: 'Absolute Trump Triumph',
        description:
            'The supreme card of the Wizard deck. Beats any suit card or trump card played in the trick round.',
        cardType: CardType.wizard,
        rarity: CardRarity.mythic,
        element: CardElement.arcane,
        level: 5,
        manaCost: 0,
        damage: 350,
        criticalChance: 0.30,
        cooldown: 0.0,
        iconData: Icons.auto_awesome_rounded,
        isUnlocked: true,
        isEquipped: true,
        upgradeCostCoins: 1500,
        upgradeCostCrystals: 25,
      ),

      // 2. Jester 'Z' Card
      GameCardModel(
        id: 'jester_card_z',
        name: 'ROYAL JESTER',
        indexSymbol: 'Z',
        abilityName: 'Zero Trick Pass',
        description:
            'The lowest card of the deck. Loses every trick unless led first. Perfect for exact bidding strategy.',
        cardType: CardType.jester,
        rarity: CardRarity.epic,
        element: CardElement.darkMagic,
        level: 4,
        manaCost: 0,
        damage: 0,
        defense: 100,
        criticalChance: 0.05,
        cooldown: 0.0,
        iconData: Icons.theater_comedy_rounded,
        isUnlocked: true,
        isEquipped: true,
        upgradeCostCoins: 600,
        upgradeCostCrystals: 5,
      ),

      // 3. Human Suit Cards (🔥 Fire)
      GameCardModel(
        id: 'human_13',
        name: 'HUMAN KING (13)',
        indexSymbol: '13',
        abilityName: 'Imperial Flame Strike',
        description:
            'The highest card of the Human suit. Commands massive fire damage and leads the human army.',
        cardType: CardType.suit,
        rarity: CardRarity.legendary,
        element: CardElement.fire,
        level: 4,
        manaCost: 13,
        damage: 260,
        criticalChance: 0.20,
        cooldown: 3.5,
        iconData: Icons.military_tech_rounded,
        isUnlocked: true,
        isEquipped: true,
        upgradeCostCoins: 800,
        upgradeCostCrystals: 12,
      ),
      GameCardModel(
        id: 'human_7',
        name: 'HUMAN WARRIOR (7)',
        indexSymbol: '7',
        abilityName: 'Blade Slash',
        description: 'Mid-rank Human suit card with balanced attack damage.',
        cardType: CardType.suit,
        rarity: CardRarity.common,
        element: CardElement.fire,
        level: 1,
        manaCost: 7,
        damage: 140,
        criticalChance: 0.08,
        cooldown: 4.0,
        iconData: Icons.shield_moon_rounded,
        isUnlocked: true,
        isEquipped: false,
        upgradeCostCoins: 200,
        upgradeCostCrystals: 0,
      ),

      // 4. Elf Suit Cards (🍃 Nature)
      GameCardModel(
        id: 'elf_12',
        name: 'HIGH ELF RANGER (12)',
        indexSymbol: '12',
        abilityName: 'Verdant Tempest',
        description:
            'High-rank Elf suit card. Shoots razor-sharp enchanted arrows that pierce armor.',
        cardType: CardType.suit,
        rarity: CardRarity.epic,
        element: CardElement.nature,
        level: 3,
        manaCost: 12,
        damage: 230,
        healing: 60,
        criticalChance: 0.18,
        cooldown: 4.0,
        iconData: Icons.eco_rounded,
        isUnlocked: true,
        isEquipped: true,
        upgradeCostCoins: 500,
        upgradeCostCrystals: 5,
      ),
      GameCardModel(
        id: 'elf_5',
        name: 'ELF DRUID (5)',
        indexSymbol: '5',
        abilityName: 'Bloom Restructure',
        description: 'Mid-tier Druid card restoring health and mana.',
        cardType: CardType.suit,
        rarity: CardRarity.common,
        element: CardElement.nature,
        level: 1,
        manaCost: 5,
        damage: 100,
        healing: 120,
        criticalChance: 0.05,
        cooldown: 5.0,
        iconData: Icons.nature_people_rounded,
        isUnlocked: true,
        isEquipped: false,
        upgradeCostCoins: 180,
        upgradeCostCrystals: 0,
      ),

      // 5. Dwarf Suit Cards (🛡️ Shield)
      GameCardModel(
        id: 'dwarf_11',
        name: 'DWARF FORGE MASTER (11)',
        indexSymbol: '11',
        abilityName: 'Mithril Shield Wall',
        description:
            'High-rank Dwarf suit card providing immense defensive fortitude and heavy hammer strikes.',
        cardType: CardType.suit,
        rarity: CardRarity.rare,
        element: CardElement.dwarfShield,
        level: 2,
        manaCost: 11,
        damage: 190,
        defense: 150,
        criticalChance: 0.12,
        cooldown: 5.0,
        iconData: Icons.construction_rounded,
        isUnlocked: true,
        isEquipped: false,
        upgradeCostCoins: 350,
        upgradeCostCrystals: 0,
      ),

      // 6. Giant Suit Cards (🌊 Ocean / Rock)
      GameCardModel(
        id: 'giant_10',
        name: 'MOUNTAIN GIANT (10)',
        indexSymbol: '10',
        abilityName: 'Tidal Quake',
        description:
            'High-rank Giant suit card. Smashes the battlefield with crushing earthquake force.',
        cardType: CardType.suit,
        rarity: CardRarity.rare,
        element: CardElement.giantOcean,
        level: 2,
        manaCost: 10,
        damage: 210,
        criticalChance: 0.15,
        cooldown: 5.5,
        iconData: Icons.landscape_rounded,
        isUnlocked: false,
        isEquipped: false,
        upgradeCostCoins: 400,
        upgradeCostCrystals: 0,
      ),
    ];
  }
}
