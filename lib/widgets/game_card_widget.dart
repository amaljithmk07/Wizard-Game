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
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
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
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withOpacity(0.75),
                size: width * 0.35,
              ),
            ),
          ),
        ),
      );
    }

    final displayCard = card!;
    final isWizard = displayCard.isWizard;
    final isJester = displayCard.isJester;

    Color borderColor = const Color(0xFFE2E8F0);
    Color cardBg = Colors.white;

    if (isSelected) {
      borderColor = const Color(0xFF2563EB);
    } else if (isWizard) {
      borderColor = const Color(0xFFA855F7); // Purple accent
      cardBg = const Color(0xFFFAF5FF);
    } else if (isJester) {
      borderColor = const Color(0xFFF59E0B); // Amber accent
      cardBg = const Color(0xFFFFFBEB);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: isSelected ? 10 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : (isWizard || isJester ? 1.8 : 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withOpacity(0.3)
                  : (isWizard
                      ? const Color(0xFF7C3AED).withOpacity(0.15)
                      : Colors.black.withOpacity(0.06)),
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
                fontSize: width * 0.25,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            // Suit symbol or character center
            Align(
              alignment: Alignment.center,
              child: Text(
                displayCard.suitSymbol,
                style: TextStyle(
                  color: displayCard.suitColor,
                  fontSize: (isWizard || isJester) ? width * 0.44 : width * 0.40,
                  height: 1.0,
                ),
              ),
            ),
            // Label bottom right for Wizard/Jester
            if (isWizard || isJester)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  isWizard ? 'WIZ' : 'JEST',
                  style: TextStyle(
                    color: displayCard.suitColor,
                    fontSize: width * 0.16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              )
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
