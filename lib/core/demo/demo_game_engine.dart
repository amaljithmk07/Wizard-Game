import 'dart:math';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/playing_card_adapter.dart';

class DemoGameEngine {
  static final DemoGameEngine _instance = DemoGameEngine._internal();
  factory DemoGameEngine() => _instance;
  DemoGameEngine._internal();

  dynamic _ref;
  late GameRoom _room;
  late List<GameCard> _deck;
  late Map<String, List<GameCard>> _playerHands;
  int _round = 5; // Start at round 5 for a rich multi-card fan demo!
  final int _totalRounds = 15;
  String? _ledSuit;

  void startDemo({required dynamic ref, required String playerName}) {
    _ref = ref;
    final name = playerName.isNotEmpty ? playerName : 'Player';

    final players = [
      Player(id: 'demo_me', name: name, isHost: true, score: 0),
      Player(id: 'demo_bot_1', name: 'Gandalf', isHost: false, score: 0),
      Player(id: 'demo_bot_2', name: 'Merlin', isHost: false, score: 0),
      Player(id: 'demo_bot_3', name: 'Morgana', isHost: false, score: 0),
    ];

    _room = GameRoom(
      id: 'offline_demo_room',
      name: 'Practice Table (Offline Demo)',
      hostId: 'demo_me',
      maxPlayers: 4,
      playerCount: 4,
      status: 'PLAYING',
      players: players,
    );

    _startRound(_round);
  }

  void _startRound(int round) {
    _round = round;
    _ledSuit = null;

    // Generate complete official 60-card deck and shuffle
    _deck = PlayingCardAdapter.create60CardDeck();
    _deck.shuffle(Random());

    _playerHands = {};
    for (final p in _room.players) {
      _playerHands[p.id] = [];
    }

    // Deal round cards to each player
    for (int i = 0; i < _round; i++) {
      for (final p in _room.players) {
        if (_deck.isNotEmpty) {
          _playerHands[p.id]!.add(_deck.removeLast());
        }
      }
    }

    // Ensure my hand has a Wizard and a Jester in round 5 to test all special card faces!
    if (_round >= 3 && _playerHands['demo_me']!.length >= 2) {
      final myHand = _playerHands['demo_me']!;
      if (!myHand.any((c) => c.isWizard)) {
        myHand[0] = GameCard(
          id: 'demo_wizard',
          suit: 'None',
          value: 99,
          name: 'Wizard',
          type: CardType.wizard,
        );
      }
      if (!myHand.any((c) => c.isJester)) {
        myHand[1] = GameCard(
          id: 'demo_jester',
          suit: 'None',
          value: 0,
          name: 'Jester',
          type: CardType.jester,
        );
      }
    }

    // Trump card
    GameCard? trumpCard;
    String? trumpSuit;
    if (_deck.isNotEmpty) {
      trumpCard = _deck.removeLast();
      if (trumpCard.isWizard) {
        trumpSuit = 'Spades';
      } else if (trumpCard.isJester) {
        trumpSuit = null; // No trump
      } else {
        trumpSuit = trumpCard.suit;
      }
    }

    // Update player hand counts
    final updatedPlayers = _room.players.map((p) {
      return p.copyWith(
        bid: null,
        tricksWon: 0,
        hand: (p.id == 'demo_me') ? _playerHands['demo_me']! : [],
      );
    }).toList();

    _room = _room.copyWith(
      players: updatedPlayers,
      gameState: GameStateModel(
        round: _round,
        totalRounds: _totalRounds,
        phase: 'BIDDING',
        trumpCard: trumpCard,
        trumpSuit: trumpSuit,
        dealerIndex: 0,
        currentTurnIndex: 0, // Me bids first
        playedCards: [],
      ),
    );

    _syncState();
  }

  void submitBid(int bid) {
    if (_ref == null) return;

    final players = List<Player>.from(_room.players);
    players[0] = players[0].copyWith(bid: bid);

    // Simulate bot bids
    final rand = Random();
    for (int i = 1; i < players.length; i++) {
      players[i] = players[i].copyWith(bid: rand.nextInt((_round / 2).ceil() + 1));
    }

    _room = _room.copyWith(
      players: players,
      gameState: _room.gameState!.copyWith(
        phase: 'TRICK',
        currentTurnIndex: 0, // Me leads first trick
      ),
    );

    _syncState();
  }

  void playCard(int cardIndex) {
    if (_ref == null) return;
    final myCards = _playerHands['demo_me']!;
    if (cardIndex < 0 || cardIndex >= myCards.length) return;

    final playedCard = myCards.removeAt(cardIndex);

    // Set led suit
    if (_ledSuit == null) {
      if (playedCard.isWizard) {
        _ledSuit = null;
      } else if (!playedCard.isJester) {
        _ledSuit = playedCard.suit;
      }
    }

    final trickCards = List<PlayedCardItem>.from(_room.gameState?.playedCards ?? []);
    trickCards.add(PlayedCardItem(
      playerId: 'demo_me',
      playerName: _room.players[0].name,
      card: playedCard,
    ));

    _room = _room.copyWith(
      gameState: _room.gameState!.copyWith(
        playedCards: trickCards,
        ledSuit: _ledSuit,
        currentTurnIndex: 1,
      ),
    );
    _syncState();

    // Trigger bot moves
    _playBotTurns(1);
  }

