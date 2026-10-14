import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  final CardModel? card;
  final bool isPlayable;
  final bool isDisabled;
  final bool isSmall;
  final bool isFaceDown;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    this.card,
    this.isPlayable = true,
    this.isDisabled = false,
    this.isSmall = false,
    this.isFaceDown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = isSmall ? 48.0 : 68.0;
    final height = isSmall ? 72.0 : 102.0;

    if (isFaceDown) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
          border: Border.all(
              color: const Color(0xFFF1C40F), width: isSmall ? 1.5 : 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                color: const Color(0xFFF1C40F), size: isSmall ? 14 : 22),
            if (!isSmall)
              const Text(
                'WIZARD',
                style: TextStyle(
                  color: Color(0xFFF1C40F),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      );
    }

    if (card == null) return const SizedBox.shrink();

    Color borderColor;
    List<Color> gradientColors;

    if (card!.isWizard) {
      borderColor = const Color(0xFFA855F7);
      gradientColors = [const Color(0xFF581C87), const Color(0xFF1E1B4B)];
    } else if (card!.isJester) {
      borderColor = const Color(0xFF06B6D4);
      gradientColors = [const Color(0xFF164E63), const Color(0xFF0F172A)];
    } else {
      borderColor = Color(suitsData[card!.suit]!.colorHex);
      gradientColors = [const Color(0xFF1E293B), const Color(0xFF0F172A)];
    }

    final displayVal =
        card!.isWizard ? 'Z' : (card!.isJester ? 'N' : '${card!.value}');
    final symbol = card!.isWizard
        ? '👑'
        : (card!.isJester ? '🤡' : suitsData[card!.suit]!.symbol);

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: (isPlayable && !isDisabled) ? onTap : null,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmall ? 6 : 10),
            border: Border.all(color: borderColor, width: isSmall ? 1.5 : 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: isSmall ? 4 : 8,
                spreadRadius: 1,
              ),
            ],
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(isSmall ? 2 : 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    displayVal,
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.w900,
                      fontSize: isSmall ? 10 : 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(symbol, style: TextStyle(fontSize: isSmall ? 9 : 11)),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(symbol, style: TextStyle(fontSize: isSmall ? 18 : 28)),
                  if (!isSmall)
                    Text(
                      card!.isWizard
                          ? 'WIZARD'
                          : (card!.isJester
                              ? 'JESTER'
                              : suitsData[card!.suit]!.name.toUpperCase()),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(symbol, style: TextStyle(fontSize: isSmall ? 9 : 11)),
                    const SizedBox(width: 2),
                    Text(
                      displayVal,
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isSmall ? 10 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
