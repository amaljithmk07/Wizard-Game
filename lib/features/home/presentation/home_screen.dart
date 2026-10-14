import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../wizard/providers/player_provider.dart';
import '../../wizard/models/player_model.dart';
import '../../battle/presentation/battle_select_screen.dart';
import '../../wizard/presentation/wizard_profile_screen.dart';
import '../../spells/presentation/spell_book_screen.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../shop/presentation/shop_screen.dart';
import '../../cards/presentation/card_collection_screen.dart';
import '../../quests/presentation/quests_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Currency & Profile Header
            _buildHeader(player),

            // Main Body View based on Bottom Navigation
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildHomeTab(player),
                  const BattleSelectScreen(),
                  const CardCollectionScreen(),
                  const WizardProfileScreen(),
                  const SpellBookScreen(),
                  const InventoryScreen(),
                  const ShopScreen(),
                ],
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PlayerModel player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.midnightPurple,
        border:
            Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Player Avatar & Title
          GestureDetector(
            onTap: () => setState(() => _currentNavIndex = 2), // Go to Profile
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.magicPurple, AppColors.arcaneBlue],
                    ),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(player.title.iconData,
                      color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name,
                        style: AppTypography.heading(fontSize: 14)),
                    Row(
                      children: [
                        Text('Lv.${player.level} ',
                            style:
                                AppTypography.caption(color: AppColors.gold)),
                        Text(player.title.displayName,
                            style: AppTypography.caption()),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),

          // Currency Pills
          _buildCurrencyPill(
              Icons.monetization_on_rounded, '${player.coins}', AppColors.gold),
          const SizedBox(width: 8),
          _buildCurrencyPill(Icons.diamond_rounded, '${player.crystals}',
              AppColors.crystalViolet),
          const SizedBox(width: 8),

          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textMuted, size: 22),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.statLabel(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(PlayerModel player) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Preview Banner
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.magicPurple.withValues(alpha: 0.3),
                    blurRadius: 15),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Glowing Magic Circle
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.magicCyan.withValues(alpha: 0.5),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.magicCyan.withValues(alpha: 0.4),
                          blurRadius: 25),
                    ],
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 8.seconds),

                // Wizard Hero Sprite Icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(player.title.icon,
                            style: const TextStyle(fontSize: 72))
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .moveY(begin: -6, end: 6, duration: 1.8.seconds),
                    const SizedBox(height: 8),
                    Text(player.title.displayName,
                        style: AppTypography.displayTitle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Play CTA Button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () =>
                  setState(() => _currentNavIndex = 1), // Go to Battle Select
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                shadowColor: AppColors.gold.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      size: 36, color: Colors.black),
                  const SizedBox(width: 8),
                  Text('ENTER BATTLE',
                      style: AppTypography.displayTitle(
                          color: Colors.black, fontSize: 20)),
                ],
              ),
            ),
          ).animate().scale(delay: 200.ms, duration: 300.ms),
          const SizedBox(height: 20),

          // Quick Action Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Daily Reward',
                  subtitle: 'Claim Free Coins',
                  color: AppColors.fireOrange,
                  onTap: () => _showDailyRewardDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.assignment_rounded,
                  title: 'Quests',
                  subtitle: 'Daily & Story',
                  color: AppColors.arcaneBlue,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QuestsScreen()));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading(fontSize: 13)),
                Text(subtitle, style: AppTypography.caption(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyRewardDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text('Daily Login Reward!',
                  style: AppTypography.heading(
                      fontSize: 18, color: AppColors.gold)),
              const SizedBox(height: 8),
              Text('+500 Gold Coins Added!',
                  style: AppTypography.body(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(playerProvider.notifier).addCoins(500);
                  Navigator.pop(context);
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                child: const Text('Claim 500 Coins',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.midnightPurple,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (idx) => setState(() => _currentNavIndex = idx),
        backgroundColor: AppColors.midnightPurple,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports), label: 'Battle'),
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Cards'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Wizard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome), label: 'Spells'),
          BottomNavigationBarItem(
              icon: Icon(Icons.backpack), label: 'Inventory'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
        ],
      ),
    );
  }
}
