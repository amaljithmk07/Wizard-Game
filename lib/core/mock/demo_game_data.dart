import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/player.dart';

/// Pre-populated mock rooms for Demo Mode.
List<GameRoom> getInitialDemoRooms() {
  return [
    GameRoom(
      id: 'demo_room_dragon',
      name: '🐉 Dragon\'s Keep',
      hostId: 'bot_gandalf',
      maxPlayers: 4,
      playerCount: 2,
      status: 'WAITING',
      players: [
        Player(id: 'bot_gandalf', name: 'Gandalf', isHost: true),
        Player(id: 'bot_merlin', name: 'Merlin', isHost: false),
      ],
    ),
    GameRoom(
      id: 'demo_room_lightning',
      name: '⚡ Lightning Arena',
      hostId: 'bot_morgana',
      maxPlayers: 2,
      playerCount: 1,
      status: 'WAITING',
      players: [
        Player(id: 'bot_morgana', name: 'Morgana', isHost: true),
      ],
    ),
    GameRoom(
      id: 'demo_room_sanctum',
      name: '🔮 Mystic Sanctum',
      hostId: 'bot_dumbledore',
      maxPlayers: 4,
      playerCount: 3,
      status: 'WAITING',
      players: [
        Player(id: 'bot_dumbledore', name: 'Dumbledore', isHost: true),
        Player(id: 'bot_elminster', name: 'Elminster', isHost: false),
        Player(id: 'bot_raistlin', name: 'Raistlin', isHost: false),
      ],
    ),
  ];
}

/// Generates a standard shuffled deck of 52 playing cards.
List<GameCard> generateDemoDeck() {
  final suits = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];
  final List<GameCard> deck = [];
  int id = 1;

  for (final suit in suits) {
    for (int val = 2; val <= 14; val++) {
      String displayVal = val.toString();
      if (val == 11) displayVal = 'J';
      if (val == 12) displayVal = 'Q';
      if (val == 13) displayVal = 'K';
      if (val == 14) displayVal = 'A';

      String symbol = '♠';
      if (suit == 'Hearts') symbol = '♥';
      if (suit == 'Diamonds') symbol = '♦';
      if (suit == 'Clubs') symbol = '♣';

      deck.add(GameCard(
        id: 'demo_card_${id++}',
        suit: suit,
        value: val,
        name: '$displayVal $symbol',
      ));
    }
  }
  deck.shuffle();
  return deck;
}
