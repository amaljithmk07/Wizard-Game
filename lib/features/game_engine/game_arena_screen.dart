import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../wizard/providers/player_provider.dart';

class EnemyEntity {
  final String id;
  final String name;
  final String symbol;
  double x;
  double y;
  double hp;
  final double maxHp;
  final double damage;
  final double speed;

  EnemyEntity({
    required this.id,
    required this.name,
    required this.symbol,
    required this.x,
    required this.y,
    required this.hp,
    required this.maxHp,
    required this.damage,
    required this.speed,
  });
}

class DamageNumber {
  final String text;
  final double x;
  final double y;
  final Color color;

  DamageNumber(
      {required this.text,
      required this.x,
      required this.y,
      required this.color});
}

class GameArenaScreen extends ConsumerStatefulWidget {
  final String modeTitle;

  const GameArenaScreen({super.key, required this.modeTitle});

  @override
  ConsumerState<GameArenaScreen> createState() => _GameArenaScreenState();
}

class _GameArenaScreenState extends ConsumerState<GameArenaScreen> {
  Timer? _gameTimer;

  // Player State
  double playerX = 180;
  double playerY = 320;
  double playerHp = 120;
  double maxHp = 120;
  double playerMana = 90;
  double maxMana = 90;

  int wave = 1;
  int enemiesKilled = 0;
  int coinsEarned = 0;
  int xpGained = 0;

  List<EnemyEntity> enemies = [];
  List<DamageNumber> damageNumbers = [];

  bool isGameOver = false;
  bool isVictory = false;

