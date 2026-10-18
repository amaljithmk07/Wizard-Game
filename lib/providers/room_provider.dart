import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/lan_discovery_service.dart';
import '../../core/network/local_game_server.dart';
import '../../core/network/socket_service.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
import 'player_provider.dart';

final roomsProvider =
    StateNotifierProvider<RoomsNotifier, List<GameRoom>>((ref) {
  return RoomsNotifier();
});

class RoomsNotifier extends StateNotifier<List<GameRoom>> {
  RoomsNotifier() : super([]) {
    _initSocket();
    _initLanDiscovery();
  }

  List<GameRoom> _lanDiscoveredRooms = [];

  void _initSocket() {
    if (AppConfig.isDemoMode) return;

    final socket = SocketService();
    socket.on('rooms_updated', (data) {
      if (data is List) {
        final list = data
            .whereType<Map>()
            .map((r) => GameRoom.fromJson(Map<String, dynamic>.from(r)))
            .toList();
        _mergeAndEmit(serverRooms: list);
      }
    });
  }

  void _initLanDiscovery() {
    if (AppConfig.isDemoMode) return;

    LanDiscoveryService().startDiscovery(
      onUpdate: (discoveredRooms) {
        _lanDiscoveredRooms = discoveredRooms;
        _mergeAndEmit();
      },
    );
  }

  void _mergeAndEmit({List<GameRoom>? serverRooms}) {
    final merged = <String, GameRoom>{};

    // Add LAN discovered rooms first
    for (final room in _lanDiscoveredRooms) {
      merged[room.id] = room;
    }

    // Add server rooms if any
    if (serverRooms != null) {
      for (final room in serverRooms) {
        merged[room.id] = room;
      }
    }

    state = merged.values.toList();
  }

  void fetchRooms() {
    // Merge currently discovered LAN rooms and request online rooms
    _mergeAndEmit();
    SocketService().emit('get_rooms');
  }

  @override
  void dispose() {
    LanDiscoveryService().stopDiscovery();
    super.dispose();
  }
}

final roomErrorMessageProvider = StateProvider<String?>((ref) => null);

final currentRoomProvider =
    StateNotifierProvider<CurrentRoomNotifier, GameRoom?>((ref) {
  return CurrentRoomNotifier(ref);
});

class CurrentRoomNotifier extends StateNotifier<GameRoom?> {
  final Ref _ref;
  bool _isHostingLocally = false;
  bool get isHostingLocally => _isHostingLocally;

  CurrentRoomNotifier(this._ref) : super(null) {
    _initSocket();
  }

  void _initSocket() {
    if (AppConfig.isDemoMode) return;

    final socket = SocketService();

    socket.on('room_created', (data) {
      if (data is Map) {
        state = GameRoom.fromJson(Map<String, dynamic>.from(data));
      }
    });

    socket.on('room_joined', (data) {
      if (data is Map) {
        state = GameRoom.fromJson(Map<String, dynamic>.from(data));
      }
    });

    socket.on('room_updated', (data) {
      if (data is Map) {
        state = GameRoom.fromJson(Map<String, dynamic>.from(data));
      }
    });

    socket.on('error', (data) {
      if (data is Map && data['message'] != null) {
        _ref.read(roomErrorMessageProvider.notifier).state =
            data['message'].toString();
      }
    });
  }

  Future<void> createRoom(String roomName, int maxPlayers) async {
    final playerName = _ref.read(playerNameProvider);

    // If connected to online server, create room on the cloud server
    if (SocketService().isConnected) {
      SocketService().emit('create_room', {
        'roomName': roomName,
        'maxPlayers': maxPlayers,
      });
      return;
    }

    // Try connecting to cloud server first
    try {
      await SocketService().connect();
      if (SocketService().isConnected) {
        SocketService().emit('set_player_name', {'name': playerName});
        SocketService().emit('create_room', {
          'roomName': roomName,
          'maxPlayers': maxPlayers,
        });
        return;
      }
    } catch (_) {}

    // Fallback: Host on Local Wi-Fi using embedded Dart server if offline
    try {
      final server = LocalGameServer();
      final port = await server.startServer(
        roomName: roomName,
        hostPlayerName: playerName,
        maxPlayers: maxPlayers,
      );

      _isHostingLocally = true;

      // Connect Host client to local server
      await SocketService().connect(serverUrl: 'ws://127.0.0.1:$port');
      SocketService().emit('join_room', {
        'roomId': server.room?.id,
        'playerName': playerName,
      });

      state = server.room;
    } catch (e) {
      SocketService().emit('create_room', {
        'roomName': roomName,
        'maxPlayers': maxPlayers,
      });
    }
  }

  Future<void> joinRoom(String roomId, {String? hostAddress}) async {
    _ref.read(roomErrorMessageProvider.notifier).state = null;
    final playerName = _ref.read(playerNameProvider);
    final cleanRoomId = roomId.trim();

    // Check if room has a host address on Wi-Fi (e.g. local host fallback)
    final allRooms = _ref.read(roomsProvider);
    final targetRoom = allRooms.cast<GameRoom?>().firstWhere(
          (r) => r?.id == cleanRoomId,
          orElse: () => null,
        );

    final targetAddress = hostAddress ?? targetRoom?.hostAddress;
    if (targetAddress != null && targetAddress.isNotEmpty) {
      await SocketService().connect(serverUrl: 'ws://$targetAddress');
    } else if (!SocketService().isConnected) {
      await SocketService().connect();
    }

    if (SocketService().isConnected) {
      SocketService().emit('set_player_name', {'name': playerName});
    }

    SocketService().emit('join_room', {
      'roomId': cleanRoomId,
      'playerName': playerName,
    });
  }

  Future<void> connectByIp(String ipAndPort) async {
    final clean = ipAndPort.trim();
    final address = clean.contains(':') ? clean : '$clean:8080';
    await SocketService().connect(serverUrl: 'ws://$address');

    final playerName = _ref.read(playerNameProvider);
    SocketService().emit('join_room', {
      'roomId': 'local_room',
      'playerName': playerName,
    });
  }

  void leaveRoom() {
    if (_isHostingLocally) {
      LocalGameServer().stopServer();
      _isHostingLocally = false;
    }

    if (AppConfig.isDemoMode) {
      state = null;
      return;
    }

    SocketService().emit('leave_room');
    SocketService().disconnect();
    state = null;
  }

  void startGame() {
    SocketService().emit('start_game');
  }

  void setRoomDirectly(GameRoom room) {
    state = room;
  }

  void updateDemoGameState({
    required List<Player> players,
    required GameStateModel gameState,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      players: players,
      gameState: gameState,
    );
  }
}
