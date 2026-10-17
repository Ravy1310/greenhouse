import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String _fontFamily = 'Plus Jakarta Sans';

  static const TextStyle headerTitle = TextStyle(
    color: AppColors.textWhite,
    fontSize: 15,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headerSubtitle = TextStyle(
    color: AppColors.textMint,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle scheduleTime = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle durationBadge = TextStyle(
    color: AppColors.primaryDeep,
    fontSize: 11,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle humidityValue = TextStyle(
    color: AppColors.primaryGreen,
    fontSize: 26,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle lastWateringTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle hint = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );
}
