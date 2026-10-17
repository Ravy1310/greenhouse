import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        surface: AppColors.background,
      ),
      useMaterial3: true,
    );
  }
}
