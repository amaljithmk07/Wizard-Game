import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_card.dart';
import '../models/game_room.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'card_back_widget.dart';
import 'game_card_widget.dart';

class PokerTableWidget extends StatelessWidget {
  final GameRoom room;
  final GameStateModel gameState;
  final String myPlayerId;
  final VoidCallback? onDealerPickTrump;

  const PokerTableWidget({
    super.key,
    required this.room,
    required this.gameState,
    required this.myPlayerId,
    this.onDealerPickTrump,
  });

  @override
  Widget build(BuildContext context) {
    final players = room.players;
    final totalPlayers = players.length;

    // Find my index to rotate table so I am at the bottom (seat 0)
    final myIndex = players.indexWhere((p) => p.id == myPlayerId);
    final myPlayer = myIndex != -1 ? players[myIndex] : null;

    final currentTurnPlayer = (gameState.currentTurnIndex >= 0 &&
            gameState.currentTurnIndex < players.length)
        ? players[gameState.currentTurnIndex]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.1),
          radius: 0.95,
          colors: [
            Color(0xFF1E3A5F), // Deep felt navy
            Color(0xFF0F172A), // Dark table edge
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          final tableHeight = constraints.maxHeight;

          // Seating positions around the table
          final List<Widget> seatWidgets = [];
          final Map<String, Offset> playerCardOffsets = {};

          // Radii for seating relative to center (0.5, 0.5)
          final double radiusX = (tableWidth * 0.40).clamp(110.0, 220.0);
          final double radiusY = (tableHeight * 0.38).clamp(80.0, 160.0);

          final centerX = tableWidth / 2.0;
          final centerY = tableHeight / 2.0;

          for (int i = 0; i < totalPlayers; i++) {
            // Relative seat index where 0 is bottom (Me)
            final int relativeSeat = myIndex != -1
                ? (i - myIndex + totalPlayers) % totalPlayers
                : i;

            // Angle: relativeSeat 0 is at bottom (pi radians)
            // Clockwise rotation: 1 is left, 2 is top-left, etc.
            final double angle =
                math.pi + (2.0 * math.pi * relativeSeat / totalPlayers);

            final seatX = centerX + radiusX * math.sin(angle);
            final seatY = centerY - radiusY * math.cos(angle);

            // Vector for trick card displacement towards seat
            final double cardDispX = (seatX - centerX) * 0.38;
            final double cardDispY = (seatY - centerY) * 0.38;
            playerCardOffsets[players[i].id] = Offset(cardDispX, cardDispY);

            // Only render seat chips for opponents (seat != 0) since Me is in bottom bar
            if (relativeSeat != 0) {
              final player = players[i];
              final isTurn = currentTurnPlayer?.id == player.id;
              final isDealer = room.gameState?.dealerIndex == i;

              seatWidgets.add(
                Positioned(
                  left: seatX - 45,
                  top: seatY - 26,
                  child: _OpponentSeatChip(
                    player: player,
                    isCurrentTurn: isTurn,
                    isDealer: isDealer,
                    phase: gameState.phase,
                  ),
                ),
              );
            }
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Felt Ring decoration
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: tableWidth * 0.72,
                    height: tableHeight * 0.65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(80),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Center Table Info (Trump & Led Suit)
              Positioned(
                left: 12,
                top: 12,
                child: _TableTrumpInfoBadge(
                  trumpCard: gameState.trumpCard,
                  trumpSuit: gameState.trumpSuit,
                  ledSuit: gameState.ledSuit,
                  isDealer: myPlayer?.isDealer == true,
                  onDealerPickTrump: onDealerPickTrump,
                ),
              ),

              // Opponent Seats
              ...seatWidgets,

              // Center Trick Area (Played cards positioned towards their player's seat)
              Positioned.fill(
                child: Center(
                  child: _TrickCenterArea(
                    playedCards: gameState.playedCards,
                    playerCardOffsets: playerCardOffsets,
                    trickWinnerName: gameState.trickWinnerName,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpponentSeatChip extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final bool isDealer;
  final String phase;

  const _OpponentSeatChip({
    required this.player,
    required this.isCurrentTurn,
    required this.isDealer,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini card back stack showing remaining hand
        if (player.handCount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CardBackWidget(width: 16, height: 22, elevation: 1),
              const SizedBox(width: 2),
              Text(
                '×${player.handCount}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        const SizedBox(height: 2),

        // Player Name & Turn Badge
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: isCurrentTurn
                ? const Color(0xFF1E40AF)
                : const Color(0xFF1E293B).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentTurn
                  ? const Color(0xFF60A5FA)
                  : (isDealer ? const Color(0xFFFCD34D) : const Color(0xFF475569)),
              width: isCurrentTurn ? 1.8 : 1.0,
            ),
            boxShadow: isCurrentTurn
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDealer) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 62),
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentTurn ? Colors.white : const Color(0xFFF1F5F9),
                    fontSize: 10,
                    fontWeight: isCurrentTurn ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bid & Tricks Indicator
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            player.bid != null
                ? 'B:${player.bid} W:${player.tricksWon}'
                : (phase == 'BIDDING' ? 'Bidding...' : 'Score: ${player.score}'),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrickCenterArea extends StatelessWidget {
  final List<PlayedCardItem> playedCards;
  final Map<String, Offset> playerCardOffsets;
  final String? trickWinnerName;

  const _TrickCenterArea({
    required this.playedCards,
    required this.playerCardOffsets,
    this.trickWinnerName,
  });

  @override
  Widget build(BuildContext context) {
    if (playedCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: const Text(
          'Trick Table',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Each played card animated from / positioned near its player's seat
        ...playedCards.map((item) {
          final offset = playerCardOffsets[item.playerId] ?? Offset.zero;
          final bool isWinner = trickWinnerName != null &&
              item.playerName.toLowerCase() == trickWinnerName!.toLowerCase();

          return Transform.translate(
            offset: offset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameCardWidget(
                  card: item.card,
                  width: 44,
                  height: 64,
                  elevation: isWinner ? 6 : 3,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E293B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),

        // Trick Winner Banner Overlay
        if (trickWinnerName != null)
          Positioned(
            bottom: -32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆 ', style: TextStyle(fontSize: 11)),
                  Text(
                    '$trickWinnerName takes the trick!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TableTrumpInfoBadge extends StatelessWidget {
  final GameCard? trumpCard;
  final String? trumpSuit;
  final String? ledSuit;
  final bool isDealer;
  final VoidCallback? onDealerPickTrump;

  const _TableTrumpInfoBadge({
    this.trumpCard,
    this.trumpSuit,
    this.ledSuit,
    this.isDealer = false,
    this.onDealerPickTrump,
  });

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
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF93C5FD);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trumpCard != null) ...[
            GameCardWidget(
              card: trumpCard,
              width: 22,
              height: 30,
              elevation: 1,
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TRUMP: ',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (trumpSuit != null && trumpSuit != 'None') ...[
                    Text(
                      _getSuitSymbol(trumpSuit!),
                      style: TextStyle(
                        color: _getSuitColor(trumpSuit!),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trumpSuit!,
                      style: TextStyle(
                        color: _getSuitColor(trumpSuit!),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'NONE',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              if (ledSuit != null && ledSuit != 'None') ...[
                const SizedBox(height: 1),
                Text(
                  'Led: ${_getSuitSymbol(ledSuit!)} $ledSuit',
                  style: TextStyle(
                    color: _getSuitColor(ledSuit!),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (trumpCard?.isWizard == true && isDealer && onDealerPickTrump != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDealerPickTrump,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PICK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
