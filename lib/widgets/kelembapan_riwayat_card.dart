import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KelembapanRiwayatCard extends StatelessWidget {
  const KelembapanRiwayatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Penyiraman terakhir section
            Text('Penyiraman terakhir', style: AppTextStyles.hint),
            SizedBox(height: 4),
            Text('Hari ini, 06:00',
                style: AppTextStyles.lastWateringTitle),
            SizedBox(height: 4),
            Text('12 dtk · 60 ml · Otomatis',
                style: AppTextStyles.hint),
          ],
        ),
      ),
    );
  }
}
