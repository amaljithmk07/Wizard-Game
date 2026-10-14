import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/game_card_model.dart';

class ManaOrb extends StatelessWidget {
  final int manaCost;
  final CardElement element;

  const ManaOrb({
    super.key,
    required this.manaCost,
    required this.element,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            element.accentColor,
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
        border: Border.all(color: const Color(0xFFF5C451), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: element.accentColor.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$manaCost',
        style: AppTypography.displayTitle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}
