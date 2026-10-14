import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../logic/wizard_rules.dart';
import '../widgets/card_widget.dart';

class PlayerData {
  final int id;
  final String name;
  final bool isHuman;

  PlayerData({required this.id, required this.name, required this.isHuman});
}

class GameBoardScreen extends StatelessWidget {
  final List<PlayerData> players;
  final List<List<CardModel>> hands;
  final Map<int, int> bids;
  final Map<int, int> tricksWon;
  final List<PlayedCard> currentTrick;
  final Suit? trumpSuit;
  final CardModel? trumpCard;
  final int activePlayerIndex;
  final String phase;
  final int dealerIndex;
  final TrickResult? lastTrickWinner;
  final List<int> scores;
  final int roundNumber;
  final Function(CardModel) onPlayCard;
  final VoidCallback onStartNextTrick;
  final VoidCallback onStartNextRound;

  const GameBoardScreen({
    super.key,
    required this.players,
    required this.hands,
    required this.bids,
    required this.tricksWon,
    required this.currentTrick,
    this.trumpSuit,
    this.trumpCard,
    required this.activePlayerIndex,
    required this.phase,
    required this.dealerIndex,
    this.lastTrickWinner,
    required this.scores,
    required this.roundNumber,
    required this.onPlayCard,
    required this.onStartNextTrick,
    required this.onStartNextRound,
  });

  @override
  Widget build(BuildContext context) {
    final humanHand = sortHand(hands[0], trumpSuit);
    final legalHumanCards = getLegalCards(humanHand, currentTrick);

    return Container(
      color: const Color(0xFF0D1322),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 1; i < players.length; i++)
                  _buildAIBadge(i, activePlayerIndex == i && phase == 'play'),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (trumpCard != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        const Text('Trump',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 9)),
                        const SizedBox(height: 2),
                        CardWidget(
                            card: trumpCard, isPlayable: false, isSmall: true),
                      ],
                    ),
                  ),
                if (currentTrick.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: currentTrick.map((play) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            players[play.playerIndex].name,
                            style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          CardWidget(card: play.card, isPlayable: false),
                        ],
                      );
                    }).toList(),
                  )
                else if (phase == 'play')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      activePlayerIndex == 0
                          ? 'Your turn to lead!'
                          : 'Waiting for ${players[activePlayerIndex].name}...',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                if (phase == 'trick_result' && lastTrickWinner != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1C40F)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 10)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${players[lastTrickWinner!.winningPlayerIndex].name} won the trick!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('(${lastTrickWinner!.reason})',
                            style: const TextStyle(
                                color: Color(0xFFF1C40F), fontSize: 11)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: onStartNextTrick,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1C40F)),
                          child: const Text('Next Trick',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                if (phase == 'round_result')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161E30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1C40F)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Round $roundNumber Complete!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: onStartNextRound,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1C40F)),
                          child: Text('Start Round ${roundNumber + 1}',
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: activePlayerIndex == 0 && phase == 'play'
                    ? const Color(0xFFF1C40F)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(players[0].name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Row(
                      children: [
                        Text('Bid: ${bids[0] ?? "-"}',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(width: 10),
                        Text('Won: ${tricksWon[0] ?? 0}',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(width: 10),
                        Text('Score: ${scores[0]}',
                            style: const TextStyle(
                                color: Color(0xFFF1C40F),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: humanHand.length,
                    itemBuilder: (context, index) {
                      final card = humanHand[index];
                      final isPlayable = phase == 'play' &&
                          activePlayerIndex == 0 &&
                          legalHumanCards.any((c) => c.id == card.id);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: CardWidget(
                          card: card,
                          isPlayable: isPlayable,
                          isDisabled: !isPlayable &&
                              activePlayerIndex == 0 &&
                              phase == 'play',
                          onTap: () => onPlayCard(card),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBadge(int pIdx, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFF1C40F).withValues(alpha: 0.2)
            : const Color(0xFF161E30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFFF1C40F)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Color(0xFFCBD5E1), size: 14),
              const SizedBox(width: 4),
              Text(players[pIdx].name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              if (dealerIndex == pIdx)
                const Text(' 👑', style: TextStyle(fontSize: 10)),
            ],
          ),
          Text(
            'Bid: ${bids[pIdx] ?? "-"} | Won: ${tricksWon[pIdx] ?? 0}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
