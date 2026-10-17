import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/socket_service.dart';
import '../../models/game_card.dart';
import '../../models/game_room.dart';
import '../../models/game_state.dart';
import '../../models/player.dart';
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
  int _selectedBid = 0;

  @override
  void initState() {
    super.initState();
    _listenToGameEvents();
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

  Widget _buildSuitChoiceButton(BuildContext ctx, String suit, String symbol, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
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
          Text(symbol, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(suit, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for error messages from server (e.g. Must follow suit!)
    ref.listen<GameState>(gameProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
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
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
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
    final opponents = room.players.where((p) => p.id != socketId).toList();
    final myPlayer = room.players.firstWhere((p) => p.id == socketId, orElse: () => room.players.first);

    final bool isMyTurn = gameState.isMyTurn;
    final bool isBidding = wizardState.isBiddingPhase;
    final bool isRoundOver = wizardState.isRoundOver;
    final int currentRound = wizardState.round;
    final int totalRounds = wizardState.totalRounds;

    // Check if dealer needs to choose trump
    if (wizardState.trumpCard?.isWizard == true && myPlayer.isDealer && wizardState.trumpSuit == 'Spades') {
      // Allow dealer to choose trump suit
    }

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
            Text(
              'Round $currentRound of $totalRounds',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isBidding
                  ? (isMyTurn ? 'YOUR TURN TO BID' : 'BIDDING: ${gameState.currentTurnPlayerName}\'s turn')
                  : (isMyTurn ? 'YOUR TURN TO PLAY' : '${gameState.currentTurnPlayerName}\'s turn'),
              style: TextStyle(
                color: isMyTurn ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                fontSize: 12,
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
            // Round & Trump Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Trump Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TRUMP: ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        if (wizardState.trumpSuit != null) ...[
                          Text(
                            _getSuitSymbol(wizardState.trumpSuit!),
                            style: TextStyle(
                              fontSize: 15,
                              color: _getSuitColor(wizardState.trumpSuit!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wizardState.trumpSuit!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _getSuitColor(wizardState.trumpSuit!),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'NO TRUMP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Revealed Trump Mini Card
                  if (wizardState.trumpCard != null) ...[
                    const Text(
                      'Card: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    GameCardWidget(
                      card: wizardState.trumpCard,
                      width: 28,
                      height: 38,
                    ),
                  ],
                ],
              ),
            ),

            // Opponents Horizontal Row (Shows avatars, bids, tricks won, scores)
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: opponents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final opp = opponents[index];
                  final bool isTurn = wizardState.currentTurnIndex < room.players.length &&
                      room.players[wizardState.currentTurnIndex].id == opp.id;

                  return Container(
                    width: 125,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isTurn ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isTurn ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: isTurn ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isTurn ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                opp.name.isNotEmpty ? opp.name[0].toUpperCase() : 'P',
                                style: TextStyle(
                                  color: isTurn ? Colors.white : const Color(0xFF334155),
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
                                  fontSize: 12,
                                  fontWeight: isTurn ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (opp.isDealer) ...[
                              const Text(' 👑', style: TextStyle(fontSize: 11)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bid: ${opp.bid ?? "-"} | Won: ${opp.tricksWon}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${opp.score}p',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Center Trick Table Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  children: [
                    // Center Trick Cards
                    Center(
                      child: wizardState.playedCards.isNotEmpty
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: wizardState.playedCards.map((item) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GameCardWidget(
                                      card: item.card,
                                      width: 58,
                                      height: 84,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Text(
                                        item.playerName,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBidding ? Icons.record_voice_over_rounded : Icons.style_outlined,
                                  size: 40,
                                  color: const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isBidding
                                      ? 'Bidding in progress...'
                                      : (wizardState.ledSuit != null
                                          ? 'Led suit: ${wizardState.ledSuit}'
                                          : 'Lead a card to start trick'),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Trick Winner Banner Overlay
                    if (wizardState.trickWinnerName != null) ...[
                      Positioned(
                        top: 12,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                            ],
                          ),
                          child: Text(
                            '🎉 ${wizardState.trickWinnerName} won the trick!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Round Over Summary Overlay
                    if (isRoundOver && wizardState.roundScores != null) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Round $currentRound Complete!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 12),
                              ...wizardState.roundScores!.map((rs) {
                                final pts = rs['roundPoints'] ?? 0;
                                final bool isPositive = pts >= 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${rs['playerName']} (Bid: ${rs['bid']}, Won: ${rs['tricksWon']})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text(
                                        '${isPositive ? "+" : ""}$pts pts  [Total: ${rs['totalScore']}]',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 12),
                              const Text('Next round starting shortly...',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Player Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // My Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            myPlayer.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          if (myPlayer.isDealer) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('DEALER 👑', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Bid: ${myPlayer.bid ?? "-"} | Won: ${myPlayer.tricksWon} | Score: ${myPlayer.score}p',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Interactive Bidding Selector (when it's player's turn to bid)
                  if (isBidding && isMyTurn) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Bid for Round $currentRound (0 to $currentRound tricks):',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(currentRound + 1, (bidNum) {
                                final isSelected = _selectedBid == bidNum;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                      foregroundColor: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      minimumSize: const Size(40, 36),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      elevation: 0,
                                      side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                                    ),
                                    onPressed: () => setState(() => _selectedBid = bidNum),
                                    child: Text('$bidNum', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                ref.read(gameProvider.notifier).submitBid(_selectedBid);
                              },
                              child: Text('Submit Bid ($_selectedBid)', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Hand Cards
                  SizedBox(
                    height: 100,
                    child: gameState.myHand.isEmpty
                        ? const Center(
                            child: Text('No cards in hand', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: gameState.myHand.length,
                            itemBuilder: (context, index) {
                              final card = gameState.myHand[index];
                              final isSelected = gameState.selectedCardIndex == index;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
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

                  const SizedBox(height: 8),

                  // Play Card Button
                  if (!isBidding)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (isMyTurn && gameState.selectedCardIndex != -1)
                            ? () {
                                ref.read(gameProvider.notifier).playSelectedCard();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isMyTurn
                              ? (gameState.selectedCardIndex != -1 ? 'Play Selected Card' : 'Select a card to play')
                              : 'Waiting for your turn...',
                          style: TextStyle(
                            color: isMyTurn && gameState.selectedCardIndex != -1 ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 15,
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

  String _getSuitSymbol(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
        return '♥';
      case 'diamonds':
        return '♦';
      case 'clubs':
        return '♣';
      case 'spades':
      default:
        return '♠';
    }
  }

  Color _getSuitColor(String suit) {
    if (suit.toLowerCase() == 'hearts' || suit.toLowerCase() == 'diamonds') {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF1E293B);
  }
}
