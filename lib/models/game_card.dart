import 'package:flutter/material.dart';

enum CardType {
  normal,
  wizard,
  jester,
}

class GameCard {
  final String id;
  final String suit; // 'Spades', 'Hearts', 'Diamonds', 'Clubs', 'None', 'Wizard', 'Jester'
  final int value;   // 2..14 for normal, 0 for Jester, 99 for Wizard
  final String name;
  final CardType type;

  GameCard({
    required this.id,
    required this.suit,
    required this.value,
    required this.name,
    this.type = CardType.normal,
  });

  bool get isWizard => type == CardType.wizard || name.toLowerCase().contains('wizard') || suit.toLowerCase() == 'wizard';
  bool get isJester => type == CardType.jester || name.toLowerCase().contains('jester') || suit.toLowerCase() == 'jester';

  String get displayValue {
    if (isWizard) return 'W';
    if (isJester) return 'N'; // Narre / Jester
    if (value == 14) return 'A';
    if (value == 13) return 'K';
    if (value == 12) return 'Q';
    if (value == 11) return 'J';
    return value.toString();
  }

  String get suitSymbol {
    if (isWizard) return '🧙‍♂️';
    if (isJester) return '🃏';
    switch (suit.toLowerCase()) {
      case 'hearts':
        return '♥';
      case 'diamonds':
        return '♦';
      case 'clubs':
        return '♣';
      case 'spades':
      default:
        return '♠';
    }
  }

  Color get suitColor {
    if (isWizard) return const Color(0xFF7C3AED); // Vivid Purple
    if (isJester) return const Color(0xFFD97706); // Warm Amber
    if (suit.toLowerCase() == 'hearts' || suit.toLowerCase() == 'diamonds') {
      return const Color(0xFFDC2626); // Red
    }
    return const Color(0xFF1E293B); // Dark Slate / Black
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString().toUpperCase();
    final rawName = (json['name'] ?? '').toString().toLowerCase();
    final rawSuit = (json['suit'] ?? '').toString().toLowerCase();

    CardType parsedType = CardType.normal;
    if (rawType == 'WIZARD' || rawName.contains('wizard') || rawSuit == 'wizard') {
      parsedType = CardType.wizard;
    } else if (rawType == 'JESTER' || rawName.contains('jester') || rawSuit == 'jester') {
      parsedType = CardType.jester;
    }

    return GameCard(
      id: json['id'] ?? '',
      suit: json['suit'] ?? 'Spades',
      value: json['value'] ?? (parsedType == CardType.wizard ? 99 : (parsedType == CardType.jester ? 0 : 2)),
      name: json['name'] ?? '',
      type: parsedType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suit': suit,
      'value': value,
      'name': name,
      'type': isWizard ? 'WIZARD' : (isJester ? 'JESTER' : 'NORMAL'),
    };
  }
}
