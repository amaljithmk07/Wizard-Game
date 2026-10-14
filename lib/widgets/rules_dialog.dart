import 'package:flutter/material.dart';

class RulesDialog extends StatelessWidget {
  final VoidCallback onClose;

  const RulesDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161E30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: Color(0xFFF1C40F), size: 20),
                    SizedBox(width: 6),
                    Text('Wizard Rules & Guide',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: onClose),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(
              height: 250,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎴 60-Card Deck',
                        style: TextStyle(
                            color: Color(0xFFF1C40F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(
                        '4 suits (Human 🔥, Elf 🍃, Dwarf 🛡️, Giant 🌊) 1-13 + 4 Wizards (Z) + 4 Jesters (N).',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    SizedBox(height: 8),
                    Text('🎯 Objective',
                        style: TextStyle(
                            color: Color(0xFFF1C40F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text('Predict exact number of tricks won per round.',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    SizedBox(height: 8),
                    Text('⚡ Rules & Overrides',
                        style: TextStyle(
                            color: Color(0xFFF1C40F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'Must follow suit if possible. Wizards and Jesters can always be played anytime!',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    SizedBox(height: 8),
                    Text('👑 Winner Order',
                        style: TextStyle(
                            color: Color(0xFFF1C40F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(
                        '1. First Wizard\n2. Highest Trump\n3. Highest Led Suit\n4. Jesters lose (first Jester wins if only Jesters)',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1C40F),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Got it, Let's Play!",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
