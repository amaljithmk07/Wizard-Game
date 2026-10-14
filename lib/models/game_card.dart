import 'package:flutter/material.dart';

class GameCard {
  final String id;
  final String suit;
  final int value;
  final String name;

  GameCard({
    required this.id,
    required this.suit,
    required this.value,
    required this.name,
  });

  String get displayValue {
    if (value == 14) return 'A';
    if (value == 13) return 'K';
    if (value == 12) return 'Q';
    if (value == 11) return 'J';
    return value.toString();
  }

  String get suitSymbol {
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
    if (suit.toLowerCase() == 'hearts' || suit.toLowerCase() == 'diamonds') {
      return const Color(0xFFDC2626); // Red
    }
    return const Color(0xFF1E293B); // Dark Slate / Black
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] ?? '',
      suit: json['suit'] ?? 'Spades',
      value: json['value'] ?? 2,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suit': suit,
      'value': value,
      'name': name,
    };
  }
}
