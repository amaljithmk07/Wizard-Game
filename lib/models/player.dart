import 'game_card.dart';

class Player {
  final String id;
  final String name;
  final int score;
  final bool isHost;
  final bool isDealer;
  final bool isConnected;
  final int? bid;
  final int tricksWon;
  final List<GameCard> hand;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
    this.isDealer = false,
    this.isConnected = true,
    this.bid,
    this.tricksWon = 0,
    this.hand = const [],
  });

  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isHost,
    bool? isDealer,
    bool? isConnected,
    int? bid,
    int? tricksWon,
    List<GameCard>? hand,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      isHost: isHost ?? this.isHost,
      isDealer: isDealer ?? this.isDealer,
      isConnected: isConnected ?? this.isConnected,
      bid: bid ?? this.bid,
      tricksWon: tricksWon ?? this.tricksWon,
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
      isDealer: json['isDealer'] ?? false,
      isConnected: json['isConnected'] ?? true,
      bid: json['bid'],
      tricksWon: json['tricksWon'] ?? 0,
      hand: parsedHand,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'isHost': isHost,
      'isDealer': isDealer,
      'isConnected': isConnected,
      'bid': bid,
      'tricksWon': tricksWon,
      'hand': hand.map((c) => c.toJson()).toList(),
    };
  }
}
