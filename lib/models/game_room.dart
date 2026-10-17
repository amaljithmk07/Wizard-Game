import 'game_state.dart';
import 'player.dart';

class GameRoom {
  final String id;
  final String name;
  final String hostId;
  final int maxPlayers;
  final int playerCount;
  final String status; // 'WAITING', 'PLAYING', 'FINISHED'
  final List<Player> players;
  final GameStateModel? gameState;
  final String? hostAddress; // e.g. "192.168.1.15:8080" for LAN Wi-Fi games

  GameRoom({
    required this.id,
    required this.name,
    required this.hostId,
    required this.maxPlayers,
    required this.playerCount,
    required this.status,
    required this.players,
    this.gameState,
    this.hostAddress,
  });

  bool get isFull => playerCount >= maxPlayers;
  bool get isWaiting => status == 'WAITING';
  bool get isLocalLan => hostAddress != null && hostAddress!.isNotEmpty;

  GameRoom copyWith({
    String? id,
    String? name,
    String? hostId,
    int? maxPlayers,
    int? playerCount,
    String? status,
    List<Player>? players,
    GameStateModel? gameState,
    String? hostAddress,
  }) {
    return GameRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      playerCount: playerCount ?? this.playerCount,
      status: status ?? this.status,
      players: players ?? this.players,
      gameState: gameState ?? this.gameState,
      hostAddress: hostAddress ?? this.hostAddress,
    );
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    var rawPlayers = json['players'] as List? ?? [];
    List<Player> parsedPlayers = rawPlayers.map((p) {
      if (p is Map) {
        return Player.fromJson(Map<String, dynamic>.from(p));
      }
      return Player(id: p.toString(), name: 'Player');
    }).toList();

    GameStateModel? stateModel;
    if (json['gameState'] != null && json['gameState'] is Map) {
      stateModel = GameStateModel.fromJson(
          Map<String, dynamic>.from(json['gameState'] as Map));
    }

    return GameRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Room',
      hostId: json['hostId'] ?? '',
      maxPlayers: json['maxPlayers'] ?? 4,
      playerCount: json['playerCount'] ?? parsedPlayers.length,
      status: json['status'] ?? 'WAITING',
      players: parsedPlayers,
      gameState: stateModel,
      hostAddress: json['hostAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'maxPlayers': maxPlayers,
      'playerCount': playerCount,
      'status': status,
      'hostAddress': hostAddress,
      'players': players.map((p) => p.toJson()).toList(),
      'gameState': gameState?.toJson(),
    };
  }
}
