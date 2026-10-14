import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_widget.dart';

class BiddingDialog extends StatefulWidget {
  final List<CardModel> hand;
  final int roundNumber;
  final Suit? trumpSuit;
  final Function(int) onSelectBid;

  const BiddingDialog({
    super.key,
    required this.hand,
    required this.roundNumber,
    this.trumpSuit,
    required this.onSelectBid,
  });

  @override
  State<BiddingDialog> createState() => _BiddingDialogState();
}

class _BiddingDialogState extends State<BiddingDialog> {
  int selectedBid = 0;

  @override
  Widget build(BuildContext context) {
    final sorted = sortHand(widget.hand, widget.trumpSuit);

    return Dialog(
      backgroundColor: const Color(0xFF161E30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.track_changes,
                    color: Color(0xFFF1C40F), size: 22),
                const SizedBox(width: 6),
                Text('Round ${widget.roundNumber} Bidding',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('How many tricks will you win out of ${widget.roundNumber}?',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: CardWidget(
                        card: sorted[index], isPlayable: false, isSmall: true),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('$selectedBid',
                style: const TextStyle(
                    color: Color(0xFFF1C40F),
                    fontSize: 36,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i <= widget.roundNumber; i++)
                  GestureDetector(
                    onTap: () => setState(() => selectedBid = i),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selectedBid == i
                            ? const Color(0xFFF1C40F)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$i',
                        style: TextStyle(
                          color: selectedBid == i ? Colors.black : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onSelectBid(selectedBid),
                icon: const Icon(Icons.check_circle,
                    size: 18, color: Colors.black),
                label: Text('Confirm Bid: $selectedBid',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1C40F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
