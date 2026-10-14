import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
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
    final singleOpponent = opponents.isNotEmpty ? opponents.first : null;

    // Find current turn player
    final currentTurnPlayer = (room.gameState != null &&
            room.gameState!.currentTurnIndex < room.players.length)
        ? room.players[room.gameState!.currentTurnIndex]
        : null;
    final bool isSingleOpponentTurn =
        singleOpponent != null && currentTurnPlayer?.id == singleOpponent.id;

    // Find all played cards on table in current trick
    final playedCards = room.gameState?.playedCards ?? [];

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
            const SizedBox(height: 8),

            // Top Opponent Area (Adaptive for 1 opponent or up to 7 opponents)
            if (opponents.length == 1 && singleOpponent != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSingleOpponentTurn
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFE2E8F0),
                      border: isSingleOpponentTurn
                          ? Border.all(color: const Color(0xFF2563EB), width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      singleOpponent.name.isNotEmpty
                          ? singleOpponent.name[0].toUpperCase()
                          : 'O',
                      style: TextStyle(
                        color: isSingleOpponentTurn
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            singleOpponent.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isSingleOpponentTurn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TURN',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${singleOpponent.hand.isNotEmpty ? singleOpponent.hand.length : 3} cards • Score: ${singleOpponent.score}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Opponent's Face-Down Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  singleOpponent.hand.isNotEmpty
                      ? singleOpponent.hand.length
                      : 3,
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: GameCardWidget(
                      isFaceDown: true,
                      width: 44,
                      height: 64,
                    ),
                  ),
                ),
              ),
            ] else if (opponents.length > 1) ...[
              // Scrollable Opponents Row for 3-8 players
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: opponents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final opp = opponents[index];
                    final bool isTurn = currentTurnPlayer?.id == opp.id;
                    return Container(
                      width: 110,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isTurn ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTurn
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE2E8F0),
                          width: isTurn ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTurn
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  opp.name.isNotEmpty
                                      ? opp.name[0].toUpperCase()
                                      : 'P',
                                  style: TextStyle(
                                    color: isTurn
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  opp.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 12,
                                    fontWeight: isTurn
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${opp.hand.length} cards',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${opp.score} pts',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (isTurn) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TURN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // Center Game Table (Displays cards played in current trick)
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: playedCards.isNotEmpty
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: playedCards.map((item) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GameCardWidget(
                                    card: item.card,
                                    width: playedCards.length > 4 ? 54 : 64,
                                    height: playedCards.length > 4 ? 78 : 92,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 70),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      item.playerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.style_outlined,
                              size: 38,
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
