import 'package:flutter/material.dart';

class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;
  final double elevation;
  final Color? baseColor;

  const CardBackWidget({
    super.key,
    this.width = 64,
    this.height = 92,
    this.elevation = 2.0,
    this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = baseColor ?? const Color(0xFF1E3A8A); // Deep Royal Navy

    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(6),
      color: Colors.white,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF93C5FD), width: 1.0),
          ),
          child: CustomPaint(
            painter: _CardBackPatternPainter(),
            child: Center(
              child: Container(
                width: width * 0.45,
                height: height * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bg.withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                ),
                child: const Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 8.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
