import 'dart:math';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/playing_card_adapter.dart';

/// Offline single-device practice engine against 3 AI bots.
///
/// Enforces official Wizard rules:
///   • Round 1 deals 1 card each; Round R deals R cards.
///   • Bidding starts to the left of the dealer and goes clockwise.
///   • Player to the left of the dealer leads the first trick of each round.
///   • Trick winner leads the next trick.
///   • Dealer rotates one seat clockwise after every completed round.
///   • Scoring: correct bid = +20 + 10×tricks; wrong = -10×|diff|.
class DemoGameEngine {
  static final DemoGameEngine _instance = DemoGameEngine._internal();
  factory DemoGameEngine() => _instance;
  DemoGameEngine._internal();

  dynamic _ref;
  late GameRoom _room;
  late Map<String, List<GameCard>> _playerHands;

  // Persistent across rounds
  int _round = 1;
  int _totalRounds = 15; // 4 players = 15 rounds
  int _dealerIndex = 0;

  // Per-trick state
  String? _ledSuit;
  int _trickLeaderIndex = 0; // index of player who leads current trick

  // ─────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────

  void startDemo({required dynamic ref, required String playerName}) {
    _ref = ref;
    final name = playerName.isNotEmpty ? playerName : 'Player';

    _round = 1;
    _dealerIndex = 0; // Human starts as dealer in demo
    _totalRounds = 15;

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

    _startRound();
  }

  /// Called when the human player submits their bid.
  void submitBid(int bid) {
    if (_ref == null) return;

    // Clamp bid to valid range
    final clamped = bid.clamp(0, _round);
    var players = List<Player>.from(_room.players);
    players[0] = players[0].copyWith(bid: clamped);

    // Simulate bot bids
    final rand = Random();
    for (int i = 1; i < players.length; i++) {
      players[i] = players[i].copyWith(bid: rand.nextInt((_round / 2).ceil() + 1));
    }

    // Trick phase: player to dealer's left leads the first trick
    _trickLeaderIndex = (_dealerIndex + 1) % _room.players.length;
    _ledSuit = null;

    _room = _room.copyWith(
      players: players,
      gameState: _room.gameState!.copyWith(
        phase: 'TRICK',
        currentTurnIndex: _trickLeaderIndex,
        playedCards: [],
        ledSuit: null,
      ),
    );

    _syncState();

    // If it is not the human's turn, let bots go first
    if (_trickLeaderIndex != 0) {
      _playBotTurns(_trickLeaderIndex);
    }
  }

