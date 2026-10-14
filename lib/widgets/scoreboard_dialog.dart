import 'package:flutter/material.dart';
import '../views/game_board_screen.dart';

class ScoreboardDialog extends StatelessWidget {
  final List<PlayerData> players;
  final List<Map<int, Map<String, dynamic>>> scoreHistory;
  final List<int> currentScores;
  final bool isGameOver;
  final VoidCallback onClose;
  final VoidCallback onNewGame;

  const ScoreboardDialog({
    super.key,
    required this.players,
    required this.scoreHistory,
    required this.currentScores,
    required this.isGameOver,
    required this.onClose,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161E30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Color(0xFFF1C40F), size: 20),
                    const SizedBox(width: 6),
                    Text(isGameOver ? 'Game Results' : 'Scoreboard',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: onClose),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 10,
                  headingRowHeight: 32,
                  dataRowMinHeight: 28,
                  dataRowMaxHeight: 32,
                  columns: [
                    const DataColumn(
                        label: Text('Rnd',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 10))),
                    ...players.map((p) => DataColumn(
                        label: Text(p.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)))),
                  ],
                  rows: scoreHistory.asMap().entries.map((entry) {
                    final rIdx = entry.key;
                    final rowMap = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('R${rIdx + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))),
                        ...players.asMap().entries.map((pEntry) {
                          final pIdx = pEntry.key;
                          final cell = rowMap[pIdx];
                          if (cell == null) return const DataCell(Text('-'));
                          final isHit = cell['bid'] == cell['tricksWon'];
                          final pts = cell['pts'] as int;
                          return DataCell(
                            Text(
                              '${cell['tricksWon']}/${cell['bid']} (${pts > 0 ? "+$pts" : "$pts"})',
                              style: TextStyle(
                                color: isHit
                                    ? const Color(0xFF2ECC71)
                                    : const Color(0xFFE74C3C),
                                fontSize: 10,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isGameOver ? onNewGame : onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1C40F),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                isGameOver ? 'Play Again' : 'Back to Game',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
