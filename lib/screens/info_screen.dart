import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _WelcomeHeader(),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _StepGuideSection(),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _FAQSection(),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome header — full-width green banner
// ─────────────────────────────────────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Tinggi tetap agar proporsional seperti desain
      constraints: const BoxConstraints(minHeight: 180),
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: Stack(
        children: [
          // ── Ilustrasi daun dekoratif di pojok kanan ───────────────────
          Positioned(
            right: -10,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/leaf_deco.png',
                width: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const _LeafDecoration(),
              ),
            ),
          ),

          // ── Teks konten ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 140, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Selamat datang di',
                  style: TextStyle(
                    color: AppColors.lightGreen,
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SanseCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Rawat Sansevieria lebih cerdas, dari\ndaun hingga katup.',
                  style: TextStyle(
                    color: AppColors.lightGreen,
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget dekorasi daun dari kode (fallback jika aset tidak ada)
class _LeafDecoration extends StatelessWidget {
  const _LeafDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: CustomPaint(
        painter: _LeafPainter(),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..style = PaintingStyle.fill;

    // Gambar tiga daun sederhana
    for (int i = 0; i < 3; i++) {
      final offsetX = size.width * (0.3 + i * 0.25);
      final offsetY = size.height * (0.15 + i * 0.2);
      final path = Path()
        ..moveTo(offsetX, offsetY + size.height * 0.35)
        ..quadraticBezierTo(
          offsetX - size.width * 0.18,
          offsetY,
          offsetX,
          offsetY - size.height * 0.05,
        )
        ..quadraticBezierTo(
          offsetX + size.width * 0.18,
          offsetY,
          offsetX,
          offsetY + size.height * 0.35,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Step guide — semua step dalam satu kartu putih
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: const [
              _StepItem(
                number: '1',
                title: 'Pindai',
                description: 'Arahkan kamera ke daun yang bermasalah.',
                isLast: false,
              ),
              _StepItem(
                number: '2',
                title: 'Analisis',
                description: 'AI mengenali penyakit dan tingkat keparahan.',
                isLast: false,
              ),
              _StepItem(
                number: '3',
                title: 'Sinkronisasi',
                description: 'Hubungkan sensor dan katup lewat BLE/LoRa.',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isLast;

  const _StepItem({
    required this.number,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nomor lingkaran hijau solid
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
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
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 62,
            endIndent: 16,
            color: AppColors.sliderTrack,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pertanyaan Umum — accordion selalu terbuka setelah di-tap
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
          title: 'Bagaimana cara memindai daun?',
          description:
              'Buka tab Deteksi, arahkan kamera ke daun yang sakit, lalu tekan tombol foto. Hasilnya langsung muncul.',
        ),
        const SizedBox(height: 10),
        const _FAQItem(
          title: 'Bagaimana cara mengatur jadwal siram?',
          description:
              'Buka tab Kontrol, tekan tombol (+) pada Jadwal Otomatis, lalu pilih waktu penyiramannya.',
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sliderTrack, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.cardTitle,
                    ),
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

          // ── Body (terbuka) ───────────────────────────────────────────
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, thickness: 1, color: AppColors.sliderTrack),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                widget.description,
                style: AppTextStyles.cardSubtitle.copyWith(height: 1.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
