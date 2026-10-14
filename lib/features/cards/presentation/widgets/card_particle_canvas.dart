import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_card_model.dart';

class CardParticleCanvas extends StatefulWidget {
  final CardElement element;
  final bool isEnabled;

  const CardParticleCanvas({
    super.key,
    required this.element,
    this.isEnabled = true,
  });

  @override
  State<CardParticleCanvas> createState() => _CardParticleCanvasState();
}

class _CardParticleCanvasState extends State<CardParticleCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 16; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.15 + _random.nextDouble() * 0.35,
        radius: 1.5 + _random.nextDouble() * 2.5,
        alpha: 0.3 + _random.nextDouble() * 0.6,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (final p in _particles) {
          p.y -= p.speed * 0.01;
          if (p.y < 0) {
            p.y = 1.0;
            p.x = _random.nextDouble();
          }
        }
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            color: widget.element.particleColor,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double radius;
  double alpha;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.alpha,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
