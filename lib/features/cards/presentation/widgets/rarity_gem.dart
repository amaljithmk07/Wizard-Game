import 'package:flutter/material.dart';
import '../../models/game_card_model.dart';

class RarityGem extends StatelessWidget {
  final CardRarity rarity;

  const RarityGem({super.key, required this.rarity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rarity.frameColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rarity.primaryColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: rarity.glowColor,
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rarity.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: rarity.primaryColor,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rarity.displayName.toUpperCase(),
            style: TextStyle(
              color: rarity.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 8.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
