import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SiramManualCard extends StatefulWidget {
  const SiramManualCard({super.key});

  @override
  State<SiramManualCard> createState() => _SiramManualCardState();
}

class _SiramManualCardState extends State<SiramManualCard> {
  bool _isOn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_outlined,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Siram Manual', style: AppTextStyles.cardTitle),
                SizedBox(height: 2),
                Text('Katup 1 · Siap digunakan',
                    style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: _isOn,
            onChanged: (val) => setState(() => _isOn = val),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.toggleActive,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.toggleInactive,
          ),
        ],
      ),
    );
  }
}