  /// Called when the human player taps "Play Selected Card".
  void playCard(int cardIndex) {
    if (_ref == null) return;

    final myCards = _playerHands['demo_me']!;
    if (cardIndex < 0 || cardIndex >= myCards.length) return;

    // Validate follow-suit rule
    if (!_isCardLegal(myCards[cardIndex], myCards)) return;

    final playedCard = myCards.removeAt(cardIndex);
    _updateLedSuit(playedCard, isFirstInTrick: _room.gameState!.playedCards.isEmpty);

    final trickCards = List<PlayedCardItem>.from(_room.gameState?.playedCards ?? []);
    trickCards.add(PlayedCardItem(
      playerId: 'demo_me',
      playerName: _room.players[0].name,
      card: playedCard,
    ));

    final nextTurnIndex = (_room.gameState!.currentTurnIndex + 1) % _room.players.length;

    _room = _room.copyWith(
      gameState: _room.gameState!.copyWith(
        playedCards: trickCards,
        ledSuit: _ledSuit,
        currentTurnIndex: nextTurnIndex,
      ),
    );
    _syncState();

    if (trickCards.length == _room.players.length) {
      // Human played last card in trick
      Future.delayed(const Duration(milliseconds: 600), _resolveTrick);
    } else {
      // Bots continue from nextTurnIndex
      _playBotTurns(nextTurnIndex);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Round management
  // ─────────────────────────────────────────────────────────────

  void _startRound() {
    _ledSuit = null;

    // Generate and shuffle full 60-card deck
    final deck = PlayingCardAdapter.create60CardDeck();
    deck.shuffle(Random());

    _playerHands = {};
    for (final p in _room.players) {
      _playerHands[p.id] = [];
    }

    // Deal _round cards to each player
    int deckIdx = 0;
    for (int card = 0; card < _round; card++) {
      for (final p in _room.players) {
        if (deckIdx < deck.length) {
          _playerHands[p.id]!.add(deck[deckIdx++]);
        }
      }
    }

    // Trump card is the next card after all dealt cards
    GameCard? trumpCard;
    String? trumpSuit;
    final trumpIdx = _round * _room.players.length;
    if (trumpIdx < deck.length) {
      trumpCard = deck[trumpIdx];
      if (trumpCard.isWizard) {
        trumpSuit = 'Spades'; // dealer picks; default Spades in demo
      } else if (trumpCard.isJester) {
        trumpSuit = null;
      } else {
        trumpSuit = trumpCard.suit;
      }
    }

    // Bidding starts to the dealer's left
    final biddingStartIndex = (_dealerIndex + 1) % _room.players.length;

    // Mark dealer on player objects and reset round stats
    final updatedPlayers = _room.players.asMap().entries.map((e) {
      return e.value.copyWith(
        bid: null,
        tricksWon: 0,
        hand: (e.value.id == 'demo_me') ? _playerHands['demo_me']! : [],
        isDealer: (e.key == _dealerIndex),
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
        dealerIndex: _dealerIndex,
        currentTurnIndex: biddingStartIndex,
        playedCards: [],
      ),
    );

    _syncState();
  }

  void _advanceToNextRound() {
    _round++;
    _dealerIndex = (_dealerIndex + 1) % _room.players.length;

    if (_round > _totalRounds) {
      _endGame();
      return;
    }

    _startRound();
  }

  void _endGame() {
    final sorted = List<Player>.from(_room.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    _room = _room.copyWith(
      status: 'FINISHED',
      gameState: _room.gameState!.copyWith(
        phase: 'GAME_OVER',
        winner: sorted.first.name,
      ),
    );
    _syncState();
  }

  // ─────────────────────────────────────────────────────────────
  // Bot AI
  // ─────────────────────────────────────────────────────────────

  /// Plays bot turns starting from [startBotIndex] (inclusive).
  /// Stops when it loops back to the human (index 0) or trick is complete.
  void _playBotTurns(int startBotIndex) async {
    int current = startBotIndex;

    while (true) {
      if (current == 0) break; // Human's turn – stop and let UI handle

      final trickCards = List<PlayedCardItem>.from(_room.gameState?.playedCards ?? []);
      if (trickCards.length >= _room.players.length) break; // Trick complete elsewhere

      await Future.delayed(const Duration(milliseconds: 450));

      final bot = _room.players[current];
      final botHand = _playerHands[bot.id]!;
      if (botHand.isEmpty) break;

      // Bot picks: follow suit if possible, else play first card
      GameCard botCard;
      if (_ledSuit != null) {
        final suited = botHand.where((c) => !c.isWizard && !c.isJester && c.suit == _ledSuit);
        botCard = suited.isNotEmpty ? suited.first : botHand.first;
      } else {
        botCard = botHand.first;
      }
      botHand.remove(botCard);
      _updateLedSuit(botCard, isFirstInTrick: trickCards.isEmpty);

      final updated = List<PlayedCardItem>.from(_room.gameState?.playedCards ?? []);
      updated.add(PlayedCardItem(
        playerId: bot.id,
        playerName: bot.name,
        card: botCard,
      ));

      final nextIdx = (current + 1) % _room.players.length;

      _room = _room.copyWith(
        gameState: _room.gameState!.copyWith(
          playedCards: updated,
          ledSuit: _ledSuit,
          currentTurnIndex: nextIdx,
        ),
      );
      _syncState();

      if (updated.length == _room.players.length) {
        // All players have played – resolve trick
        await Future.delayed(const Duration(milliseconds: 600));
        _resolveTrick();
        return;
      }

      current = nextIdx;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Trick resolution
  // ─────────────────────────────────────────────────────────────

  void _resolveTrick() async {
    final trickCards = _room.gameState!.playedCards;
    if (trickCards.isEmpty) return;

    final trumpSuit = _room.gameState!.trumpSuit;
    final winner = _determineTrickWinner(trickCards, trumpSuit, _ledSuit);

    // Award trick to winner
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
        playedCards: trickCards,
      ),
    );
    _syncState();

    await Future.delayed(const Duration(milliseconds: 1400));
    _ledSuit = null;

    // Trick winner leads next trick
    final winnerIndex = _room.players.indexWhere((p) => p.id == winner.playerId);
    _trickLeaderIndex = winnerIndex >= 0 ? winnerIndex : 0;

    // Round is over when all hands are empty (human hand is authoritative)
    final bool roundOver = _playerHands['demo_me']!.isEmpty;

    if (roundOver) {
      _handleRoundOver();
    } else {
      _room = _room.copyWith(
        gameState: _room.gameState!.copyWith(
          playedCards: [],
          trickWinnerName: null,
          ledSuit: null,
          currentTurnIndex: _trickLeaderIndex,
        ),
      );
      _syncState();

      // If a bot leads the next trick, start bot turns immediately
      if (_trickLeaderIndex != 0) {
        _playBotTurns(_trickLeaderIndex);
      }
    }
  }

  PlayedCardItem _determineTrickWinner(
    List<PlayedCardItem> played,
    String? trumpSuit,
    String? ledSuit,
  ) {
    // 1. First Wizard wins
    for (final item in played) {
      if (item.card.isWizard) return item;
    }

    // 2. Highest trump
    if (trumpSuit != null && trumpSuit.isNotEmpty && trumpSuit != 'None') {
      final trumps = played
          .where((c) => !c.card.isWizard && !c.card.isJester && c.card.suit.toLowerCase() == trumpSuit.toLowerCase())
          .toList();
      if (trumps.isNotEmpty) {
        trumps.sort((a, b) => b.card.value.compareTo(a.card.value));
        return trumps.first;
      }
    }

    // 3. Highest of led suit
    if (ledSuit != null) {
      final led = played
          .where((c) => !c.card.isWizard && !c.card.isJester && c.card.suit.toLowerCase() == ledSuit.toLowerCase())
          .toList();
      if (led.isNotEmpty) {
        led.sort((a, b) => b.card.value.compareTo(a.card.value));
        return led.first;
      }
    }

    // 4. All Jesters or first card wins
    return played.first;
  }

  // ─────────────────────────────────────────────────────────────
  // Round scoring
  // ─────────────────────────────────────────────────────────────

  void _handleRoundOver() {
    final roundScores = <Map<String, dynamic>>[];

    final scoredPlayers = _room.players.map((p) {
      final bid = p.bid ?? 0;
      final won = p.tricksWon;
      final delta = (bid == won) ? 20 + (won * 10) : -10 * (bid - won).abs();
      roundScores.add({
        'playerId': p.id,
        'playerName': p.name,
        'bid': bid,
        'tricksWon': won,
        'roundPoints': delta,
        'totalScore': p.score + delta,
      });
      return p.copyWith(score: p.score + delta);
    }).toList();

    _room = _room.copyWith(
      players: scoredPlayers,
      gameState: _room.gameState!.copyWith(
        phase: 'ROUND_OVER',
        playedCards: [],
        trickWinnerName: null,
        ledSuit: null,
        roundScores: roundScores,
      ),
    );
    _syncState();

    // Auto-advance to next round after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), _advanceToNextRound);
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  /// Updates [_ledSuit] based on the card played.
  void _updateLedSuit(GameCard card, {required bool isFirstInTrick}) {
    if (isFirstInTrick) {
      if (!card.isWizard && !card.isJester) {
        _ledSuit = card.suit;
      }
      // Wizard or Jester lead: no led suit yet
    } else if (_ledSuit == null && !card.isWizard && !card.isJester) {
      // Jester was led; first normal card sets the suit
      _ledSuit = card.suit;
    }
  }

  /// Returns true if playing [card] is legal given the player's [hand].
  bool _isCardLegal(GameCard card, List<GameCard> hand) {
    if (_ledSuit == null) return true;
    if (card.isWizard || card.isJester) return true;
    if (card.suit == _ledSuit) return true;
    final hasSuit = hand.any((c) => !c.isWizard && !c.isJester && c.suit == _ledSuit);
    return !hasSuit;
  }

  void _syncState() {
    if (_ref == null) return;
    _ref!.read(currentRoomProvider.notifier).setRoomDirectly(_room);

    final myCards = _playerHands['demo_me'] ?? [];
    final turnIndex = _room.gameState?.currentTurnIndex ?? 0;
    final isMyTurn = turnIndex == 0;
    final turnName = isMyTurn
        ? _room.players[0].name
        : (turnIndex < _room.players.length ? _room.players[turnIndex].name : 'Opponent');

    _ref!.read(gameProvider.notifier).setDemoState(
          myHand: myCards,
          isMyTurn: isMyTurn,
          turnPlayerName: turnName,
        );
  }
}
