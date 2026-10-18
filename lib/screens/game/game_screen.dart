import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/network/socket_service.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/card_fan_widget.dart';
import '../../widgets/poker_table_widget.dart';
import '../result/game_result_screen.dart';
import '../server_list/server_list_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _selectedBid = 0;

  @override
  void initState() {
    super.initState();
    _listenToGameEvents();
  }

  void _listenToGameEvents() {
    if (AppConfig.isDemoMode) return;

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
    if (AppConfig.isDemoMode) {
      AppConfig.resetRuntimeDemo();
      ref.read(currentRoomProvider.notifier).leaveRoom();
      Navigator.pop(context);
      return;
    }

    ref.read(currentRoomProvider.notifier).leaveRoom();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ServerListScreen()),
      (route) => false,
    );
  }

  void _showTrumpChoiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Wizard Revealed! Choose Trump Suit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'As dealer, choose the trump suit for this round:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSuitChoiceButton(ctx, 'Spades', '♠', const Color(0xFF1E293B)),
                _buildSuitChoiceButton(ctx, 'Hearts', '♥', const Color(0xFFDC2626)),
                _buildSuitChoiceButton(ctx, 'Diamonds', '♦', const Color(0xFFDC2626)),
                _buildSuitChoiceButton(ctx, 'Clubs', '♣', const Color(0xFF1E293B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuitChoiceButton(
      BuildContext ctx, String suit, String symbol, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onPressed: () {
        ref.read(gameProvider.notifier).chooseTrump(suit);
        Navigator.pop(ctx);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(symbol,
              style: TextStyle(
                  fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(suit,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(gameProvider.notifier).clearError();
      }

      if (next.winnerName != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameResultScreen()),
        );
      }
    });

    final room = ref.watch(currentRoomProvider);
    final gameState = ref.watch(gameProvider);
    final socketId = SocketService().socketId;

    if (room == null || room.gameState == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Dealing cards & preparing round...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final wizardState = room.gameState!;
    final myPlayerId = AppConfig.isDemoMode
        ? 'demo_me'
        : (socketId ?? room.players.first.id);

    final myPlayer = room.players.firstWhere(
      (p) => p.id == myPlayerId,
      orElse: () => room.players.first,
    );

    final bool isMyTurn = gameState.isMyTurn;
    final bool isBidding = wizardState.isBiddingPhase;
    final bool isRoundOver = wizardState.isRoundOver;
    final int currentRound = wizardState.round;
    final int totalRounds = wizardState.totalRounds;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant poker table frame
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF1F5F9), size: 20),
          onPressed: _leaveGame,
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Round $currentRound of $totalRounds',
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isBidding
                  ? (isMyTurn
                      ? '🎯 YOUR TURN TO BID'
                      : 'BIDDING: ${gameState.currentTurnPlayerName}\'s turn')
                  : (isMyTurn
                      ? '⚡ YOUR TURN TO PLAY'
                      : '${gameState.currentTurnPlayerName}\'s turn'),
              style: TextStyle(
                color: isMyTurn ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isMyTurn ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Poker Table with relative seating for 3-8 players and center trick
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Stack(
                  children: [
                    PokerTableWidget(
                      room: room,
                      gameState: wizardState,
                      myPlayerId: myPlayerId,
                      onDealerPickTrump: _showTrumpChoiceDialog,
                    ),

                    // Round Over Summary Modal Overlay
                    if (isRoundOver && wizardState.roundScores != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Material(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              elevation: 10,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 340),
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🏆',
                                        style: TextStyle(fontSize: 32)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Round $currentRound Complete!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...wizardState.roundScores!.map((rs) {
                                      final pts = rs['roundPoints'] ?? 0;
                                      final bool isPositive = pts >= 0;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${rs['playerName']} (Bid: ${rs['bid']}, Won: ${rs['tricksWon']})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${isPositive ? "+" : ""}$pts pts  [Total: ${rs['totalScore']}]',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isPositive
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Next round starting shortly...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Player Section
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player Stats Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            myPlayer.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (myPlayer.isDealer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEALER 👑',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          'Bid: ${myPlayer.bid ?? "-"}  |  Won: ${myPlayer.tricksWon}  |  Score: ${myPlayer.score}p',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bidding Selector
                  if (isBidding && isMyTurn) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Bid for Round $currentRound (0 to $currentRound tricks):',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF93C5FD),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: List.generate(currentRound + 1, (bidNum) {
                                final isSelected = _selectedBid == bidNum;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF1E293B),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(38, 36),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      elevation: 0,
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                    onPressed: () =>
                                        setState(() => _selectedBid = bidNum),
                                    child: Text('$bidNum',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                ref
                                    .read(gameProvider.notifier)
                                    .submitBid(_selectedBid);
                              },
                              child: Text(
                                'Confirm Bid ($_selectedBid)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Overlapping Card Fan
                  CardFanWidget(
                    cards: gameState.myHand,
                    selectedIndex: gameState.selectedCardIndex,
                    ledSuit: wizardState.ledSuit,
                    isMyTurn: isMyTurn,
                    isTrickPhase: !isBidding && !isRoundOver,
                    onCardSelected: (index) {
                      ref.read(gameProvider.notifier).selectCard(index);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Play Card Button
                  if (!isBidding && !isRoundOver)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (isMyTurn && gameState.selectedCardIndex != -1)
                            ? () {
                                ref
                                    .read(gameProvider.notifier)
                                    .playSelectedCard();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          disabledBackgroundColor: const Color(0xFF334155),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isMyTurn
                              ? (gameState.selectedCardIndex != -1
                                  ? 'Play Selected Card'
                                  : 'Tap a playable card in your hand')
                              : 'Waiting for your turn...',
                          style: TextStyle(
                            color: isMyTurn && gameState.selectedCardIndex != -1
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
