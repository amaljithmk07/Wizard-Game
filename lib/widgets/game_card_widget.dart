import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import '../models/game_card.dart';
import 'card_back_widget.dart';
import 'jester_card_widget.dart';
import 'playing_card_adapter.dart';
import 'wizard_card_widget.dart';

class GameCardWidget extends StatelessWidget {
  final GameCard? card;
  final bool isFaceDown;
  final bool isSelected;
  final bool isPlayable;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double elevation;

  const GameCardWidget({
    super.key,
    this.card,
    this.isFaceDown = false,
    this.isSelected = false,
    this.isPlayable = true,
    this.onTap,
    this.width = 62,
    this.height = 88,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isFaceDown || card == null) {
      return CardBackWidget(
        width: width,
        height: height,
        elevation: elevation,
      );
    }

    final currentCard = card!;
    final bool isWizard = currentCard.isWizard;
    final bool isJester = currentCard.isJester;
    final playingCard = PlayingCardAdapter.toPlayingCard(currentCard);

    Widget cardFace;
    if (isWizard) {
      cardFace = WizardCardWidget(
        width: width,
        height: height,
        elevation: isSelected ? elevation + 2 : elevation,
      );
    } else if (isJester) {
      cardFace = JesterCardWidget(
        width: width,
        height: height,
        elevation: isSelected ? elevation + 2 : elevation,
      );
    } else if (playingCard != null) {
      cardFace = SizedBox(
        width: width,
        height: height,
        child: PlayingCardView(
          card: playingCard,
          showBack: false,
          elevation: isSelected ? elevation + 2 : elevation,
        ),
      );
    } else {
      cardFace = CardBackWidget(
        width: width,
        height: height,
        elevation: elevation,
      );
    }

    // Apply selection highlight ring and playable/disabled opacity
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, isSelected ? -14 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          cardFace,

          // If not playable, visually dim and disable
          if (!isPlayable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

          // Selection border highlight
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 2.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
