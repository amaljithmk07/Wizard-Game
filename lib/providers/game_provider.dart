import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/mock/demo_game_data.dart';
import '../../core/network/socket_service.dart';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'player_provider.dart';
import 'room_provider.dart';

class GameState {
  final List<GameCard> myHand;
  final int selectedCardIndex;
  final bool isMyTurn;
  final String currentTurnPlayerName;
  final String? winnerName;
  final List<Player> finalScores;

  GameState({
    this.myHand = const [],
    this.selectedCardIndex = -1,
    this.isMyTurn = false,
    this.currentTurnPlayerName = '',
    this.winnerName,
    this.finalScores = const [],
  });

  GameState copyWith({
    List<GameCard>? myHand,
    int? selectedCardIndex,
    bool? isMyTurn,
    String? currentTurnPlayerName,
    String? winnerName,
    List<Player>? finalScores,
  }) {
    return GameState(
      myHand: myHand ?? this.myHand,
      selectedCardIndex: selectedCardIndex ?? this.selectedCardIndex,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      currentTurnPlayerName:
          currentTurnPlayerName ?? this.currentTurnPlayerName,
      winnerName: winnerName ?? this.winnerName,
      finalScores: finalScores ?? this.finalScores,
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;
  int _userDemoScore = 0;
  int _botDemoScore = 0;
  Timer? _botTurnTimer;
  Timer? _trickClearTimer;

  GameNotifier(this._ref) : super(GameState()) {
    _initSocket();
  }

  @override
  void dispose() {
    _botTurnTimer?.cancel();
    _trickClearTimer?.cancel();
    super.dispose();
  }

  void _initSocket() {
    if (AppConfig.isDemoMode) return;

    final socket = SocketService();

    socket.on('room_updated', (data) {
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final room = GameRoom.fromJson(mapData);
        final mySocketId = socket.socketId;

        final rawPlayers = (mapData['players'] as List? ?? []);
        Map<String, dynamic>? myPlayerMap;
        for (final p in rawPlayers) {
          if (p is Map && p['id'] == mySocketId) {
            myPlayerMap = Map<String, dynamic>.from(p);
            break;
          }
        }

        List<GameCard> hand = [];
        if (myPlayerMap != null && myPlayerMap['hand'] != null) {
          final rawHand = myPlayerMap['hand'] as List;
          hand = rawHand
              .whereType<Map>()
              .map((c) => GameCard.fromJson(Map<String, dynamic>.from(c)))
              .toList();
        }

        bool myTurn = false;
        String turnName = '';
        if (mapData['gameState'] != null && mapData['gameState'] is Map) {
          final gs = mapData['gameState'] as Map;
          int turnIdx = gs['currentTurnIndex'] ?? 0;
          if (turnIdx >= 0 && turnIdx < room.players.length) {
            final turnPlayer = room.players[turnIdx];
            turnName = turnPlayer.name;
            myTurn = (turnPlayer.id == mySocketId);
          }
        }

        state = state.copyWith(
          myHand: hand,
          isMyTurn: myTurn,
          currentTurnPlayerName: turnName,
        );
      }
    });

    socket.on('game_finished', (data) {
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final winner = mapData['winner'] ?? 'Winner';
        var rawScores = mapData['players'] as List? ?? [];
        List<Player> scores = rawScores
            .whereType<Map>()
            .map((p) => Player.fromJson(Map<String, dynamic>.from(p)))
            .toList();

        state = state.copyWith(
          winnerName: winner,
          finalScores: scores,
        );
      }
    });
  }

  void initDemoGame(GameRoom room) {
    _userDemoScore = 0;
    _botDemoScore = 0;

    final user = room.players.firstWhere(
      (p) => p.id == 'demo_player_local' || !p.id.startsWith('bot_'),
      orElse: () => room.players.first,
    );

    state = state.copyWith(
      myHand: List<GameCard>.from(user.hand),
      selectedCardIndex: -1,
      isMyTurn: true,
      currentTurnPlayerName: 'Your',
      winnerName: null,
      finalScores: [],
    );
  }

  void selectCard(int index) {
    if (state.selectedCardIndex == index) {
      state = state.copyWith(selectedCardIndex: -1);
    } else {
      state = state.copyWith(selectedCardIndex: index);
    }
  }

