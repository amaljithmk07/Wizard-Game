import 'package:flutter/material.dart';
import '../models/card_model.dart';

class HeaderBar extends StatelessWidget {
  final int roundNumber;
  final int maxRounds;
  final Suit? trumpSuit;
  final String mode;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenScores;
  final VoidCallback onSwitchMode;
  final VoidCallback onNewGame;

  const HeaderBar({
    super.key,
    required this.roundNumber,
    required this.maxRounds,
    this.trumpSuit,
    required this.mode,
    required this.onOpenRules,
    required this.onOpenScores,
    required this.onSwitchMode,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    final trumpInfo = trumpSuit != null ? suitsData[trumpSuit] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0A0E1A),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: onNewGame,
              child: const Row(
                children: [
                  Text('🪄', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 4),
                  Text(
                    'WIZARD',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFFF1C40F),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (mode == 'game')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1C40F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFF1C40F).withValues(alpha: 0.4)),
                ),
                child: Text(
                  'R$roundNumber/$maxRounds',
                  style: const TextStyle(
                    color: Color(0xFFF1C40F),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            if (mode == 'game')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trumpInfo != null
                      ? '${trumpInfo.symbol} ${trumpInfo.name}'
                      : 'No Trump',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.emoji_events,
                  color: Color(0xFFF1C40F), size: 20),
              onPressed: onOpenScores,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.menu_book, color: Colors.white, size: 20),
              onPressed: onOpenRules,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: onSwitchMode,
              icon: const Icon(Icons.phone_android, size: 12),
              label: Text(mode == 'game' ? 'Scorepad' : 'Play AI',
                  style: const TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
