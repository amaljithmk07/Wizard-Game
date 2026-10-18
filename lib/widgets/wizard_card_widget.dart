import 'package:flutter/material.dart';

class WizardCardWidget extends StatelessWidget {
  final double width;
  final double height;
  final double elevation;

  const WizardCardWidget({
    super.key,
    this.width = 64,
    this.height = 92,
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6B21A8); // Deep royal purple
    const accentGold = Color(0xFFD97706);

    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(6),
      color: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9333EA), width: 1.4),
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Top-Left Index: 'W' and star
            const Positioned(
              top: 0,
              left: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'W',
                    style: TextStyle(
                      color: primaryPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      fontFamily: 'serif',
                    ),
                  ),
                  Text(
                    '✦',
                    style: TextStyle(
                      color: accentGold,
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
                      'W',
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: accentGold,
                        fontSize: 8,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Wizard Artwork & Banner
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: width * 0.52,
                    height: height * 0.44,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC084FC), width: 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '🧙‍♂️',
                      style: TextStyle(fontSize: (height * 0.22).clamp(16.0, 32.0)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryPurple,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'WIZARD',
                      style: TextStyle(
                        color: Color(0xFFFDE68A),
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
