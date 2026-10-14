import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/game_card_model.dart';
import 'card_frame_painter.dart';
import 'card_particle_canvas.dart';
import 'foil_overlay_painter.dart';
import 'rarity_gem.dart';

class GameCard extends StatefulWidget {
  final GameCardModel card;
  final VoidCallback? onTap;
  final bool isInteractive;

  const GameCard({
    super.key,
    required this.card,
    this.onTap,
    this.isInteractive = true,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isPressed = false;

  void _onPointerMove(PointerMoveEvent event, Size cardSize) {
    if (!widget.isInteractive) return;

    final dx = event.localPosition.dx - (cardSize.width / 2);
    final dy = event.localPosition.dy - (cardSize.height / 2);

    setState(() {
      _tiltX = (dy / (cardSize.height / 2)).clamp(-1.0, 1.0) *
          -0.08; // ~4.5 degrees max
      _tiltY = (dx / (cardSize.width / 2)).clamp(-1.0, 1.0) * 0.08;
    });
  }

  void _onPointerUp() {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return AspectRatio(
      aspectRatio: 0.69,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

          final cardTransform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 3D Perspective
            ..rotateX(_tiltX)
            ..rotateY(_tiltY)
            ..scaleByDouble(
                _isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0, 1.0);

          return Listener(
            onPointerDown: (_) => setState(() => _isPressed = true),
            onPointerMove: (e) => _onPointerMove(e, cardSize),
            onPointerUp: (_) {
              _onPointerUp();
              widget.onTap?.call();
            },
            onPointerCancel: (_) => _onPointerUp(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: cardTransform,
              transformAlignment: Alignment.center,
              child: Stack(
                children: [
                  // Base Carved Metallic Frame Painter
                  CustomPaint(
                    size: cardSize,
                    painter: CardFramePainter(
                      rarity: card.rarity,
                      element: card.element,
                      isUnlocked: card.isUnlocked,
                    ),
                  ),

                  // Elemental Animated Particles
                  if (card.isUnlocked && card.rarity.hasParticles)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CardParticleCanvas(element: card.element),
                      ),
                    ),

                  // Top Header Row (Dual Index Symbol 'W'/'Z'/'1-13', Name, Rarity)
                  Positioned(
                    top: 10,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dual Corner Index Symbol Badge ('W' / 'Z' / '1-13')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: card.element.accentColor
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: card.element.accentColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                card.indexSymbol,
                                style: AppTypography.statLabel(
                                  color: card.element.accentColor,
                                  fontSize:
                                      constraints.maxWidth < 180 ? 12 : 14,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                card.element.iconData,
                                size: 11,
                                color: card.element.accentColor,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              card.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displayTitle(
                                color: card.isUnlocked
                                    ? AppColors.gold
                                    : AppColors.textDim,
                                fontSize: constraints.maxWidth < 180 ? 10 : 12,
                              ),
                            ),
                          ),
                        ),
                        RarityGem(rarity: card.rarity),
                      ],
                    ),
                  ),

                  // Center Recessed Artwork View with Library Vector Icons & Dual Mirrored Layout
                  Positioned(
                    top: 42,
                    left: 14,
                    right: 14,
                    height: cardSize.height * 0.56,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Cinematic Background Radial Light
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: RadialGradient(
                              colors: [
                                card.element.accentColor.withValues(
                                    alpha: card.isUnlocked ? 0.35 : 0.05),
                                const Color(0xFF070B14),
                              ],
                              stops: const [0.2, 1.0],
                            ),
                          ),
                        ),

                        // Authentic Mirrored Dual Artwork for Wizard 'W' & Jester 'Z'
                        if (card.cardType == CardType.wizard ||
                            card.cardType == CardType.jester)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                card.iconData,
                                size: constraints.maxWidth * 0.28,
                                color: card.element.accentColor,
                              ),
                              RotatedBox(
                                quarterTurns: 2,
                                child: Icon(
                                  card.iconData,
                                  size: constraints.maxWidth * 0.28,
                                  color: card.element.accentColor,
                                ),
                              ),
                            ],
                          )
                        else
                          // Suit Artwork Main Symbol with 3D Depth Scale
                          Positioned(
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: card.element.accentColor
                                    .withValues(alpha: 0.15),
                                border: Border.all(
                                    color: card.element.accentColor
                                        .withValues(alpha: 0.4),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: card.element.accentColor
                                        .withValues(alpha: 0.4),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Icon(
                                card.iconData,
                                size: constraints.maxWidth * 0.26,
                                color: card.element.accentColor,
                              ),
                            ),
                          ),

                        // Element Rune Watermark in Bottom Right Inner Frame
                        Positioned(
                          bottom: 6,
                          right: 8,
                          child: Icon(
                            card.element.iconData,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),

                        // Bottom-Left Secondary Mirrored Corner Index Symbol ('W'/'Z'/'1-13')
                        Positioned(
                          bottom: 6,
                          left: 8,
                          child: Text(
                            card.indexSymbol,
                            style: AppTypography.statLabel(
                              color: card.element.accentColor
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Text Panel (Type, Ability, Description, Stats)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    height: cardSize.height * 0.30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Type Header Badge & Level
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.cardType.displayName,
                              style: AppTypography.statLabel(
                                color: card.element.accentColor,
                                fontSize: 9,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.gold, width: 0.8),
                              ),
                              child: Text(
                                'LVL ${card.level}',
                                style: AppTypography.statLabel(
                                  color: AppColors.gold,
                                  fontSize: 8.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Ability Name
                        Text(
                          card.abilityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.heading(
                            color: Colors.white,
                            fontSize: constraints.maxWidth < 180 ? 10 : 11,
                          ),
                        ),

                        // Description
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 4),
                            child: Text(
                              card.description,
                              maxLines: constraints.maxWidth < 180 ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(
                                color: AppColors.textMuted,
                                fontSize: constraints.maxWidth < 180 ? 8 : 9,
                              ),
                            ),
                          ),
                        ),

                        // Footer Secondary Stats Bar (DMG / DEF / CRIT / CD)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('DMG', '${card.damage.toInt()}',
                                  AppColors.fireOrange),
                              _buildStatItem(
                                  'CRIT',
                                  '+${(card.criticalChance * 100).toInt()}%',
                                  AppColors.gold),
                              _buildStatItem('CD', '${card.cooldown}s',
                                  AppColors.magicCyan),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Specular Holographic Foil Reflections for Legendary & Mythic Cards
                  if (card.isUnlocked && card.rarity.hasFoil)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: FoilOverlayPainter(
                            tiltX: _tiltX,
                            tiltY: _tiltY,
                            opacity:
                                card.rarity == CardRarity.mythic ? 0.45 : 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Locked Card Silhouette Overlay
                  if (!card.isUnlocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                color: AppColors.gold, size: 36),
                            const SizedBox(height: 6),
                            Text(
                              'LOCKED CARD',
                              style: AppTypography.heading(
                                  color: AppColors.textDim, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: AppTypography.caption(color: Colors.white54, fontSize: 8),
        ),
        Text(
          value,
          style: AppTypography.statLabel(color: color, fontSize: 9),
        ),
      ],
    );
  }
}
