import 'package:flutter/material.dart';
import '../models/game_card.dart';

class GameCardWidget extends StatelessWidget {
  final GameCard? card;
  final bool isFaceDown;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const GameCardWidget({
    super.key,
    this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.onTap,
    this.width = 62,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    if (isFaceDown || card == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1),
            ),
            child: Center(
              child: Icon(
                Icons.style_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: width * 0.4,
              ),
            ),
          ),
        ),
      );
    }

    final displayCard = card!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: isSelected ? 8 : 0),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Value top left
            Text(
              displayCard.displayValue,
              style: TextStyle(
                color: displayCard.suitColor,
                fontSize: width * 0.24,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            // Suit symbol center/bottom
            Align(
              alignment: Alignment.center,
              child: Text(
                displayCard.suitSymbol,
                style: TextStyle(
                  color: displayCard.suitColor,
                  fontSize: width * 0.42,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
