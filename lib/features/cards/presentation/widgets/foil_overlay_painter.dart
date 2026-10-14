import 'package:flutter/material.dart';

class FoilOverlayPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;
  final double opacity;

  FoilOverlayPainter({
    required this.tiltX,
    required this.tiltY,
    this.opacity = 0.35,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Dynamic spectral rainbow highlight offset calculated from tilt position
    final centerX = size.width / 2 + (tiltY * size.width * 2.0);
    final centerY = size.height / 2 + (tiltX * size.height * 2.0);

    final foilGradient = RadialGradient(
      center: Alignment(
        (centerX / size.width) * 2 - 1,
        (centerY / size.height) * 2 - 1,
      ),
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: opacity * 0.7),
        Colors.cyanAccent.withValues(alpha: opacity * 0.5),
        Colors.purpleAccent.withValues(alpha: opacity * 0.4),
        Colors.amberAccent.withValues(alpha: opacity * 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = foilGradient.createShader(rect)
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(covariant FoilOverlayPainter oldDelegate) {
    return oldDelegate.tiltX != tiltX ||
        oldDelegate.tiltY != tiltY ||
        oldDelegate.opacity != opacity;
  }
}
