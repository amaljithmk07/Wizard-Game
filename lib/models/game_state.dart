import 'game_card.dart';

class PlayedCardItem {
  final String playerId;
  final String playerName;
  final GameCard card;

  PlayedCardItem({
    required this.playerId,
    required this.playerName,
    required this.card,
  });

  factory PlayedCardItem.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'];
    return PlayedCardItem(
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      card: GameCard.fromJson(
        rawCard is Map ? Map<String, dynamic>.from(rawCard) : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'card': card.toJson(),
    };
  }
}

class GameStateModel {
  final int round;
  final int totalRounds;
  final String phase; // 'BIDDING', 'TRICK', 'ROUND_OVER', 'GAME_OVER'
  final GameCard? trumpCard;
  final String? trumpSuit;
  final String? ledSuit;
  final int dealerIndex;
  final int currentTurnIndex;
  final List<PlayedCardItem> playedCards;
  final String? trickWinnerName;
  final String? winner;
  final List<Map<String, dynamic>>? roundScores;

  GameStateModel({
    this.round = 1,
    this.totalRounds = 15,
    this.phase = 'BIDDING',
    this.trumpCard,
    this.trumpSuit,
    this.ledSuit,
    this.dealerIndex = 0,
    required this.currentTurnIndex,
    required this.playedCards,
    this.trickWinnerName,
    this.winner,
    this.roundScores,
  });

  bool get isBiddingPhase => phase == 'BIDDING';
  bool get isTrickPhase => phase == 'TRICK';
  bool get isRoundOver => phase == 'ROUND_OVER';
  bool get isGameOver => phase == 'GAME_OVER';

  GameStateModel copyWith({
    int? round,
    int? totalRounds,
    String? phase,
    GameCard? trumpCard,
    String? trumpSuit,
    String? ledSuit,
    int? dealerIndex,
    int? currentTurnIndex,
    List<PlayedCardItem>? playedCards,
    String? trickWinnerName,
    String? winner,
    List<Map<String, dynamic>>? roundScores,
  }) {
    return GameStateModel(
      round: round ?? this.round,
      totalRounds: totalRounds ?? this.totalRounds,
      phase: phase ?? this.phase,
      trumpCard: trumpCard ?? this.trumpCard,
      trumpSuit: trumpSuit ?? this.trumpSuit,
      ledSuit: ledSuit ?? this.ledSuit,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      playedCards: playedCards ?? this.playedCards,
      trickWinnerName: trickWinnerName ?? this.trickWinnerName,
      winner: winner ?? this.winner,
      roundScores: roundScores ?? this.roundScores,
    );
  }

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    var rawPlayed = json['playedCards'] as List? ?? [];
    List<PlayedCardItem> items = rawPlayed.whereType<Map>().map((e) {
      return PlayedCardItem.fromJson(Map<String, dynamic>.from(e));
    }).toList();

    GameCard? parsedTrump;
    if (json['trumpCard'] != null && json['trumpCard'] is Map) {
      parsedTrump = GameCard.fromJson(Map<String, dynamic>.from(json['trumpCard'] as Map));
    }

    List<Map<String, dynamic>>? parsedRoundScores;
    if (json['roundScores'] != null && json['roundScores'] is List) {
      parsedRoundScores = (json['roundScores'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    return GameStateModel(
      round: json['round'] ?? 1,
      totalRounds: json['totalRounds'] ?? 15,
      phase: json['phase'] ?? 'TRICK',
      trumpCard: parsedTrump,
      trumpSuit: json['trumpSuit'],
      ledSuit: json['ledSuit'],
      dealerIndex: json['dealerIndex'] ?? 0,
      currentTurnIndex: json['currentTurnIndex'] ?? 0,
      playedCards: items,
      trickWinnerName: json['trickWinnerName'],
      winner: json['winner'],
      roundScores: parsedRoundScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'totalRounds': totalRounds,
      'phase': phase,
      'trumpCard': trumpCard?.toJson(),
      'trumpSuit': trumpSuit,
      'ledSuit': ledSuit,
      'dealerIndex': dealerIndex,
      'currentTurnIndex': currentTurnIndex,
      'playedCards': playedCards.map((c) => c.toJson()).toList(),
      'trickWinnerName': trickWinnerName,
      'winner': winner,
      'roundScores': roundScores,
    };
  }
}
