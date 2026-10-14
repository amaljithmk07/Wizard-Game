import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../game_engine/game_arena_screen.dart';

class BattleSelectScreen extends StatelessWidget {
  const BattleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT GAME MODE',
                style:
                    AppTypography.heading(color: AppColors.gold, fontSize: 15)),
            Text('Embark on wizard chapters or challenge boss arenas',
                style: AppTypography.caption()),
            const SizedBox(height: 16),

            // Story Campaign Banner
            _buildModeCard(
              context: context,
              icon: '⚔️',
              title: 'STORY CAMPAIGN',
              subtitle: '6 Chapters • 60 Levels • Epic Lore',
              color: AppColors.magicPurple,
              onTap: () => _openMode(context, 'Story Mode: Chapter 1'),
            ),
            const SizedBox(height: 14),

            // Endless Horde Banner
            _buildModeCard(
              context: context,
              icon: '🔥',
              title: 'ENDLESS HORDE',
              subtitle: 'Infinite Waves • High Score Leaderboard',
              color: AppColors.fireOrange,
              onTap: () => _openMode(context, 'Endless Wave Mode'),
            ),
            const SizedBox(height: 14),

            // Boss Arena Banner
            _buildModeCard(
              context: context,
              icon: '🐉',
              title: 'BOSS ARENA',
              subtitle: 'Multi-Phase Legendary Boss Battles',
              color: AppColors.darkMagicRed,
              onTap: () => _openMode(context, 'Boss Arena: Dragon Mountain'),
            ),
            const SizedBox(height: 24),

            Text('STORY CHAPTERS',
                style: AppTypography.heading(
                    color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 10),

            _buildChapterTile(
                context, 'Chapter 1', 'The Forgotten Forest', '🌲', true),
            _buildChapterTile(
                context, 'Chapter 2', 'The Cursed Village', '🏚️', false),
            _buildChapterTile(
                context, 'Chapter 3', 'Crystal Caverns', '💎', false),
            _buildChapterTile(
                context, 'Chapter 4', 'Shadow Kingdom', '🏰', false),
            _buildChapterTile(
                context, 'Chapter 5', 'Dragon Mountain', '🌋', false),
            _buildChapterTile(
                context, 'Chapter 6', 'The Dark Wizard Castle', '💀', false),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.4), AppColors.midnightPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 42)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: AppTypography.displayTitle(
                          fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.caption(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTile(BuildContext context, String chapter, String title,
      String icon, bool isUnlocked) {
    return GestureDetector(
      onTap: isUnlocked ? () => _openMode(context, '$chapter: $title') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isUnlocked
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: 24, color: isUnlocked ? null : Colors.grey)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter,
                    style: AppTypography.caption(
                        color:
                            isUnlocked ? AppColors.gold : AppColors.textDim)),
                Text(title,
                    style: AppTypography.heading(
                        fontSize: 14,
                        color: isUnlocked
                            ? AppColors.textLight
                            : AppColors.textDim)),
              ],
            ),
            const Spacer(),
            Icon(
              isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock,
              color: isUnlocked ? AppColors.gold : AppColors.textDim,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _openMode(BuildContext context, String modeTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameArenaScreen(modeTitle: modeTitle)),
    );
  }
}
