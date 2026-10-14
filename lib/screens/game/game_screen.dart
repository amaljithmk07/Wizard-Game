import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
import '../../models/game_state.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/game_card_widget.dart';
import '../result/game_result_screen.dart';
import '../server_list/server_list_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Timer? _fallbackTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();

    if (AppConfig.isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final room = ref.read(currentRoomProvider);
        if (room != null) {
          ref.read(gameProvider.notifier).initDemoGame(room);
        }
      });
    } else {
      _listenToGameEvents();
    }

    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && ref.read(currentRoomProvider) == null) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _listenToGameEvents() {
    final socket = SocketService();
    socket.on('game_finished', (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameResultScreen()),
        );
      }
    });
  }

  void _leaveGame() {
    ref.read(currentRoomProvider.notifier).leaveRoom();
    ref.read(gameProvider.notifier).resetGame();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ServerListScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for winner in both Demo and Server modes
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.winnerName != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameResultScreen()),
        );
      }
    });

    final room = ref.watch(currentRoomProvider);
    final gameState = ref.watch(gameProvider);
    final isDemo = AppConfig.isDemoMode;
    final socketId = isDemo ? 'demo_player_local' : SocketService().socketId;

    if (room == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: _timedOut
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 16),
                    const Text(
                      'Game Not Found',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _leaveGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: const Text('Back to Rooms',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2563EB)),
                    SizedBox(height: 16),
                    Text(
                      'Loading match...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
        ),
      );
    }

    // Find opponents
    final opponents = room.players.where((p) => p.id != socketId).toList();
    final opponent = opponents.isNotEmpty ? opponents.first : null;

    // Find played card on table
    PlayedCardItem? tableCardItem;
    if (room.gameState != null && room.gameState!.playedCards.isNotEmpty) {
      tableCardItem = room.gameState!.playedCards.last;
    }

    final bool isMyTurn = gameState.isMyTurn;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: _leaveGame,
        ),
        centerTitle: true,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isDemo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isMyTurn
                  ? 'Your turn'
                  : '${gameState.currentTurnPlayerName}\'s turn',
              style: TextStyle(
                color: isMyTurn
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isMyTurn ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Top Opponent Area
            if (opponent != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE2E8F0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opponent.name.isNotEmpty
                          ? opponent.name[0].toUpperCase()
                          : 'O',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponent.name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${opponent.hand.isNotEmpty ? opponent.hand.length : 3} cards',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Opponent's Face-Down Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  opponent.hand.isNotEmpty ? opponent.hand.length : 3,
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: GameCardWidget(
                      isFaceDown: true,
                      width: 48,
                      height: 68,
                    ),
                  ),
                ),
              ),
            ],

            // Center Game Table
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: tableCardItem != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameCardWidget(
                              card: tableCardItem.card,
                              width: 80,
                              height: 116,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Played by ${tableCardItem.playerName}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.style_outlined,
                              size: 40,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Table is clear',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Bottom Player Cards Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your cards',
                  style: TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cards Horizontal View
            SizedBox(
              height: 105,
              child: gameState.myHand.isEmpty
                  ? const Center(
                      child: Text(
                        'No cards left',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: gameState.myHand.length,
                      itemBuilder: (context, index) {
                        final card = gameState.myHand[index];
                        final bool isSelected =
                            gameState.selectedCardIndex == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: GameCardWidget(
                            card: card,
                            isSelected: isSelected,
                            onTap: () {
                              ref.read(gameProvider.notifier).selectCard(index);
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Play Card Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (isMyTurn && gameState.selectedCardIndex != -1)
                      ? () {
                          ref.read(gameProvider.notifier).playSelectedCard();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isMyTurn ? 'Play Card' : 'Waiting for turn...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
