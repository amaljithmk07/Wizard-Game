import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayTitle(
      {Color color = AppColors.gold, double fontSize = 24}) {
    return GoogleFonts.cinzel(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
    );
  }

  static TextStyle heading(
      {Color color = AppColors.textLight, double fontSize = 18}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
  }

  static TextStyle subHeading(
      {Color color = AppColors.gold, double fontSize = 14}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
  }

  static TextStyle body(
      {Color color = AppColors.textLight, double fontSize = 14}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.35,
    );
  }

  static TextStyle caption(
      {Color color = AppColors.textMuted, double fontSize = 11}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle statLabel(
      {Color color = AppColors.gold, double fontSize = 10}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );
  }
}
