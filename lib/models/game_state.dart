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
}

class GameStateModel {
  final int currentTurnIndex;
  final List<PlayedCardItem> playedCards;
  final String? winner;

  GameStateModel({
    required this.currentTurnIndex,
    required this.playedCards,
    this.winner,
  });

  GameStateModel copyWith({
    int? currentTurnIndex,
    List<PlayedCardItem>? playedCards,
    String? winner,
  }) {
    return GameStateModel(
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      playedCards: playedCards ?? this.playedCards,
      winner: winner ?? this.winner,
    );
  }

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    var rawPlayed = json['playedCards'] as List? ?? [];
    List<PlayedCardItem> items = rawPlayed.whereType<Map>().map((e) {
      return PlayedCardItem.fromJson(Map<String, dynamic>.from(e));
    }).toList();

    return GameStateModel(
      currentTurnIndex: json['currentTurnIndex'] ?? 0,
      playedCards: items,
      winner: json['winner'],
    );
  }
}
