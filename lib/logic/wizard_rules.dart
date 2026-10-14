// Wizard Rules Engine for Flutter App
import '../models/card_model.dart';

class PlayedCard {
  final int playerIndex;
  final CardModel card;

  PlayedCard({required this.playerIndex, required this.card});
}

class TrickResult {
  final int winningPlayerIndex;
  final CardModel winningCard;
  final String reason;

  TrickResult({
    required this.winningPlayerIndex,
    required this.winningCard,
    required this.reason,
  });
}

Suit? getLedSuit(List<PlayedCard> trick) {
  if (trick.isEmpty) return null;
  for (final play in trick) {
    if (play.card.isWizard) return null;
    if (play.card.isSuit) return play.card.suit;
  }
  return null;
}

List<CardModel> getLegalCards(List<CardModel> hand, List<PlayedCard> trick) {
  if (trick.isEmpty) return List.from(hand);

  final ledSuit = getLedSuit(trick);
  if (ledSuit == null) return List.from(hand);

  final hasLedSuit = hand.any((c) => c.isSuit && c.suit == ledSuit);
  if (!hasLedSuit) return List.from(hand);

  return hand.where((c) {
    if (c.isWizard || c.isJester) return true;
    return c.suit == ledSuit;
  }).toList();
}

TrickResult? determineTrickWinner(List<PlayedCard> trick, Suit? trumpSuit) {
  if (trick.isEmpty) return null;

  // 1. First Wizard played
  final firstWizard = trick.where((p) => p.card.isWizard).toList();
  if (firstWizard.isNotEmpty) {
    return TrickResult(
      winningPlayerIndex: firstWizard.first.playerIndex,
      winningCard: firstWizard.first.card,
      reason: 'First Wizard',
    );
  }

  // 2. Highest Trump
  if (trumpSuit != null) {
    final trumps =
        trick.where((p) => p.card.isSuit && p.card.suit == trumpSuit).toList();
    if (trumps.isNotEmpty) {
      trumps.sort((a, b) => b.card.value.compareTo(a.card.value));
      return TrickResult(
        winningPlayerIndex: trumps.first.playerIndex,
        winningCard: trumps.first.card,
        reason: 'Highest Trump',
      );
    }
  }

  // 3. Highest Card of Led Suit
  final ledSuit = getLedSuit(trick);
  if (ledSuit != null) {
    final ledPlays =
        trick.where((p) => p.card.isSuit && p.card.suit == ledSuit).toList();
    if (ledPlays.isNotEmpty) {
      ledPlays.sort((a, b) => b.card.value.compareTo(a.card.value));
      return TrickResult(
        winningPlayerIndex: ledPlays.first.playerIndex,
        winningCard: ledPlays.first.card,
        reason: 'Highest Led Suit',
      );
    }
  }

  // 4. First Jester played
  final firstJester = trick.where((p) => p.card.isJester).toList();
  if (firstJester.isNotEmpty) {
    return TrickResult(
      winningPlayerIndex: firstJester.first.playerIndex,
      winningCard: firstJester.first.card,
      reason: 'First Jester',
    );
  }

  return TrickResult(
    winningPlayerIndex: trick.first.playerIndex,
    winningCard: trick.first.card,
    reason: 'Lead Card',
  );
}

int calculateRoundScore(int bid, int tricksWon) {
  if (bid == tricksWon) {
    return 20 + (10 * bid);
  }
  return -10 * (bid - tricksWon).abs();
}

int getMaxRounds(int numPlayers) {
  return (60 / numPlayers).floor();
}
