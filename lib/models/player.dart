import 'game_card.dart';

class Player {
  final String id;
  final String name;
  final int score;
  final bool isHost;
  final List<GameCard> hand;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
    this.hand = const [],
  });

  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isHost,
    List<GameCard>? hand,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
      hand: hand ?? this.hand,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    var rawHand = json['hand'] as List? ?? [];
    List<GameCard> parsedHand = rawHand.whereType<Map>().map((c) {
      return GameCard.fromJson(Map<String, dynamic>.from(c));
    }).toList();

    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Player',
      score: json['score'] ?? 0,
      isHost: json['isHost'] ?? false,
      hand: parsedHand,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'isHost': isHost,
      'hand': hand.map((c) => c.toJson()).toList(),
    };
  }
}
