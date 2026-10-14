import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../providers/game_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/player_tile.dart';
import '../server_list/server_list_screen.dart';

class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final room = ref.watch(currentRoomProvider);
    final playerName = ref.watch(playerNameProvider);
    final isDemo = AppConfig.isDemoMode;

    final winnerName =
        gameState.winnerName ?? (playerName.isNotEmpty ? playerName : 'Player');
    final scores = gameState.finalScores.isNotEmpty
        ? gameState.finalScores
        : (room?.players ?? []);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _backToRooms(context, ref);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                if (isDemo) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Text(
                      'DEMO MATCH RESULT',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                // Title
                const Text(
                  'Game Over',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 28),

                // Gold Trophy Badge
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFEF3C7),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '🏆',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 16),

                // Winner Subtitle
                const Text(
                  'Winner',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // Winner Name
                Text(
                  winnerName,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 32),

                // Player Standings List
                Expanded(
                  child: ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      final p = scores[index];
                      final bool isWinner = (p.name == winnerName);

                      return PlayerTile(
                        name: p.name,
                        isWinner: isWinner,
                        score: p.score,
                      );
                    },
                  ),
                ),

                // Back to Rooms Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _backToRooms(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToRooms(BuildContext context, WidgetRef ref) {
    ref.read(currentRoomProvider.notifier).leaveRoom();
    ref.read(gameProvider.notifier).resetGame();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ServerListScreen()),
      (route) => false,
    );
  }
}
