import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/game_card_model.dart';
import 'widgets/card_frame_painter.dart';
import 'widgets/game_card.dart';

class CardRevealDialog extends StatefulWidget {
  final GameCardModel card;

  const CardRevealDialog({super.key, required this.card});

  @override
  State<CardRevealDialog> createState() => _CardRevealDialogState();
}

class _CardRevealDialogState extends State<CardRevealDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Trigger dramatic flip after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _flipController.forward().then((_) {
          setState(() => _isFlipped = true);
        });
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Atmospheric Particles & Radial Burst
          Container(
            width: 340,
            height: 520,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  card.rarity.glowColor,
                  Colors.transparent,
                ],
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEW CARD UNLOCKED!',
                style: AppTypography.displayTitle(
                    color: AppColors.gold, fontSize: 20),
              ).animate().fadeIn().moveY(begin: -20, end: 0),
              const SizedBox(height: 16),

              // 3D Animated Card Flip Container
              AnimatedBuilder(
                animation: _flipController,
                builder: (context, child) {
                  final angle = _flipController.value * pi;
                  final isShowingBack = angle < (pi / 2);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isShowingBack
                        ? _buildCardBack(card)
                        : Transform(
                            transform: Matrix4.identity()..rotateY(pi),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 260,
                              height: 380,
                              child: GameCard(card: card, isInteractive: true),
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(height: 20),

              if (_isFlipped)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CLAIM CARD',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ).animate().fadeIn().scale(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(GameCardModel card) {
    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF130E22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.rarity.primaryColor, width: 2),
        boxShadow: [
          BoxShadow(color: card.rarity.glowColor, blurRadius: 20),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 380),
            painter:
                CardFramePainter(rarity: card.rarity, element: card.element),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.gold, size: 56),
              const SizedBox(height: 10),
              Text(
                'ANCIENT ARCANUM',
                style:
                    AppTypography.heading(color: AppColors.gold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
