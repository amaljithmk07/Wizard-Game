// Heuristic AI Bot for Flutter Wizard
import '../models/card_model.dart';
import 'wizard_rules.dart';

int calculateAIBid(
    List<CardModel> hand, Suit? trumpSuit, int roundNumber, int totalPlayers) {
  double expectedTricks = 0.0;

  for (final card in hand) {
    if (card.isWizard) {
      expectedTricks += 0.95;
    } else if (card.isJester) {
      expectedTricks += 0.05;
    } else if (card.suit == trumpSuit) {
      if (card.value >= 11) {
        expectedTricks += 0.85;
      } else if (card.value >= 8) {
        expectedTricks += 0.6;
      } else if (card.value >= 5) {
        expectedTricks += 0.35;
      } else {
        expectedTricks += 0.15;
      }
    } else {
      if (card.value >= 12) {
        expectedTricks += 0.6;
      } else if (card.value >= 10) {
        expectedTricks += 0.3;
      } else if (card.value >= 7) {
        expectedTricks += 0.1;
      }
    }
  }

  int finalBid = expectedTricks.round();
  return finalBid.clamp(0, hand.length);
}

Suit chooseAITrumpSuit(List<CardModel> hand) {
  final Map<Suit, int> suitCounts = {for (var s in Suit.values) s: 0};
  final Map<Suit, int> suitValues = {for (var s in Suit.values) s: 0};

  for (final card in hand) {
    if (card.isSuit) {
      suitCounts[card.suit!] = suitCounts[card.suit!]! + 1;
      suitValues[card.suit!] = suitValues[card.suit!]! + card.value;
    }
  }

  Suit bestSuit = Suit.human;
  int bestScore = -1;

  for (final suit in Suit.values) {
    final score = (suitCounts[suit]! * 10) + suitValues[suit]!;
    if (score > bestScore) {
      bestScore = score;
      bestSuit = suit;
    }
  }

  return bestSuit;
}

CardModel selectAICard(
  List<CardModel> hand,
  List<PlayedCard> trick,
  Suit? trumpSuit,
  int playerBid,
  int playerTricksWon,
) {
  final legalCards = getLegalCards(hand, trick);
  if (legalCards.length == 1) return legalCards.first;

  final tricksNeeded = playerBid - playerTricksWon;
  final wantToWin = tricksNeeded > 0;

  if (trick.isEmpty) {
    if (wantToWin) {
      final wizards = legalCards.where((c) => c.isWizard).toList();
      if (wizards.isNotEmpty && tricksNeeded >= wizards.length) {
        return wizards.first;
      }
      final trumps = legalCards.where((c) => c.suit == trumpSuit).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (trumps.isNotEmpty && trumps.first.value >= 10) {
        return trumps.first;
      }
      legalCards.sort((a, b) => b.value.compareTo(a.value));
      return legalCards.first;
    } else {
      final jesters = legalCards.where((c) => c.isJester).toList();
      if (jesters.isNotEmpty) return jesters.first;

      legalCards.sort((a, b) => a.value.compareTo(b.value));
      return legalCards.first;
    }
  }

  if (wantToWin) {
    final winningCards = legalCards.where((card) {
      final sim = [...trick, PlayedCard(playerIndex: 99, card: card)];
      final winner = determineTrickWinner(sim, trumpSuit);
      return winner?.winningCard == card;
    }).toList();

    if (winningCards.isNotEmpty) {
      winningCards.sort((a, b) {
        int cost(CardModel c) {
          if (c.isSuit && c.suit != trumpSuit) return c.value;
          if (c.isSuit && c.suit == trumpSuit) return 20 + c.value;
          return 50;
        }

        return cost(a).compareTo(cost(b));
      });
      return winningCards.first;
    } else {
      final jesters = legalCards.where((c) => c.isJester).toList();
      if (jesters.isNotEmpty) return jesters.first;
      legalCards.sort((a, b) => a.value.compareTo(b.value));
      return legalCards.first;
    }
  } else {
    final losingCards = legalCards.where((card) {
      final sim = [...trick, PlayedCard(playerIndex: 99, card: card)];
      final winner = determineTrickWinner(sim, trumpSuit);
      return winner?.winningCard != card;
    }).toList();

    if (losingCards.isNotEmpty) {
      final jesters = losingCards.where((c) => c.isJester).toList();
      if (jesters.isNotEmpty) return jesters.first;

      losingCards.sort((a, b) => b.value.compareTo(a.value));
      return losingCards.first;
    } else {
      legalCards.sort((a, b) => a.value.compareTo(b.value));
      return legalCards.first;
    }
  }
}
