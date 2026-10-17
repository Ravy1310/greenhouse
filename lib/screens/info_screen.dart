import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _WelcomeHeader(),
          SizedBox(height: 24),
          _StepGuideSection(),
          SizedBox(height: 24),
          _FAQSection(),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome header
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: AppColors.lightGreen,
                size: 24,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selamat datang di', style: AppTextStyles.headerSubtitle),
                  Text(
                    'GreenHouse',
                    style: AppTextStyles.headerTitle,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Rawat tanaman lebih cerdas, dari daun hingga katup.',
            style: AppTextStyles.headerSubtitle,
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akurasi AI', style: AppTextStyles.cardSubtitle),
                    Text(
                      '96,4%',
                      style: AppTextStyles.humidityValue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick step guide
// ─────────────────────────────────────────────────────────────────────────────
class _StepGuideSection extends StatelessWidget {
  const _StepGuideSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Panduan Langkah Cepat', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        ..._steps,
      ],
    );
  }

  static const _steps = [
    _StepItem(
      number: '1',
      title: 'Pindai',
      description: 'Arahkan kamera ke daun yang bermasalah.',
    ),
    _StepItem(
      number: '2',
      title: 'Analisis',
      description: 'AI mengenali penyakit dan tingkat keparahan.',
    ),
    _StepItem(
      number: '3',
      title: 'Sinkronisasi',
      description: 'Hubungkan sensor dan katup lewat BLE/LoRa.',
    ),
  ];
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sliderTrack, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  number,
                  style: AppTextStyles.chipLabel.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pertanyaan Umum (FAQ accordion)
// ─────────────────────────────────────────────────────────────────────────────
class _FAQSection extends StatelessWidget {
  const _FAQSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pertanyaan Umum', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        const _FAQItem(
          title: 'Membaca hasil AI Vision',
          description:
              'Hasil deteksi menampilkan tingkat akurasi, tingkat keparahan infeksi, dan area yang terdampak. Perhatikan overlay warna merah/oranye untuk melihat lokasi infeksi.',
        ),
        const SizedBox(height: 10),
        const _FAQItem(
          title: 'Integrasi sensor & LoRa Hub',
          description:
              'Pastikan LoRa Hub aktif dan sinyal baik (RSSI ideal di atas -70 dBm). Sensor mengirim data ke hub, lalu hub mengontrol katup secara otomatis.',
        ),
      ],
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String title;
  final String description;

  const _FAQItem({required this.title, required this.description});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.sliderTrack, width: 1),
      ),
      child: Column(
        children: [
          // ── Header (tappable) ─────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom:
                      _expanded ? Radius.zero : const Radius.circular(14),
                ),
                color: _expanded ? AppColors.mintGreen : Colors.transparent,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.cardTitle),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ──────────────────────────────────────────────
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: const BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  ),
                  Text(
                    widget.description,
                    style: AppTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
