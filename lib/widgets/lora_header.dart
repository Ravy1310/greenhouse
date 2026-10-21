import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoraHeader extends StatelessWidget {
  const LoraHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Wi-Fi icon
          const Icon(Icons.wifi, color: AppColors.lightGreen, size: 20),
          const SizedBox(width: 10),
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('LoRa Hub Terhubung', style: AppTextStyles.headerTitle),
                SizedBox(height: 2),
                Text(
                  'Wi-Fi + LoRa · Sansevieria Teras',
                  style: AppTextStyles.headerSubtitle,
                ),
              ],
            ),
          ),
          // Right text
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('-67 dBm', style: AppTextStyles.headerTitle),
              SizedBox(height: 2),
              Text('RSSI Baik', style: AppTextStyles.headerSubtitle),
            ],
          ),
        ],
      ),
    );
  }
}
