// Card Model & Deck Generator for Flutter Wizard
enum CardType { suit, wizard, jester }

enum Suit { human, elf, dwarf, giant }

class SuitInfo {
  final Suit suit;
  final String name;
  final String symbol;
  final int colorHex;

  const SuitInfo({
    required this.suit,
    required this.name,
    required this.symbol,
    required this.colorHex,
  });
}

const Map<Suit, SuitInfo> suitsData = {
  Suit.human: SuitInfo(
      suit: Suit.human, name: 'Human', symbol: '🔥', colorHex: 0xFFFF4D4D),
  Suit.elf:
      SuitInfo(suit: Suit.elf, name: 'Elf', symbol: '🍃', colorHex: 0xFF2ECC71),
  Suit.dwarf: SuitInfo(
      suit: Suit.dwarf, name: 'Dwarf', symbol: '🛡️', colorHex: 0xFFF1C40F),
  Suit.giant: SuitInfo(
      suit: Suit.giant, name: 'Giant', symbol: '🌊', colorHex: 0xFF3498DB),
};

class CardModel {
  final String id;
  final Suit? suit;
  final int value;
  final CardType type;
  final String name;

  const CardModel({
    required this.id,
    this.suit,
    required this.value,
    required this.type,
    required this.name,
  });

  bool get isWizard => type == CardType.wizard;
  bool get isJester => type == CardType.jester;
  bool get isSuit => type == CardType.suit;
}

List<CardModel> createDeck() {
  final List<CardModel> deck = [];

  for (final suit in Suit.values) {
    for (int value = 1; value <= 13; value++) {
      deck.add(CardModel(
        id: '${suit.name}-$value',
        suit: suit,
        value: value,
        type: CardType.suit,
        name: '$value of ${suitsData[suit]!.name}',
      ));
    }
  }

  for (int i = 1; i <= 4; i++) {
    deck.add(CardModel(
      id: 'wizard-$i',
      value: 14,
      type: CardType.wizard,
      name: 'Wizard Z',
    ));
  }

  for (int i = 1; i <= 4; i++) {
    deck.add(CardModel(
      id: 'jester-$i',
      value: 0,
      type: CardType.jester,
      name: 'Jester N',
    ));
  }

  return deck;
}

List<CardModel> shuffleDeck(List<CardModel> deck) {
  final List<CardModel> shuffled = List.from(deck);
  shuffled.shuffle();
  return shuffled;
}

class DealResult {
  final List<List<CardModel>> hands;
  final CardModel? trumpCard;

  DealResult({required this.hands, this.trumpCard});
}

DealResult dealRound(List<CardModel> deck, int numPlayers, int roundNumber) {
  final List<List<CardModel>> hands = List.generate(numPlayers, (_) => []);
  int deckIndex = 0;

  for (int c = 0; c < roundNumber; c++) {
    for (int p = 0; p < numPlayers; p++) {
      hands[p].add(deck[deckIndex++]);
    }
  }

  CardModel? trumpCard;
  if (deckIndex < deck.length) {
    trumpCard = deck[deckIndex];
  }

  return DealResult(hands: hands, trumpCard: trumpCard);
}

List<CardModel> sortHand(List<CardModel> hand, Suit? trumpSuit) {
  final List<CardModel> sorted = List.from(hand);
  sorted.sort((a, b) {
    int getWeight(CardModel card) {
      if (card.isWizard) return 0;
      if (card.suit == trumpSuit) return 1;
      if (card.isJester) return 99;
      const order = [Suit.human, Suit.elf, Suit.dwarf, Suit.giant];
      return 2 + order.indexOf(card.suit!);
    }

    final wA = getWeight(a);
    final wB = getWeight(b);
    if (wA != wB) return wA.compareTo(wB);
    return b.value.compareTo(a.value);
  });
  return sorted;
}
