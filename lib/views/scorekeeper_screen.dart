import 'package:flutter/material.dart';
import '../logic/wizard_rules.dart';

class ScorekeeperScreen extends StatefulWidget {
  final VoidCallback onBackToGame;

  const ScorekeeperScreen({super.key, required this.onBackToGame});

  @override
  State<ScorekeeperScreen> createState() => _ScorekeeperScreenState();
}

class _ScorekeeperScreenState extends State<ScorekeeperScreen> {
  final List<String> players = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
  final TextEditingController nameController = TextEditingController();
  bool gameStarted = false;
  int currentRound = 1;
  String stage = 'bids';
  final Map<int, int> bids = {};
  final Map<int, int> tricks = {};
  final List<Map<String, dynamic>> history = [];

  @override
  Widget build(BuildContext context) {
    final maxRounds = getMaxRounds(players.length);

    return Container(
      color: const Color(0xFF0D1322),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBackToGame,
                icon:
                    const Icon(Icons.arrow_back, size: 14, color: Colors.white),
                label: const Text('Play AI',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const Text('Scorekeeper Companion',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (!gameStarted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161E30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Setup Players (3-6)',
                      style: TextStyle(
                          color: Color(0xFFF1C40F),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter name...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFFF1C40F)),
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty &&
                              players.length < 6) {
                            setState(() {
                              players.add(nameController.text.trim());
                              nameController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...players.asMap().entries.map((e) => Text(
                      '#${e.key + 1} ${e.value}',
                      style: const TextStyle(color: Color(0xFFCBD5E1)))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => gameStarted = true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1C40F)),
                    child: Text('Start Tracking ($maxRounds Rounds)',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161E30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                      'Round $currentRound of $maxRounds - ${stage == "bids" ? "Enter Bids" : "Enter Tricks Won"}',
                      style: const TextStyle(
                          color: Color(0xFFF1C40F),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...players.asMap().entries.map((e) {
                    final idx = e.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: stage == 'bids' ? 'Bid' : 'Won',
                                hintStyle:
                                    const TextStyle(color: Color(0xFF94A3B8)),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final n = int.tryParse(val) ?? 0;
                                if (stage == 'bids') {
                                  bids[idx] = n;
                                } else {
                                  tricks[idx] = n;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (stage == 'bids') {
                        setState(() => stage = 'tricks');
                      } else {
                        final pts = players.asMap().entries.map((e) {
                          return calculateRoundScore(
                              bids[e.key] ?? 0, tricks[e.key] ?? 0);
                        }).toList();

                        setState(() {
                          history.add({
                            'round': currentRound,
                            'bids': Map.from(bids),
                            'tricks': Map.from(tricks),
                            'pts': pts
                          });
                          currentRound++;
                          stage = 'bids';
                          bids.clear();
                          tricks.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1C40F)),
                    child: Text(
                        stage == 'bids'
                            ? 'Confirm Bids'
                            : 'Calculate Round Score',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
