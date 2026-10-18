import 'package:flutter/material.dart';

class JesterCardWidget extends StatelessWidget {
  final double width;
  final double height;
  final double elevation;

  const JesterCardWidget({
    super.key,
    this.width = 64,
    this.height = 92,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    const primaryAmber = Color(0xFFB45309); // Warm amber
    const secondaryColor = Color(0xFFDC2626); // Crimson

    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(6),
      color: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.4),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Top-Left Index: 'N' (Narr / Jester) and bell
            const Positioned(
              top: 0,
              left: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'N',
                    style: TextStyle(
                      color: primaryAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      fontFamily: 'serif',
                    ),
                  ),
                  Text(
                    '🔔',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom-Right Inverted Index
            const Positioned(
              bottom: 0,
              right: 0,
              child: RotatedBox(
                quarterTurns: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'N',
                      style: TextStyle(
                        color: primaryAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      '🔔',
                      style: TextStyle(
                        fontSize: 8,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Jester Artwork & Banner
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: width * 0.52,
                    height: height * 0.44,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFBBF24), width: 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🃏',
                      style: TextStyle(fontSize: (height * 0.22).clamp(16.0, 32.0)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'JESTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
