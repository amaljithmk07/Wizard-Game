import 'package:flutter/material.dart';
import '../../models/game_card_model.dart';

class CardFramePainter extends CustomPainter {
  final CardRarity rarity;
  final CardElement element;
  final bool isUnlocked;

  CardFramePainter({
    required this.rarity,
    required this.element,
    this.isUnlocked = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Outer Base Metallic Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Outer Frame Gradient (Dark Iron / Cold Steel / Antique Gold / Obsidian)
    final outerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isUnlocked
          ? [
              rarity.primaryColor.withValues(alpha: 0.8),
              rarity.frameColor,
              const Color(0xFF090B12),
            ]
          : [
              const Color(0xFF333333),
              const Color(0xFF1A1A1A),
              const Color(0xFF0D0D0D),
            ],
    );

    canvas.drawRRect(
      rrect,
      Paint()..shader = outerGradient.createShader(rect),
    );

    // Inner Carved Frame Border Offset
    final innerRect = rect.deflate(6);
    final innerRRect =
        RRect.fromRectAndRadius(innerRect, const Radius.circular(12));

    final innerFrameGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: isUnlocked
          ? [
              element.accentColor.withValues(alpha: 0.6),
              const Color(0xFF1E1B2E),
              const Color(0xFF0A0814),
            ]
          : [
              const Color(0xFF222222),
              const Color(0xFF111111),
            ],
    );

    canvas.drawRRect(
      innerRRect,
      Paint()..shader = innerFrameGradient.createShader(innerRect),
    );

    // Inner Bevel Highlight Line (Top-Left Key Light)
    final path = Path()
      ..addRRect(rrect)
      ..addRRect(innerRRect);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isUnlocked ? 0.35 : 0.1),
          rarity.primaryColor.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, highlightPaint);

    // Inner Artwork Recessed Container (58% Height)
    final artHeight = size.height * 0.58;
    final artRect = Rect.fromLTWH(12, 42, size.width - 24, artHeight);
    final artRRect = RRect.fromRectAndRadius(artRect, const Radius.circular(8));

    // Recessed Shadow inside Artwork Frame
    canvas.drawRRect(
      artRRect,
      Paint()..color = const Color(0xFF05070E),
    );

    // Artwork Inner Border Frame Stroke
    final artBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: isUnlocked
            ? [
                rarity.primaryColor.withValues(alpha: 0.9),
                element.accentColor.withValues(alpha: 0.7),
                const Color(0xFF1A1D2B),
              ]
            : [
                const Color(0xFF444444),
                const Color(0xFF222222),
              ],
      ).createShader(artRect);

    canvas.drawRRect(artRRect, artBorderPaint);

    // Bottom Text Panel Embossed Leather Container
    final textPanelRect = Rect.fromLTWH(
      12,
      artRect.bottom + 6,
      size.width - 24,
      size.height - artRect.bottom - 18,
    );
    final textPanelRRect =
        RRect.fromRectAndRadius(textPanelRect, const Radius.circular(10));

    const textPanelGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF13111C),
        Color(0xFF0A0910),
      ],
    );

    canvas.drawRRect(
      textPanelRRect,
      Paint()..shader = textPanelGradient.createShader(textPanelRect),
    );

    // Text Panel Border Line
    canvas.drawRRect(
      textPanelRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = isUnlocked
            ? rarity.primaryColor.withValues(alpha: 0.4)
            : const Color(0xFF333333),
    );
  }

  @override
  bool shouldRepaint(covariant CardFramePainter oldDelegate) {
    return oldDelegate.rarity != rarity ||
        oldDelegate.element != element ||
        oldDelegate.isUnlocked != isUnlocked;
  }
}
