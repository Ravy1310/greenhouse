import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class JadwalOtomatisCard extends StatefulWidget {
  const JadwalOtomatisCard({super.key});

  @override
  State<JadwalOtomatisCard> createState() => _JadwalOtomatisCardState();
}

class _JadwalOtomatisCardState extends State<JadwalOtomatisCard> {
  int _selectedFreq = 1; // 0: 1x, 1: 2x, 2: Interval
  bool _jadwal1On = true;
  bool _jadwal2On = true;

  static const List<String> _freqLabels = ['1x / hari', '2x / hari', 'Interval hari'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Expanded(
                child: Text('Jadwal Otomatis Cerdas',
                    style: AppTextStyles.sectionTitle),
              ),
              Switch(
                value: _jadwal1On || _jadwal2On,
                onChanged: (val) =>
                    setState(() => _jadwal1On = _jadwal2On = val),
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.toggleActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.toggleInactive,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Frequency selector
          Row(
            children: List.generate(_freqLabels.length, (index) {
              final selected = _selectedFreq == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFreq = index),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < _freqLabels.length - 1 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryGreen
                            : AppColors.sliderTrack,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _freqLabels[index],
                        style: AppTextStyles.chipLabel.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Schedule item 1
          _buildScheduleRow(
            time: '06:00',
            subtitle: 'Pagi · Setiap hari',
            value: _jadwal1On,
            onChanged: (val) => setState(() => _jadwal1On = val),
          ),
          const Divider(height: 24, color: AppColors.sliderTrack),

          // Schedule item 2
          _buildScheduleRow(
            time: '17:30',
            subtitle: 'Sore · Setiap hari',
            value: _jadwal2On,
            onChanged: (val) => setState(() => _jadwal2On = val),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required String time,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mintGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.schedule,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: AppTextStyles.scheduleTime),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.toggleActive,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.toggleInactive,
        ),
      ],
    );
  }
}
