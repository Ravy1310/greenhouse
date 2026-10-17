import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DurasiSemprotCard extends StatefulWidget {
  const DurasiSemprotCard({super.key});

  @override
  State<DurasiSemprotCard> createState() => _DurasiSemprotCardState();
}

class _DurasiSemprotCardState extends State<DurasiSemprotCard> {
  double _durasi = 12; // seconds, range 5–30
  static const double _minDurasi = 5;
  static const double _maxDurasi = 30;

  // Approximate ml: 5ml per second
  int get _ml => (_durasi * 5).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Expanded(
                child: Text('Durasi Semprot Katup',
                    style: AppTextStyles.cardTitle),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_durasi.round()} dtk ≈ $_ml ml',
                  style: AppTextStyles.durationBadge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryGreen,
              inactiveTrackColor: AppColors.sliderTrack,
              thumbColor: AppColors.primaryGreen,
              overlayColor: AppColors.primaryGreen.withValues(alpha: 0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 4,
            ),
            child: Slider(
              value: _durasi,
              min: _minDurasi,
              max: _maxDurasi,
              divisions: 25,
              onChanged: (val) => setState(() => _durasi = val),
            ),
          ),

          // Min / Max labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5 dtk', style: AppTextStyles.cardSubtitle),
                Text('30 dtk', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
