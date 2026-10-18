import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/demo/demo_game_engine.dart';
import '../../core/network/socket_service.dart';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/player.dart';

class GameState {
  final List<GameCard> myHand;
  final int selectedCardIndex;
  final bool isMyTurn;
  final String currentTurnPlayerName;
  final String? errorMessage;
  final String? winnerName;
  final List<Player> finalScores;
  final List<Map<String, dynamic>> finalStandings;

  GameState({
    this.myHand = const [],
    this.selectedCardIndex = -1,
    this.isMyTurn = false,
    this.currentTurnPlayerName = '',
    this.errorMessage,
    this.winnerName,
    this.finalScores = const [],
    this.finalStandings = const [],
  });

  GameState copyWith({
    List<GameCard>? myHand,
    int? selectedCardIndex,
    bool? isMyTurn,
    String? currentTurnPlayerName,
    String? errorMessage,
    String? winnerName,
    List<Player>? finalScores,
    List<Map<String, dynamic>>? finalStandings,
  }) {
    return GameState(
      myHand: myHand ?? this.myHand,
      selectedCardIndex: selectedCardIndex ?? this.selectedCardIndex,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      currentTurnPlayerName:
          currentTurnPlayerName ?? this.currentTurnPlayerName,
      errorMessage: errorMessage,
      winnerName: winnerName ?? this.winnerName,
      finalScores: finalScores ?? this.finalScores,
      finalStandings: finalStandings ?? this.finalStandings,
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier([Ref? ref]) : super(GameState()) {
    _initSocket();
  }

  void _initSocket() {
    final socket = SocketService();

    socket.on('room_updated', (data) {
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final room = GameRoom.fromJson(mapData);
        final mySocketId = socket.socketId;

        // Extract own private hand
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
        if (room.gameState != null) {
          int turnIdx = room.gameState!.currentTurnIndex;
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
          errorMessage: null,
        );
      }
    });

    socket.on('game_finished', (data) {
      if (data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        final winner = mapData['winner']?.toString() ?? 'Winner';
        final rawStandings = mapData['standings'] as List? ?? [];
        final standings = rawStandings
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList();

        final players = standings
            .map((s) => Player(
                  id: '',
                  name: s['name']?.toString() ?? '',
                  score: (s['score'] is num) ? (s['score'] as num).toInt() : 0,
                ))
            .toList();

        state = state.copyWith(
          winnerName: winner,
          finalStandings: standings,
          finalScores: players,
        );
      }
    });

    socket.on('error', (data) {
      if (data is Map && data['message'] != null) {
        final msg = data['message'].toString();
        if (kDebugMode) print('[Game Error]: $msg');
        state = state.copyWith(errorMessage: msg);
      }
    });
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void selectCard(int index) {
    if (state.selectedCardIndex == index) {
      state = state.copyWith(selectedCardIndex: -1);
    } else {
      state = state.copyWith(selectedCardIndex: index);
    }
  }

  void submitBid(int bid) {
    if (AppConfig.isDemoMode) {
      DemoGameEngine().submitBid(bid);
      return;
    }
    SocketService().emit('submit_bid', {'bid': bid});
  }

  void chooseTrump(String suit) {
    SocketService().emit('choose_trump_suit', {'suit': suit});
  }

  void playSelectedCard() {
    if (state.selectedCardIndex < 0 ||
        state.selectedCardIndex >= state.myHand.length) {
      return;
    }

    if (AppConfig.isDemoMode) {
      final index = state.selectedCardIndex;
      state = state.copyWith(selectedCardIndex: -1);
      DemoGameEngine().playCard(index);
      return;
    }

    final card = state.myHand[state.selectedCardIndex];
    SocketService().emit('play_card', {
      'cardId': card.id,
      'cardIndex': state.selectedCardIndex,
    });

    state = state.copyWith(selectedCardIndex: -1);
  }

  void setDemoState({
    required List<GameCard> myHand,
    required bool isMyTurn,
    required String turnPlayerName,
  }) {
    state = state.copyWith(
      myHand: myHand,
      isMyTurn: isMyTurn,
      currentTurnPlayerName: turnPlayerName,
      selectedCardIndex: -1,
      errorMessage: null,
    );
  }

  void resetGame() {
    state = GameState();
  }
}
