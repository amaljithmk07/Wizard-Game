import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import '../mock/demo_game_data.dart';

class LocalGameServer {
  static final LocalGameServer _instance = LocalGameServer._internal();
  factory LocalGameServer() => _instance;
  LocalGameServer._internal();

  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;

  int _port = 8080;
  int get port => _port;
  bool get isRunning => _server != null;

  String? _localIp;
  String? get localIp => _localIp;

  GameRoom? _room;
  GameRoom? get room => _room;

  final Map<String, WebSocket> _clients = {};
  final Map<WebSocket, String> _socketToPlayerId = {};

  Future<String?> findLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            _localIp = addr.address;
            return addr.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[LocalGameServer] Error finding local IP: $e');
    }
    _localIp ??= '127.0.0.1';
    return _localIp;
  }

  Future<int> startServer({
    required String roomName,
    required String hostPlayerName,
    required int maxPlayers,
    int preferredPort = 8080,
  }) async {
    await stopServer();
    await findLocalIp();

    int tryPort = preferredPort;
    for (int i = 0; i < 5; i++) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          tryPort,
          shared: true,
        );
        _port = tryPort;
        break;
      } catch (_) {
        tryPort++;
      }
    }

    if (_server == null) {
      throw Exception('Failed to bind embedded local server on ports $preferredPort-${tryPort - 1}');
    }

    final roomId = 'local_room_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final hostPlayer = Player(
      id: 'player_host',
      name: hostPlayerName.isNotEmpty ? hostPlayerName : 'Host',
      isHost: true,
    );

    _room = GameRoom(
      id: roomId,
      name: roomName,
      hostId: hostPlayer.id,
      maxPlayers: maxPlayers,
      playerCount: 1,
      status: 'WAITING',
      players: [hostPlayer],
      hostAddress: '$_localIp:$_port',
    );

    _server!.listen(_handleHttpRequest);

    // Start UDP LAN announcement
    _startUdpBroadcast();

    if (kDebugMode) {
      print('[LocalGameServer] Running on $_localIp:$_port (Room: $roomName)');
    }

    return _port;
  }

  void _handleHttpRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then(_handleWebSocket);
    } else if (request.uri.path == '/rooms') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode([_getSanitizedRoom()]))
        ..close();
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Wizard Card Game Local Server is Running')
        ..close();
    }
  }

  void _handleWebSocket(WebSocket socket) {
    final clientId = 'client_${DateTime.now().microsecondsSinceEpoch}';
    _clients[clientId] = socket;
    _socketToPlayerId[socket] = clientId;

    socket.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          final event = decoded['event'] as String?;
          final payload = decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : <String, dynamic>{};

          _processEvent(socket, clientId, event, payload);
        } catch (e) {
          if (kDebugMode) print('[LocalGameServer] Error parsing message: $e');
        }
      },
      onDone: () => _handleClientDisconnect(socket, clientId),
      onError: (_) => _handleClientDisconnect(socket, clientId),
    );
  }

  void _processEvent(
    WebSocket socket,
    String clientId,
    String? event,
    Map<String, dynamic> payload,
  ) {
    if (_room == null) return;

    switch (event) {
      case 'set_player_name':
        final name = payload['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          final playerIndex = _room!.players.indexWhere((p) => p.id == clientId);
          if (playerIndex != -1) {
            _room!.players[playerIndex] = _room!.players[playerIndex].copyWith(name: name);
            _broadcastRoomUpdated();
          }
        }
        break;

      case 'get_rooms':
        _sendTo(socket, 'rooms_updated', [_getSanitizedRoom()]);
        break;

      case 'join_room':
        if (_room!.status != 'WAITING') {
          _sendTo(socket, 'error', {'message': 'Game already in progress'});
          return;
        }
        if (_room!.players.length >= _room!.maxPlayers) {
          _sendTo(socket, 'error', {'message': 'Room is full'});
          return;
        }

        final playerName = payload['playerName']?.toString().trim();
        final effectiveName = (playerName != null && playerName.isNotEmpty)
            ? playerName
            : 'Player ${_room!.players.length + 1}';

        // Check if player already registered
        if (!_room!.players.any((p) => p.id == clientId)) {
          final newPlayer = Player(
            id: clientId,
            name: effectiveName,
            isHost: false,
          );

          _room = _room!.copyWith(
            players: [..._room!.players, newPlayer],
            playerCount: _room!.players.length + 1,
          );
        }

        _sendTo(socket, 'room_joined', _roomToJson());
        _broadcastRoomUpdated();
        break;

      case 'start_game':
        if (_room!.players.length < 2) {
          _sendTo(socket, 'error', {'message': 'At least 2 players required'});
          return;
        }

        // Generate deck & deal 5 cards to each player
        final deck = generateDemoDeck();
        final updatedPlayers = <Player>[];
        for (int i = 0; i < _room!.players.length; i++) {
          final hand = deck.sublist(i * 5, (i + 1) * 5);
          updatedPlayers.add(_room!.players[i].copyWith(hand: hand, score: 0));
        }

        _room = _room!.copyWith(
          status: 'PLAYING',
          players: updatedPlayers,
          gameState: GameStateModel(
            currentTurnIndex: 0,
            playedCards: [],
          ),
        );

        _broadcast('game_started', _roomToJson());
        _broadcastRoomUpdated();
        break;

      case 'play_card':
        if (_room!.status != 'PLAYING' || _room!.gameState == null) return;

        final turnIdx = _room!.gameState!.currentTurnIndex;
        if (turnIdx < 0 || turnIdx >= _room!.players.length) return;

        final currentTurnPlayer = _room!.players[turnIdx];
        if (currentTurnPlayer.id != clientId) {
          _sendTo(socket, 'error', {'message': 'Not your turn'});
          return;
        }

        final cardIndex = payload['cardIndex'] as int?;
        if (cardIndex == null ||
            cardIndex < 0 ||
            cardIndex >= currentTurnPlayer.hand.length) {
          return;
        }

        final playedCard = currentTurnPlayer.hand[cardIndex];
        final updatedHand = List<GameCard>.from(currentTurnPlayer.hand)..removeAt(cardIndex);

        final playerIdxInList = _room!.players.indexWhere((p) => p.id == clientId);
        _room!.players[playerIdxInList] = currentTurnPlayer.copyWith(hand: updatedHand);

        final playedItem = PlayedCardItem(
          playerId: currentTurnPlayer.id,
          playerName: currentTurnPlayer.name,
          card: playedCard,
        );

        final updatedPlayedCards = [..._room!.gameState!.playedCards, playedItem];

        // Did everyone in the room play their card for this trick?
        if (updatedPlayedCards.length >= _room!.players.length) {
          // Resolve trick: highest card wins
          PlayedCardItem highest = updatedPlayedCards.first;
          for (int i = 1; i < updatedPlayedCards.length; i++) {
            if (updatedPlayedCards[i].card.value > highest.card.value) {
              highest = updatedPlayedCards[i];
            }
          }

          // Award 10 points to winner
          final winnerIdx = _room!.players.indexWhere((p) => p.id == highest.playerId);
          if (winnerIdx != -1) {
            final w = _room!.players[winnerIdx];
            _room!.players[winnerIdx] = w.copyWith(score: w.score + 10);
          }

          _room = _room!.copyWith(
            gameState: GameStateModel(
              currentTurnIndex: 0,
              playedCards: updatedPlayedCards,
            ),
          );

          _broadcastRoomUpdated();

          // After 1 second, clear table and continue or finish
          Timer(const Duration(milliseconds: 1200), () {
            if (_room == null) return;

            final isGameOver = _room!.players.every((p) => p.hand.isEmpty);
            if (isGameOver) {
              // Determine overall winner
              Player topPlayer = _room!.players.first;
              for (final p in _room!.players) {
                if (p.score > topPlayer.score) topPlayer = p;
              }

              _room = _room!.copyWith(
                status: 'FINISHED',
                gameState: GameStateModel(
                  currentTurnIndex: 0,
                  playedCards: [],
                  winner: topPlayer.name,
                ),
              );

              final resultScores = _room!.players.map((p) => {
                'id': p.id,
                'name': p.name,
                'score': p.score,
                'isHost': p.isHost,
                'hand': [],
              }).toList();

              _broadcast('game_finished', {
                'winner': topPlayer.name,
                'players': resultScores,
              });
              _broadcastRoomUpdated();
            } else {
              _room = _room!.copyWith(
                gameState: GameStateModel(
                  currentTurnIndex: 0,
                  playedCards: [],
                ),
              );
              _broadcastRoomUpdated();
            }
          });
        } else {
          // Next turn
          final nextTurn = (turnIdx + 1) % _room!.players.length;
          _room = _room!.copyWith(
            gameState: GameStateModel(
              currentTurnIndex: nextTurn,
              playedCards: updatedPlayedCards,
            ),
          );
          _broadcastRoomUpdated();
        }
        break;

      case 'leave_room':
        _handleClientDisconnect(socket, clientId);
        break;
    }
  }

  void _handleClientDisconnect(WebSocket socket, String clientId) {
    _clients.remove(clientId);
    _socketToPlayerId.remove(socket);

    if (_room == null) return;

    final wasHost = _room!.hostId == clientId;
    _room!.players.removeWhere((p) => p.id == clientId);

    if (_room!.players.isEmpty || wasHost) {
      stopServer();
      return;
    }

    _room = _room!.copyWith(playerCount: _room!.players.length);
    _broadcastRoomUpdated();
  }

  void _sendTo(WebSocket socket, String event, dynamic data) {
    try {
      socket.add(jsonEncode({'event': event, 'data': data}));
    } catch (_) {}
  }

  void _broadcast(String event, dynamic data) {
    final message = jsonEncode({'event': event, 'data': data});
    for (final client in _clients.values) {
      try {
        client.add(message);
      } catch (_) {}
    }
  }

  void _broadcastRoomUpdated() {
    if (_room == null) return;
    _broadcast('room_updated', _roomToJson());
  }

  Map<String, dynamic> _roomToJson() {
    if (_room == null) return {};
    return {
      'id': _room!.id,
      'name': _room!.name,
      'hostId': _room!.hostId,
      'maxPlayers': _room!.maxPlayers,
      'playerCount': _room!.players.length,
      'status': _room!.status,
      'hostAddress': _room!.hostAddress,
      'players': _room!.players.map((p) => {
        'id': p.id,
        'name': p.name,
        'score': p.score,
        'isHost': p.isHost,
        'hand': p.hand.map((c) => c.toJson()).toList(),
      }).toList(),
      'gameState': _room!.gameState == null
          ? null
          : {
              'currentTurnIndex': _room!.gameState!.currentTurnIndex,
              'winner': _room!.gameState!.winner,
              'playedCards': _room!.gameState!.playedCards.map((pc) => {
                'playerId': pc.playerId,
                'playerName': pc.playerName,
                'card': pc.card.toJson(),
              }).toList(),
            },
    };
  }

  Map<String, dynamic> _getSanitizedRoom() {
    if (_room == null) return {};
    return {
      'id': _room!.id,
      'name': _room!.name,
      'hostId': _room!.hostId,
      'maxPlayers': _room!.maxPlayers,
      'playerCount': _room!.players.length,
      'status': _room!.status,
      'hostAddress': '$_localIp:$_port',
    };
  }

  void _startUdpBroadcast() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _udpSocket!.broadcastEnabled = true;

      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (_room == null || _room!.status != 'WAITING') return;

        final payload = jsonEncode({
          'type': 'WIZARD_ROOM_ANNOUNCE',
          'roomId': _room!.id,
          'roomName': _room!.name,
          'hostIp': _localIp,
          'port': _port,
          'playerCount': _room!.players.length,
          'maxPlayers': _room!.maxPlayers,
          'status': _room!.status,
        });

        final bytes = utf8.encode(payload);
        try {
          _udpSocket?.send(bytes, InternetAddress('255.255.255.255'), 8889);
        } catch (_) {}
      });
    } catch (e) {
      if (kDebugMode) print('[LocalGameServer] UDP broadcast init: $e');
    }
  }

  Future<void> stopServer() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    try {
      _udpSocket?.close();
    } catch (_) {}
    _udpSocket = null;

    for (final client in _clients.values) {
      try {
        client.close();
      } catch (_) {}
    }
    _clients.clear();
    _socketToPlayerId.clear();

    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _room = null;
  }
}
