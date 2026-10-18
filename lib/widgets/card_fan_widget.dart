import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_card.dart';
import 'game_card_widget.dart';
import 'playing_card_adapter.dart';

class CardFanWidget extends StatelessWidget {
  final List<GameCard> cards;
  final int selectedIndex;
  final ValueChanged<int>? onCardSelected;
  final String? ledSuit;
  final bool isMyTurn;
  final bool isTrickPhase;

  const CardFanWidget({
    super.key,
    required this.cards,
    this.selectedIndex = -1,
    this.onCardSelected,
    this.ledSuit,
    this.isMyTurn = false,
    this.isTrickPhase = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No cards in hand',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardCount = cards.length;

        // Responsive card dimensions based on screen width
        double cardWidth = 62.0;
        double cardHeight = 88.0;

        if (availableWidth < 360) {
          cardWidth = 54.0;
          cardHeight = 78.0;
        } else if (availableWidth > 600) {
          cardWidth = 72.0;
          cardHeight = 102.0;
        }

        // Calculate card overlap
        // If single card: centered
        if (cardCount == 1) {
          final isLegal = PlayingCardAdapter.isCardLegalToPlay(
            card: cards[0],
            hand: cards,
            ledSuit: ledSuit,
            isMyTurn: isMyTurn,
            isTrickPhase: isTrickPhase,
          );

          return SizedBox(
            height: cardHeight + 24,
            child: Center(
              child: GameCardWidget(
                card: cards[0],
                width: cardWidth,
                height: cardHeight,
                isSelected: selectedIndex == 0,
                isPlayable: isLegal,
                onTap: () => onCardSelected?.call(0),
              ),
            ),
          );
        }

        // Available space for the fan
        final maxFanWidth = availableWidth - 16;
        final double maxSpacing = cardWidth * 0.70; // when few cards
        const double minSpacing = 22.0; // minimum visible rank strip

        double spacing = (maxFanWidth - cardWidth) / (cardCount - 1);
        spacing = spacing.clamp(minSpacing, maxSpacing);

        final totalFanWidth = cardWidth + spacing * (cardCount - 1);
        final bool needsScroll = totalFanWidth > maxFanWidth;

        Widget fanContent = SizedBox(
          width: totalFanWidth,
          height: cardHeight + 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(cardCount, (index) {
              final card = cards[index];
              final bool isSelected = selectedIndex == index;

              final isLegal = PlayingCardAdapter.isCardLegalToPlay(
                card: card,
                hand: cards,
                ledSuit: ledSuit,
                isMyTurn: isMyTurn,
                isTrickPhase: isTrickPhase,
              );

              // Subtle fan rotation arc from -8° to +8°
              final double normalized = (index - (cardCount - 1) / 2.0) /
                  (cardCount > 1 ? (cardCount - 1) / 2.0 : 1.0);
              final double rotationAngle = normalized * (math.pi / 28); // ~6.4 deg max

              // Slight arc curvature in Y
              final double arcY = math.pow(normalized, 2) * 6.0;

              return Positioned(
                left: index * spacing,
                top: 14 + arcY,
                child: Transform.rotate(
                  angle: rotationAngle,
                  alignment: Alignment.bottomCenter,
                  child: GameCardWidget(
                    card: card,
                    width: cardWidth,
                    height: cardHeight,
                    isSelected: isSelected,
                    isPlayable: isLegal,
                    elevation: isSelected ? 5.0 : 2.0,
                    onTap: () => onCardSelected?.call(index),
                  ),
                ),
              );
            }),
          ),
        );

        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: fanContent,
          );
        }

        return Center(child: fanContent);
      },
    );
  }
}
