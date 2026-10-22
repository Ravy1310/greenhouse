import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SiramManualCard extends StatefulWidget {
  const SiramManualCard({super.key});

  @override
  State<SiramManualCard> createState() => _SiramManualCardState();
}

class _SiramManualCardState extends State<SiramManualCard> {
  final _storage = LocalStorage.instance;
  bool _isOn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  /// Baca state terakhir dari SharedPreferences saat widget pertama kali dibuat
  Future<void> _loadState() async {
    final saved = await _storage.getSiramManual();
    if (mounted) setState(() { _isOn = saved; _loading = false; });
  }

  /// Simpan perubahan toggle ke SharedPreferences
  Future<void> _onToggle(bool val) async {
    setState(() => _isOn = val);
    await _storage.setSiramManual(val);
  }

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
          // Toggle — disabled saat masih loading agar tidak flicker
          if (_loading)
            const SizedBox(
              width: 48,
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            )
          else
            Switch(
              value: _isOn,
              onChanged: _onToggle,
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
