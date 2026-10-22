import 'dart:io';

import 'package:flutter/material.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';

/// Layar hasil deteksi — ditampilkan setelah inferensi selesai.
/// Menampilkan: gambar + bounding-box overlay, nama penyakit, tombol panduan.
class HasilDeteksiScreen extends StatelessWidget {
  final File imageFile;
  final DiseaseResult result;
  final String plantName;

  const HasilDeteksiScreen({
    super.key,
    required this.imageFile,
    required this.result,
    this.plantName = 'Sansevieria',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── App bar ────────────────────────────────────────────────────
            _TopBar(plantName: plantName),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar dengan overlay bounding-box
                    _ImageWithBbox(
                      imageFile: imageFile,
                      result: result,
                    ),
                    const SizedBox(height: 16),

                    // Kartu nama penyakit
                    _DiseaseNameCard(result: result),
                    const SizedBox(height: 16),

                    // Tombol panduan (hanya muncul jika bukan healthy)
                    if (!result.isHealthy)
                      _TreatmentButton(result: result),

                    if (result.isHealthy)
                      _HealthyBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String plantName;
  const _TopBar({required this.plantName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Tombol kembali
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Nama tanaman — tengah
          Expanded(
            child: Text(
              plantName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Tombol share (placeholder)
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gambar + Bounding-Box Overlay
// ─────────────────────────────────────────────────────────────────────────────
class _ImageWithBbox extends StatelessWidget {
  final File imageFile;
  final DiseaseResult result;

  const _ImageWithBbox({required this.imageFile, required this.result});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar hasil foto
            Image.file(imageFile, fit: BoxFit.cover),

            // Overlay gelap tipis agar box lebih kontras
            Container(color: Colors.black.withValues(alpha: 0.08)),

            // Bounding box + chip label
            _BboxOverlay(result: result),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bounding-Box Overlay
// Karena model adalah pure classifier (tidak mengembalikan koordinat),
// box digambar di posisi simbolis — tengah frame, proporsional.
// ─────────────────────────────────────────────────────────────────────────────
class _BboxOverlay extends StatelessWidget {
  final DiseaseResult result;
  const _BboxOverlay({required this.result});

  @override
  Widget build(BuildContext context) {
    // Warna kotak: merah untuk penyakit, hijau untuk sehat
    final boxColor = result.isHealthy
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final chipColor = result.isHealthy
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Box menempati ~40% lebar dan ~45% tinggi, diposisikan di tengah
      const relW = 0.42;
      const relH = 0.48;
      final boxW = w * relW;
      final boxH = h * relH;
      final left = (w - boxW) / 2;
      final top = (h - boxH) / 2 - h * 0.04;

      return Stack(
        children: [
          // ── Kotak deteksi ───────────────────────────────────────────────
          Positioned(
            left: left,
            top: top,
            width: boxW,
            height: boxH,
            child: CustomPaint(
              painter: _BboxPainter(color: boxColor),
            ),
          ),

          // ── Chip label di atas kotak ─────────────────────────────────────
          Positioned(
            left: left,
            top: top - 32,
            child: _ChipLabel(
              label: result.chipLabel,
              color: chipColor,
            ),
          ),
        ],
      );
    });
  }
}

/// Gambar kotak dengan border penuh
class _BboxPainter extends CustomPainter {
  final Color color;
  const _BboxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BboxPainter old) => old.color != color;
}

/// Label chip melayang di atas kotak (mis. "Anthracnose 96%")
class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu Nama Penyakit
// ─────────────────────────────────────────────────────────────────────────────
class _DiseaseNameCard extends StatelessWidget {
  final DiseaseResult result;
  const _DiseaseNameCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        result.displayName,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol Panduan Pengobatan & Penyelamatan
// ─────────────────────────────────────────────────────────────────────────────
class _TreatmentButton extends StatelessWidget {
  final DiseaseResult result;
  const _TreatmentButton({required this.result});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showTreatmentGuide(context, result),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Lihat Panduan Pengobatan &\nPenyelamatan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showTreatmentGuide(BuildContext context, DiseaseResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TreatmentGuideSheet(result: result),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner untuk tanaman sehat
// ─────────────────────────────────────────────────────────────────────────────
class _HealthyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanaman Sehat',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Tidak terdeteksi penyakit. Lanjutkan perawatan rutin.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Color(0xFF166534),
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

// ─────────────────────────────────────────────────────────────────────────────
// Treatment Guide Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _TreatmentGuideSheet extends StatelessWidget {
  final DiseaseResult result;
  const _TreatmentGuideSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final guide = _guideFor(result.label);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.healing_outlined,
                      color: AppColors.primaryGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Panduan: ${result.displayName}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Content
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: guide.length,
                separatorBuilder: (_, idx) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GuideStep(
                  step: i + 1,
                  text: guide[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Panduan pengobatan per label
  static List<String> _guideFor(DiseaseLabel label) {
    switch (label) {
      case DiseaseLabel.anthracnose:
        return [
          'Isolasi tanaman yang terinfeksi dari tanaman lain untuk mencegah penyebaran spora jamur.',
          'Potong dan buang daun yang terinfeksi menggunakan gunting steril. Bakar atau buang jauh dari area tanam.',
          'Semprot seluruh bagian tanaman dengan fungisida berbahan aktif tembaga (copper-based) atau mankozeb setiap 7–10 hari.',
          'Kurangi kelembapan lingkungan — hindari penyiraman dari atas daun. Sirami langsung ke media tanam.',
          'Pastikan sirkulasi udara baik. Jangan menempatkan tanaman terlalu rapat.',
          'Setelah 3–4 minggu perawatan, pantau pertumbuhan daun baru sebagai indikator pemulihan.',
        ];
      case DiseaseLabel.leafWithering:
        return [
          'Periksa kelembapan media tanam — Sansevieria tidak menyukai tanah yang terlalu basah maupun terlalu kering.',
          'Jika akar membusuk (root rot), keluarkan tanaman, potong akar busuk, dan tanam ulang di media yang lebih drainable.',
          'Tempatkan tanaman di lokasi dengan cahaya tidak langsung yang cukup (bright indirect light).',
          'Kurangi frekuensi penyiraman — Sansevieria cukup disiram setiap 2–4 minggu sekali tergantung kondisi lingkungan.',
          'Berikan pupuk seimbang (NPK 10-10-10) setiap 2 bulan sekali selama musim tumbuh untuk mendukung pemulihan.',
          'Hindari suhu ekstrem dan paparan angin kencang langsung.',
        ];
      case DiseaseLabel.healthy:
        return [
          'Tanaman dalam kondisi baik. Pertahankan rutinitas perawatan saat ini.',
        ];
    }
  }
}

class _GuideStep extends StatelessWidget {
  final int step;
  final String text;
  const _GuideStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nomor langkah
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
