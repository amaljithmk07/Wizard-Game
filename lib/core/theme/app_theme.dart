import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.deepNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.magicPurple,
        secondary: AppColors.gold,
        surface: AppColors.midnightPurple,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.midnightPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
    );
  }
}
