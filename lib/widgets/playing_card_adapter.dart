import 'package:playing_cards/playing_cards.dart';
import '../models/game_card.dart';

class PlayingCardAdapter {
  static Suit? suitFromGameCard(GameCard card) {
    if (card.isWizard || card.isJester) return null;
    switch (card.suit.toLowerCase()) {
      case 'spades':
        return Suit.spades;
      case 'hearts':
        return Suit.hearts;
      case 'diamonds':
        return Suit.diamonds;
      case 'clubs':
        return Suit.clubs;
      default:
        return Suit.spades;
    }
  }

  static CardValue? valueFromGameCard(GameCard card) {
    if (card.isWizard || card.isJester) return null;
    switch (card.value) {
      case 2:
        return CardValue.two;
      case 3:
        return CardValue.three;
      case 4:
        return CardValue.four;
      case 5:
        return CardValue.five;
      case 6:
        return CardValue.six;
      case 7:
        return CardValue.seven;
      case 8:
        return CardValue.eight;
      case 9:
        return CardValue.nine;
      case 10:
        return CardValue.ten;
      case 11:
        return CardValue.jack;
      case 12:
        return CardValue.queen;
      case 13:
        return CardValue.king;
      case 14:
        return CardValue.ace;
      default:
        return CardValue.two;
    }
  }

  static PlayingCard? toPlayingCard(GameCard card) {
    if (card.isWizard || card.isJester) return null;
    final suit = suitFromGameCard(card);
    final val = valueFromGameCard(card);
    if (suit == null || val == null) return null;
    return PlayingCard(suit, val);
  }

  /// Generates the complete official 60-card Wizard deck.
  /// Each physical card has a guaranteed unique ID.
  static List<GameCard> create60CardDeck() {
    final List<GameCard> deck = [];
    final suits = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];

    // 52 Standard Cards (2..14)
    for (final suit in suits) {
      for (int v = 2; v <= 14; v++) {
        String name;
        switch (v) {
          case 11:
            name = 'Jack of $suit';
            break;
          case 12:
            name = 'Queen of $suit';
            break;
          case 13:
            name = 'King of $suit';
            break;
          case 14:
            name = 'Ace of $suit';
            break;
          default:
            name = '$v of $suit';
        }
        deck.add(GameCard(
          id: '${suit.toLowerCase()}_$v',
          suit: suit,
          value: v,
          name: name,
          type: CardType.normal,
        ));
      }
    }

    // 4 Wizards (unique IDs wizard_1 .. wizard_4)
    for (int i = 1; i <= 4; i++) {
      deck.add(GameCard(
        id: 'wizard_$i',
        suit: 'None',
        value: 99,
        name: 'Wizard #$i',
        type: CardType.wizard,
      ));
    }

    // 4 Jesters (unique IDs jester_1 .. jester_4)
    for (int i = 1; i <= 4; i++) {
      deck.add(GameCard(
        id: 'jester_$i',
        suit: 'None',
        value: 0,
        name: 'Jester #$i',
        type: CardType.jester,
      ));
    }

    return deck;
  }

  /// Evaluates whether a specific card in a hand is legally playable.
  /// Standard Wizard rules:
  /// - Wizard and Jester can ALWAYS be played.
  /// - If no suit led, any card can be played.
  /// - If suit led, player must follow suit if they hold any card of that suit.
  /// - If player does not hold any card of led suit, any card can be played.
  static bool isCardLegalToPlay({
    required GameCard card,
    required List<GameCard> hand,
    required String? ledSuit,
    required bool isMyTurn,
    required bool isTrickPhase,
  }) {
    if (!isMyTurn || !isTrickPhase) return false;

    // Wizards and Jesters can always be played
    if (card.isWizard || card.isJester) return true;

    // If no suit led yet, any card is valid
    if (ledSuit == null || ledSuit.isEmpty || ledSuit == 'None') return true;

    // Check if hand holds any card of the led suit
    final hasLedSuit = hand.any((c) =>
        !c.isWizard &&
        !c.isJester &&
        c.suit.toLowerCase() == ledSuit.toLowerCase());

    if (!hasLedSuit) {
      // Void in led suit: any card may be played
      return true;
    }

    // Must follow led suit
    return card.suit.toLowerCase() == ledSuit.toLowerCase();
  }
}
