import 'package:flutter/material.dart';

class PlayerTile extends StatelessWidget {
  final String name;
  final bool isYou;
  final bool isHost;
  final bool isWinner;
  final bool isEmpty;
  final int? score;

  const PlayerTile({
    super.key,
    required this.name,
    this.isYou = false,
    this.isHost = false,
    this.isWinner = false,
    this.isEmpty = false,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                color: const Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Waiting for player...',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1F5F9),
            ),
            alignment: Alignment.center,
            child: isHost
                ? const Text('👑', style: TextStyle(fontSize: 16))
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (isYou)
                  const Text(
                    ' (You)',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          if (score != null) ...[
            Text(
              '$score pts',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Pill tag
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Winner',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
