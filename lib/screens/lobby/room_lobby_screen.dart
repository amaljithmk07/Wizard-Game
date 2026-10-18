import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
import '../../models/player.dart';
import '../../providers/room_provider.dart';
import '../../widgets/player_tile.dart';
import '../game/game_screen.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({super.key});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  Timer? _loadingTimeoutTimer;
  bool _timedOut = false;
  bool _lastHostReady = false;

  @override
  void initState() {
    super.initState();
    _listenToSocketEvents();

    // Prevent infinite spinner if room never resolves
    _loadingTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && ref.read(currentRoomProvider) == null) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  void _listenToSocketEvents() {
    if (AppConfig.isDemoMode) return;

    final socket = SocketService();
    socket.on('game_started', (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    });
  }

  void _onLeaveRoom() {
    ref.read(currentRoomProvider.notifier).leaveRoom();
    Navigator.pop(context);
  }

  void _onStartGame() {
    ref.read(currentRoomProvider.notifier).toggleReady(true);
    ref.read(currentRoomProvider.notifier).startGame();
    if (AppConfig.isDemoMode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(currentRoomProvider);
    final socketId = SocketService().socketId;
    final isDemo = AppConfig.isDemoMode;

    if (room == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Joining Room...'),
        ),
        body: Center(
          child: _timedOut
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to Connect to Room',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The game server did not respond or connection was lost.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Return to Rooms',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
                    SizedBox(height: 16),
                    Text(
                      'Entering room...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
        ),
      );
    }

    final bool isHost = room.hostId == socketId ||
        room.players
            .firstWhere((p) => p.id == socketId,
                orElse: () => room.players.first)
            .isHost;
    final bool isYouHost = isHost || isDemo;
    final bool canStart =
        isHost && room.playerCount >= 3 && room.playerCount <= 8;

    final Player? hostPlayer = room.hostPlayer;
    final bool isPlayer1Ready = hostPlayer?.isReady ?? false;

    final myPlayer = room.players.firstWhere(
      (p) => isDemo
          ? p.isHost || p.id == 'demo_player_local'
          : p.id == socketId,
      orElse: () => room.players.first,
    );
    final bool isMyPlayerReady = myPlayer.isReady;

    if (!isYouHost && isPlayer1Ready && !_lastHostReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${hostPlayer?.name ?? "Player 1"} is READY to start!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
    _lastHostReady = isPlayer1Ready;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(currentRoomProvider.notifier).leaveRoom();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A), size: 20),
            onPressed: _onLeaveRoom,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  room.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Room Code Card (Always visible so host or players can share)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vpn_key_rounded,
                            size: 20, color: Color(0xFF60A5FA)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ROOM CODE',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              room.id,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: room.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Room Code "${room.id}" copied to clipboard!'),
                              backgroundColor: const Color(0xFF16A34A),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded,
                            size: 15, color: Colors.white),
                        label: const Text(
                          'Copy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Player 1 (Host) Ready Status Banner
                if (!isYouHost) ...[
                  if (isPlayer1Ready)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF22C55E), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E)
                                .withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hostPlayer?.name ?? "Player 1"} is READY to start!',
                                  style: const TextStyle(
                                    color: Color(0xFF14532D),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Get ready! The host will launch the game shortly.',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Waiting for ${hostPlayer?.name ?? "Player 1"} to get ready...',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Section Header
                Text(
                  'Players (${room.playerCount} / ${room.maxPlayers})',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // Player tiles list
                Expanded(
                  child: ListView.builder(
                    itemCount: room.maxPlayers,
                    itemBuilder: (context, index) {
                      if (index < room.players.length) {
                        final player = room.players[index];
                        final bool isYou = isDemo
                            ? player.id == 'demo_player_local'
                            : player.id == socketId;
                        final bool playerIsHost = player.id == room.hostId ||
                            (isDemo && player.isHost);

                        return PlayerTile(
                          name: player.name,
                          isYou: isYou,
                          isHost: playerIsHost,
                          isReady: player.isReady,
                        );
                      } else {
                        return const PlayerTile(
                          name: '',
                          isEmpty: true,
                        );
                      }
                    },
                  ),
                ),

                // Bottom Action Area
                if (isYouHost) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(currentRoomProvider.notifier)
                            .toggleReady(!isPlayer1Ready);
                      },
                      icon: Icon(
                        isPlayer1Ready
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isPlayer1Ready
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF2563EB),
                        size: 20,
                      ),
                      label: Text(
                        isPlayer1Ready
                            ? 'You are READY! (Tap to unmark)'
                            : 'Mark as READY to Start',
                        style: TextStyle(
                          color: isPlayer1Ready
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isPlayer1Ready
                            ? const Color(0xFFDCFCE7)
                            : Colors.white,
                        side: BorderSide(
                          color: isPlayer1Ready
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFBFDBFE),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canStart ? _onStartGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      canStart
                          ? (isPlayer1Ready
                              ? 'Ready to start! Tap Start Game above.'
                              : 'Ready to start!')
                          : 'Minimum 3 players required (${room.playerCount}/3 joined)',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isPlayer1Ready
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPlayer1Ready
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPlayer1Ready
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded,
                          color: isPlayer1Ready
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPlayer1Ready
                              ? 'Player 1 is READY to start! Waiting for launch...'
                              : 'Waiting for host to start...',
                          style: TextStyle(
                            color: isPlayer1Ready
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: isPlayer1Ready
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(currentRoomProvider.notifier)
                            .toggleReady(!isMyPlayerReady);
                      },
                      icon: Icon(
                        isMyPlayerReady
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: isMyPlayerReady
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                      label: Text(
                        isMyPlayerReady
                            ? 'You are Ready! (Tap to unmark)'
                            : 'Mark I\'m Ready',
                        style: TextStyle(
                          color: isMyPlayerReady
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isMyPlayerReady
                            ? const Color(0xFFDCFCE7)
                            : Colors.white,
                        side: BorderSide(
                          color: isMyPlayerReady
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
