import 'package:flutter/material.dart';
import '../models/card_model.dart';

class TrumpPickerDialog extends StatelessWidget {
  final Function(Suit) onSelectTrump;

  const TrumpPickerDialog({super.key, required this.onSelectTrump});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161E30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            const Text('Wizard Turned Up!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Text('Select Trump Suit for this round:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 16),
            Column(
              children: Suit.values.map((suit) {
                final info = suitsData[suit]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () => onSelectTrump(suit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(color: Color(info.colorHex)),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('${info.symbol} ${info.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
