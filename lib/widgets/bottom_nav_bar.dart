import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// When true, uses a dark background suitable for the Deteksi screen.
  final bool dark;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = dark ? const Color(0xFF0D2018) : Colors.white;
    final borderColor =
        dark ? Colors.white.withValues(alpha: 0.08) : AppColors.sliderTrack;
    final inactiveColor =
        dark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary;
    final activeColor = dark ? Colors.white : AppColors.primaryGreen;
    final activeBg =
        dark ? Colors.white.withValues(alpha: 0.12) : AppColors.mintGreen;

    Widget item(int index, IconData icon, String label) => Expanded(
          child: _buildNavItem(
            index: index,
            icon: icon,
            label: label,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            activeBg: activeBg,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              item(0, Icons.tune, 'Kontrol'),
              item(1, Icons.crop_free, 'Deteksi'),
              item(2, Icons.history, 'Riwayat Deteksi'),
              item(3, Icons.info_outline, 'Info Aplikasi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required Color inactiveColor,
    required Color activeBg,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: activeBg,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.navLabel.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}