  void playSelectedCard() {
    if (state.selectedCardIndex < 0 ||
        state.selectedCardIndex >= state.myHand.length) {
      return;
    }

    if (AppConfig.isDemoMode) {
      _playDemoCard();
      return;
    }

    SocketService().emit('play_card', {
      'cardIndex': state.selectedCardIndex,
    });
    state = state.copyWith(selectedCardIndex: -1);
  }

  void _playDemoCard() {
    final playedCard = state.myHand[state.selectedCardIndex];
    final updatedHand = List<GameCard>.from(state.myHand)
      ..removeAt(state.selectedCardIndex);

    final room = _ref.read(currentRoomProvider);
    if (room == null) return;

    final userName = _ref.read(playerNameProvider);
    final userItem = PlayedCardItem(
      playerId: 'demo_player_local',
      playerName: userName.isNotEmpty ? userName : 'You',
      card: playedCard,
    );

    final bot = room.players.firstWhere(
      (p) => p.id != 'demo_player_local',
      orElse: () => Player(id: 'bot_merlin', name: 'Merlin', isHost: false),
    );

    // Place user card on table
    _ref.read(currentRoomProvider.notifier).updateDemoGameState(
          players: room.players,
          gameState: GameStateModel(
            currentTurnIndex: 1,
            playedCards: [userItem],
          ),
        );

    state = state.copyWith(
      myHand: updatedHand,
      selectedCardIndex: -1,
      isMyTurn: false,
      currentTurnPlayerName: bot.name,
    );

    // Simulate Bot opponent response
    _botTurnTimer?.cancel();
    _botTurnTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      final currentRoom = _ref.read(currentRoomProvider);
      if (currentRoom == null) return;

      GameCard botCard;
      final botPlayerIndex =
          currentRoom.players.indexWhere((p) => p.id == bot.id);
      List<Player> updatedPlayers = List<Player>.from(currentRoom.players);

      if (botPlayerIndex != -1 &&
          updatedPlayers[botPlayerIndex].hand.isNotEmpty) {
        final botHand =
            List<GameCard>.from(updatedPlayers[botPlayerIndex].hand);
        botCard = botHand.removeAt(0);
        updatedPlayers[botPlayerIndex] =
            updatedPlayers[botPlayerIndex].copyWith(hand: botHand);
      } else {
        botCard = generateDemoDeck().first;
      }

      final botItem = PlayedCardItem(
        playerId: bot.id,
        playerName: bot.name,
        card: botCard,
      );

      // Evaluate trick winner
      final bool userWonTrick = playedCard.value >= botCard.value;
      if (userWonTrick) {
        _userDemoScore += 10;
      } else {
        _botDemoScore += 10;
      }

      // Update player scores in room
      updatedPlayers = updatedPlayers.map((p) {
        if (p.id == 'demo_player_local') {
          return p.copyWith(score: _userDemoScore);
        } else if (p.id == bot.id) {
          return p.copyWith(score: _botDemoScore);
        }
        return p;
      }).toList();

      // Table shows both cards
      _ref.read(currentRoomProvider.notifier).updateDemoGameState(
            players: updatedPlayers,
            gameState: GameStateModel(
              currentTurnIndex: 0,
              playedCards: [userItem, botItem],
            ),
          );

      // Clear table after a brief pause and determine if game finishes
      _trickClearTimer?.cancel();
      _trickClearTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;

        final activeRoom = _ref.read(currentRoomProvider);
        if (activeRoom == null) return;

        if (updatedHand.isEmpty) {
          // Game over: determine winner
          final displayName = userName.isNotEmpty ? userName : 'You';
          final winner =
              _userDemoScore >= _botDemoScore ? displayName : bot.name;

          _ref.read(currentRoomProvider.notifier).updateDemoGameState(
                players: updatedPlayers,
                gameState: GameStateModel(
                  currentTurnIndex: 0,
                  playedCards: [],
                  winner: winner,
                ),
              );

          state = state.copyWith(
            winnerName: winner,
            finalScores: updatedPlayers,
          );
        } else {
          // Continue round: User's turn again
          _ref.read(currentRoomProvider.notifier).updateDemoGameState(
                players: updatedPlayers,
                gameState: GameStateModel(
                  currentTurnIndex: 0,
                  playedCards: [],
                ),
              );

          state = state.copyWith(
            isMyTurn: true,
            currentTurnPlayerName: 'Your',
          );
        }
      });
    });
  }

  void resetGame() {
    _botTurnTimer?.cancel();
    _trickClearTimer?.cancel();
    _userDemoScore = 0;
    _botDemoScore = 0;
    state = GameState();
  }
}
