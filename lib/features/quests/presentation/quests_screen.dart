import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DAILY QUESTS & ACHIEVEMENTS',
            style: AppTypography.heading(fontSize: 16)),
        backgroundColor: AppColors.midnightPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuestItem(
              'Defeat 20 Enemies', 'Progress: 12/20', '💰 +300 Coins', 0.6),
          _buildQuestItem('Cast 30 Spells', 'Progress: 30/30 (Completed!)',
              '💎 +15 Crystals', 1.0,
              isDone: true),
          _buildQuestItem(
              'Defeat 1 Chapter Boss', 'Progress: 0/1', '📦 Rare Chest', 0.0),
          _buildQuestItem('Upgrade Any Spell', 'Progress: 1/1 (Completed!)',
              '💰 +200 Coins', 1.0,
              isDone: true),
        ],
      ),
    );
  }

  Widget _buildQuestItem(
      String title, String progress, String reward, double percent,
      {bool isDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDone ? AppColors.gold : AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.heading(fontSize: 14)),
              Text(reward, style: AppTypography.caption(color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(progress, style: AppTypography.caption()),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            color: isDone ? AppColors.gold : AppColors.arcaneBlue,
            backgroundColor: AppColors.deepNavy,
          ),
        ],
      ),
    );
  }
}
