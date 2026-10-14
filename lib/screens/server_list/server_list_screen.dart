import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
import '../../providers/room_provider.dart';
import '../../widgets/room_tile.dart';
import '../create_room/create_room_screen.dart';
import '../lobby/room_lobby_screen.dart';

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  void _loadRooms() {
    ref.read(roomsProvider.notifier).fetchRooms();
  }

  void _joinRoom(String roomId) {
    ref.read(currentRoomProvider.notifier).joinRoom(roomId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoomLobbyScreen()),
    );
  }

  void _enableDemoMode() {
    AppConfig.enableRuntimeDemo();
    _loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider);
    final isDemo = AppConfig.isDemoMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Rooms',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isDemo) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text(
                  'DEMO MODE',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF334155), size: 24),
            onPressed: _loadRooms,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Server Mode Connection Error Banner
              if (!isDemo)
                ValueListenableBuilder<SocketConnectionStatus>(
                  valueListenable: SocketService().statusNotifier,
                  builder: (context, status, _) {
                    if (status == SocketConnectionStatus.error ||
                        (status == SocketConnectionStatus.disconnected &&
                            rooms.isEmpty)) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi_off_rounded,
                                    color: Color(0xFFDC2626), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Backend Server Unavailable',
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              SocketService().errorMessage ??
                                  'Could not connect to multiplayer backend (localhost:3000).',
                              style: const TextStyle(
                                color: Color(0xFF7F1D1D),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    SocketService().connect();
                                    _loadRooms();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _enableDemoMode,
                                  icon: const Icon(Icons.play_arrow_rounded,
                                      size: 16),
                                  label: const Text('Switch to Demo Mode'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF991B1B),
                                    side: const BorderSide(
                                        color: Color(0xFFFCA5A5)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              const SizedBox(height: 8),

              // Create Room Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateRoomScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    'Create Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Rooms List
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 48,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No open rooms available',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create one above to get started!',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _loadRooms();
                        },
                        child: ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomTile(
                              room: room,
                              onJoin: () => _joinRoom(room.id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
