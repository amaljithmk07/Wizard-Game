import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/game_room.dart';
import '../../models/player.dart';

class LanDiscoveryService {
  static final LanDiscoveryService _instance = LanDiscoveryService._internal();
  factory LanDiscoveryService() => _instance;
  LanDiscoveryService._internal();

  RawDatagramSocket? _socket;
  final Map<String, GameRoom> _discoveredRooms = {};
  final Map<String, DateTime> _roomLastSeen = {};
  Timer? _pruneTimer;

  Function(List<GameRoom>)? onRoomsUpdated;

  bool get isListening => _socket != null;

  Future<void> startDiscovery({required Function(List<GameRoom>) onUpdate}) async {
    onRoomsUpdated = onUpdate;
    if (_socket != null) return;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        8889,
        reuseAddress: true,
        reusePort: true,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleDatagram(datagram);
          }
        }
      });

      // Periodically prune stale rooms that stopped announcing (> 5s)
      _pruneTimer?.cancel();
      _pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        final now = DateTime.now();
        final staleIds = <String>[];
        _roomLastSeen.forEach((id, lastSeen) {
          if (now.difference(lastSeen).inSeconds > 5) {
            staleIds.add(id);
          }
        });

        if (staleIds.isNotEmpty) {
          for (final id in staleIds) {
            _discoveredRooms.remove(id);
            _roomLastSeen.remove(id);
          }
          onRoomsUpdated?.call(_discoveredRooms.values.toList());
        }
      });

      if (kDebugMode) {
        print('[LanDiscovery] Listening for rooms on UDP 8889');
      }
    } catch (e) {
      if (kDebugMode) print('[LanDiscovery] Error binding UDP 8889: $e');
    }
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;

      if (json['type'] == 'WIZARD_ROOM_ANNOUNCE') {
        final roomId = json['roomId'] as String;
        final roomName = json['roomName'] as String;
        final hostIp = json['hostIp'] as String? ?? datagram.address.address;
        final port = json['port'] as int? ?? 8080;
        final playerCount = json['playerCount'] as int? ?? 1;
        final maxPlayers = json['maxPlayers'] as int? ?? 4;
        final status = json['status'] as String? ?? 'WAITING';

        final room = GameRoom(
          id: roomId,
          name: roomName,
          hostId: 'host',
          maxPlayers: maxPlayers,
          playerCount: playerCount,
          status: status,
          players: [
            Player(id: 'host', name: 'Host', isHost: true),
          ],
          hostAddress: '$hostIp:$port',
        );

        _discoveredRooms[roomId] = room;
        _roomLastSeen[roomId] = DateTime.now();

        onRoomsUpdated?.call(_discoveredRooms.values.toList());
      }
    } catch (_) {}
  }

  void stopDiscovery() {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    try {
      _socket?.close();
    } catch (_) {}
    _socket = null;
    _discoveredRooms.clear();
    _roomLastSeen.clear();
  }
}
