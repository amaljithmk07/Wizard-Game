import 'package:flutter/material.dart';

// Player Model for Wizard RPG Game

enum WizardTitle {
  apprentice,
  spellcaster,
  mage,
  archmage,
  grandWizard,
}

extension WizardTitleExtension on WizardTitle {
  String get displayName {
    switch (this) {
      case WizardTitle.apprentice:
        return 'Apprentice Wizard';
      case WizardTitle.spellcaster:
        return 'Spellcaster';
      case WizardTitle.mage:
        return 'High Mage';
      case WizardTitle.archmage:
        return 'Archmage';
      case WizardTitle.grandWizard:
        return 'Grand Wizard';
    }
  }

  IconData get iconData {
    switch (this) {
      case WizardTitle.apprentice:
        return Icons.auto_awesome_rounded;
      case WizardTitle.spellcaster:
        return Icons.stars_rounded;
      case WizardTitle.mage:
        return Icons.psychology_rounded;
      case WizardTitle.archmage:
        return Icons.bolt_rounded;
      case WizardTitle.grandWizard:
        return Icons.workspace_premium_rounded;
    }
  }

  String get icon {
    switch (this) {
      case WizardTitle.apprentice:
        return '🪄';
      case WizardTitle.spellcaster:
        return '✨';
      case WizardTitle.mage:
        return '🔮';
      case WizardTitle.archmage:
        return '⚡';
      case WizardTitle.grandWizard:
        return '👑';
    }
  }
}

class PlayerModel {
  final String id;
  final String name;
  final int level;
  final int xp;
  final int coins;
  final int crystals;
  final WizardTitle title;

  // Base Stats
  final double maxHealth;
  final double maxMana;
  final double attackPower;
  final double magicPower;
  final double defense;
  final double critChance;
  final double moveSpeed;
  final double manaRegen;
  final double cooldownReduction;

  // Stat Upgrade Levels
  final int healthLevel;
  final int manaLevel;
  final int magicLevel;
  final int defenseLevel;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.level,
    required this.xp,
    required this.coins,
    required this.crystals,
    required this.title,
    required this.maxHealth,
    required this.maxMana,
    required this.attackPower,
    required this.magicPower,
    required this.defense,
    required this.critChance,
    required this.moveSpeed,
    required this.manaRegen,
    required this.cooldownReduction,
    required this.healthLevel,
    required this.manaLevel,
    required this.magicLevel,
    required this.defenseLevel,
  });

  factory PlayerModel.initial() {
    return const PlayerModel(
      id: 'player_1',
      name: 'Merlin Apprentice',
      level: 1,
      xp: 0,
      coins: 1500,
      crystals: 50,
      title: WizardTitle.apprentice,
      maxHealth: 100.0,
      maxMana: 80.0,
      attackPower: 15.0,
      magicPower: 25.0,
      defense: 5.0,
      critChance: 0.05,
      moveSpeed: 180.0,
      manaRegen: 3.5,
      cooldownReduction: 0.0,
      healthLevel: 1,
      manaLevel: 1,
      magicLevel: 1,
      defenseLevel: 1,
    );
  }

  PlayerModel copyWith({
    String? name,
    int? level,
    int? xp,
    int? coins,
    int? crystals,
    WizardTitle? title,
    double? maxHealth,
    double? maxMana,
    double? attackPower,
    double? magicPower,
    double? defense,
    double? critChance,
    double? moveSpeed,
    double? manaRegen,
    double? cooldownReduction,
    int? healthLevel,
    int? manaLevel,
    int? magicLevel,
    int? defenseLevel,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      crystals: crystals ?? this.crystals,
      title: title ?? this.title,
      maxHealth: maxHealth ?? this.maxHealth,
      maxMana: maxMana ?? this.maxMana,
      attackPower: attackPower ?? this.attackPower,
      magicPower: magicPower ?? this.magicPower,
      defense: defense ?? this.defense,
      critChance: critChance ?? this.critChance,
      moveSpeed: moveSpeed ?? this.moveSpeed,
      manaRegen: manaRegen ?? this.manaRegen,
      cooldownReduction: cooldownReduction ?? this.cooldownReduction,
      healthLevel: healthLevel ?? this.healthLevel,
      manaLevel: manaLevel ?? this.manaLevel,
      magicLevel: magicLevel ?? this.magicLevel,
      defenseLevel: defenseLevel ?? this.defenseLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'xp': xp,
        'coins': coins,
        'crystals': crystals,
        'title': title.index,
        'maxHealth': maxHealth,
        'maxMana': maxMana,
        'attackPower': attackPower,
        'magicPower': magicPower,
        'defense': defense,
        'critChance': critChance,
        'moveSpeed': moveSpeed,
        'manaRegen': manaRegen,
        'cooldownReduction': cooldownReduction,
        'healthLevel': healthLevel,
        'manaLevel': manaLevel,
        'magicLevel': magicLevel,
        'defenseLevel': defenseLevel,
      };

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] ?? 'player_1',
      name: json['name'] ?? 'Wizard',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 500,
      crystals: json['crystals'] ?? 20,
      title: WizardTitle.values[json['title'] ?? 0],
      maxHealth: (json['maxHealth'] ?? 100.0).toDouble(),
      maxMana: (json['maxMana'] ?? 80.0).toDouble(),
      attackPower: (json['attackPower'] ?? 15.0).toDouble(),
      magicPower: (json['magicPower'] ?? 25.0).toDouble(),
      defense: (json['defense'] ?? 5.0).toDouble(),
      critChance: (json['critChance'] ?? 0.05).toDouble(),
      moveSpeed: (json['moveSpeed'] ?? 180.0).toDouble(),
      manaRegen: (json['manaRegen'] ?? 3.5).toDouble(),
      cooldownReduction: (json['cooldownReduction'] ?? 0.0).toDouble(),
      healthLevel: json['healthLevel'] ?? 1,
      manaLevel: json['manaLevel'] ?? 1,
      magicLevel: json['magicLevel'] ?? 1,
      defenseLevel: json['defenseLevel'] ?? 1,
    );
  }
}