  void _playBotTurns(int botIndex) async {
    if (botIndex >= _room.players.length) {
      // Trick complete: resolve winner
      await Future.delayed(const Duration(milliseconds: 600));
      _resolveTrick();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));
    final bot = _room.players[botIndex];
    final botHand = _playerHands[bot.id]!;

    if (botHand.isNotEmpty) {
      // Find legal card
      GameCard botCard = botHand.first;
      if (_ledSuit != null) {
        final suited = botHand.where((c) => c.suit == _ledSuit);
        if (suited.isNotEmpty) {
          botCard = suited.first;
        }
      }
      botHand.remove(botCard);

      if (_ledSuit == null && !botCard.isWizard && !botCard.isJester) {
        _ledSuit = botCard.suit;
      }

      final trickCards = List<PlayedCardItem>.from(_room.gameState?.playedCards ?? []);
      trickCards.add(PlayedCardItem(
        playerId: bot.id,
        playerName: bot.name,
        card: botCard,
      ));

      _room = _room.copyWith(
        gameState: _room.gameState!.copyWith(
          playedCards: trickCards,
          ledSuit: _ledSuit,
          currentTurnIndex: (botIndex + 1) % _room.players.length,
        ),
      );
      _syncState();
    }

    _playBotTurns(botIndex + 1);
  }

  void _resolveTrick() async {
    final trickCards = _room.gameState!.playedCards;
    if (trickCards.isEmpty) return;

    final trumpSuit = _room.gameState!.trumpSuit;
    PlayedCardItem winner = trickCards[0];

    // Rule 5: 1) First Wizard wins
    final wizard = trickCards.where((c) => c.card.isWizard).toList();
    if (wizard.isNotEmpty) {
      winner = wizard.first;
    } else {
      // 2) Highest Trump
      final trumps = (trumpSuit != null && trumpSuit != 'None')
          ? trickCards.where((c) => c.card.suit.toLowerCase() == trumpSuit.toLowerCase()).toList()
          : <PlayedCardItem>[];

      if (trumps.isNotEmpty) {
        trumps.sort((a, b) => b.card.value.compareTo(a.card.value));
        winner = trumps.first;
      } else {
        // 3) Highest of led suit
        final led = (_ledSuit != null)
            ? trickCards.where((c) => c.card.suit.toLowerCase() == _ledSuit!.toLowerCase()).toList()
            : <PlayedCardItem>[];

        if (led.isNotEmpty) {
          led.sort((a, b) => b.card.value.compareTo(a.card.value));
          winner = led.first;
        } else {
          // 4) First card
          winner = trickCards[0];
        }
      }
    }

    // Award trick
    final players = _room.players.map((p) {
      if (p.id == winner.playerId) {
        return p.copyWith(tricksWon: p.tricksWon + 1);
      }
      return p;
    }).toList();

    _room = _room.copyWith(
      players: players,
      gameState: _room.gameState!.copyWith(
        trickWinnerName: winner.playerName,
      ),
    );
    _syncState();

    // Clear trick after 1.5 seconds and start next trick or round
    await Future.delayed(const Duration(milliseconds: 1400));
    _ledSuit = null;

    final bool allCardsPlayed = _playerHands['demo_me']!.isEmpty;
    if (allCardsPlayed) {
      // Calculate scores
      final scoredPlayers = _room.players.map((p) {
        final b = p.bid ?? 0;
        final w = p.tricksWon;
        int delta = 0;
        if (b == w) {
          delta = 20 + (w * 10);
        } else {
          delta = -10 * (b - w).abs();
        }
        return p.copyWith(score: p.score + delta);
      }).toList();

      _room = _room.copyWith(
        players: scoredPlayers,
        gameState: _room.gameState!.copyWith(
          phase: 'ROUND_OVER',
          playedCards: [],
          trickWinnerName: null,
          ledSuit: null,
        ),
      );
      _syncState();
    } else {
      _room = _room.copyWith(
        gameState: _room.gameState!.copyWith(
          playedCards: [],
          trickWinnerName: null,
          ledSuit: null,
          currentTurnIndex: 0, // Me leads
        ),
      );
      _syncState();
    }
  }

  void _syncState() {
    if (_ref == null) return;
    _ref!.read(currentRoomProvider.notifier).setRoomDirectly(_room);

    final myCards = _playerHands['demo_me'] ?? [];
    final isMyTurn = _room.gameState?.currentTurnIndex == 0;

    _ref!.read(gameProvider.notifier).setDemoState(
          myHand: myCards,
          isMyTurn: isMyTurn,
          turnPlayerName: isMyTurn ? _room.players[0].name : 'Opponent',
        );
  }
}