  @override
  void initState() {
    super.initState();
    _spawnWave();
    _startGameLoop();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _spawnWave() {
    final rand = Random();
    enemies.clear();
    final count = 3 + wave * 2;

    for (int i = 0; i < count; i++) {
      final isBoss = i == 0 && wave % 3 == 0;
      enemies.add(EnemyEntity(
        id: 'enemy_$i',
        name: isBoss ? 'Ancient Golem Boss' : 'Shadow Minion',
        symbol: isBoss ? '🗿' : (i % 2 == 0 ? '👹' : '💀'),
        x: 40 + rand.nextDouble() * 280,
        y: 60 + rand.nextDouble() * 140,
        hp: isBoss ? 250.0 : 40.0 + wave * 10,
        maxHp: isBoss ? 250.0 : 40.0 + wave * 10,
        damage: isBoss ? 15.0 : 6.0,
        speed: isBoss ? 1.0 : 1.8 + rand.nextDouble(),
      ));
    }
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isGameOver || isVictory) return;

      setState(() {
        // Mana Regeneration
        if (playerMana < maxMana) {
          playerMana = (playerMana + 0.8).clamp(0, maxMana);
        }

        // Enemy AI Movement towards player
        for (final enemy in enemies) {
          final dx = playerX - enemy.x;
          final dy = playerY - enemy.y;
          final dist = sqrt(dx * dx + dy * dy);

          if (dist > 10) {
            enemy.x += (dx / dist) * enemy.speed;
            enemy.y += (dy / dist) * enemy.speed;
          }

          // Enemy attacks player if close
          if (dist < 25) {
            playerHp = (playerHp - enemy.damage * 0.05).clamp(0, maxHp);
            if (playerHp <= 0) {
              isGameOver = true;
            }
          }
        }
      });
    });
  }

  void _castSpell(String name, double damage, double manaCost, Color color) {
    if (playerMana < manaCost || isGameOver) return;

    setState(() {
      playerMana -= manaCost;

      // Find closest enemy
      if (enemies.isNotEmpty) {
        final target = enemies.first;
        target.hp -= damage;

        // Damage Number Floating Text
        damageNumbers.add(DamageNumber(
          text: '-${damage.toInt()}',
          x: target.x,
          y: target.y - 15,
          color: color,
        ));

        // Clear Floating Text after 800ms
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => damageNumbers.clear());
          }
        });

        if (target.hp <= 0) {
          enemies.remove(target);
          enemiesKilled++;
          coinsEarned += 25;
          xpGained += 40;

          ref.read(playerProvider.notifier).addCoins(25);
          ref.read(playerProvider.notifier).addXP(40);
        }
      }

      if (enemies.isEmpty) {
        if (wave >= 5) {
          isVictory = true;
        } else {
          wave++;
          _spawnWave();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Combat Field
            Container(
              color: const Color(0xFF090C15),
              child: Stack(
                children: [
                  // Enemies
                  for (final enemy in enemies)
                    Positioned(
                      left: enemy.x,
                      top: enemy.y,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Enemy Health Bar
                          SizedBox(
                            width: 30,
                            child: LinearProgressIndicator(
                              value: (enemy.hp / enemy.maxHp).clamp(0.0, 1.0),
                              color: Colors.red,
                              backgroundColor: Colors.black,
                            ),
                          ),
                          Text(enemy.symbol,
                              style: const TextStyle(fontSize: 28)),
                        ],
                      ),
                    ),

                  // Floating Damage Text
                  for (final dmg in damageNumbers)
                    Positioned(
                      left: dmg.x,
                      top: dmg.y,
                      child: Text(
                        dmg.text,
                        style: TextStyle(
                            color: dmg.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w900),
                      ),
                    ),

                  // Player Wizard Hero Component
                  Positioned(
                    left: playerX,
                    top: playerY,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🧙‍♂️', style: TextStyle(fontSize: 36)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Status Header (HP, Mana, Wave)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        // HP Bar
                        LinearProgressIndicator(
                          value: (playerHp / maxHp).clamp(0.0, 1.0),
                          color: AppColors.healthRed,
                          backgroundColor: Colors.black54,
                          minHeight: 10,
                        ),
                        const SizedBox(height: 4),
                        // Mana Bar
                        LinearProgressIndicator(
                          value: (playerMana / maxMana).clamp(0.0, 1.0),
                          color: AppColors.manaBlue,
                          backgroundColor: Colors.black54,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Wave $wave',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Bottom Right Action Spell Buttons
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _buildSpellButton(
                          Icons.local_fire_department_rounded,
                          'Fireball',
                          AppColors.fireOrange,
                          () => _castSpell(
                              'Fireball', 45, 15, AppColors.fireOrange)),
                      const SizedBox(width: 10),
                      _buildSpellButton(
                          Icons.ac_unit_rounded,
                          'Ice Spike',
                          AppColors.iceBlue,
                          () => _castSpell(
                              'Ice Spike', 55, 20, AppColors.iceBlue)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSpellButton(
                          Icons.bolt_rounded,
                          'Lightning',
                          AppColors.gold,
                          () =>
                              _castSpell('Lightning', 85, 30, AppColors.gold)),
                      const SizedBox(width: 10),
                      _buildSpellButton(Icons.favorite_rounded, 'Heal Light',
                          const Color(0xFF22C55E), () {
                        if (playerMana >= 25) {
                          setState(() {
                            playerMana -= 25;
                            playerHp = (playerHp + 40).clamp(0, maxHp);
                          });
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Game Over / Victory Overlay
            if (isGameOver || isVictory)
              Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.midnightPurple,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isVictory ? '👑 VICTORY!' : '💀 DEFEAT',
                          style: AppTypography.displayTitle(
                              color: isVictory
                                  ? AppColors.gold
                                  : AppColors.darkMagicRed,
                              fontSize: 24)),
                      const SizedBox(height: 12),
                      Text('Enemies Defeated: $enemiesKilled',
                          style: AppTypography.body()),
                      Text('Coins Earned: +$coinsEarned 💰',
                          style: AppTypography.body(color: AppColors.gold)),
                      Text('XP Gained: +$xpGained ✨',
                          style: AppTypography.body(
                              color: AppColors.crystalViolet)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold),
                        child: Text('Return to Home',
                            style: AppTypography.heading(
                                color: Colors.black, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardDark,
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
