import 'dart:io';

import 'package:flutter/material.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';

/// Layar hasil deteksi — ditampilkan setelah inferensi selesai.
/// Menampilkan: gambar, nama hasil, keyakinan model, rincian probabilitas,
/// dan tombol panduan.
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
                    // Gambar utuh (tanpa crop) + chip status
                    _ResultImage(imageFile: imageFile, result: result),
                    const SizedBox(height: 16),

                    // Nama hasil + keterangan keyakinan model
                    _DiseaseNameCard(result: result),
                    const SizedBox(height: 16),

                    // Rincian probabilitas semua kelas
                    if (result.scores.isNotEmpty) ...[
                      _ProbabilityCard(result: result),
                      const SizedBox(height: 16),
                    ],

                    // Tombol panduan (hanya muncul jika bukan healthy)
                    if (!result.isHealthy) _TreatmentButton(result: result),

                    if (result.isHealthy) _HealthyBanner(),

                    const SizedBox(height: 14),
                    const _Disclaimer(),
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
// Warna
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(DiseaseResult r) {
  if (r.isHealthy) return const Color(0xFF16A34A);
  if (r.uncertain) return const Color(0xFFF59E0B);
  if (r.isUnrecognized) return const Color(0xFF6B7280);
  return const Color(0xFFEF4444);
}

Color _levelColor(ConfidenceLevel level) {
  switch (level) {
    case ConfidenceLevel.high:
      return const Color(0xFF16A34A);
    case ConfidenceLevel.medium:
      return const Color(0xFFF59E0B);
    case ConfidenceLevel.low:
      return const Color(0xFFEF4444);
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
// Gambar hasil + chip status
// ─────────────────────────────────────────────────────────────────────────────
class _ResultImage extends StatelessWidget {
  final File imageFile;
  final DiseaseResult result;
  const _ResultImage({required this.imageFile, required this.result});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.45;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Gambar utuh, tanpa crop (cacheWidth membatasi memori)
              Image.file(imageFile, fit: BoxFit.contain, cacheWidth: 1200),
              Positioned(
                left: 12,
                top: 12,
                child: _ChipLabel(
                  label: result.chipLabel,
                  color: _statusColor(result),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label chip di atas gambar (mis. "Anthracnose 96%")
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
// Kartu Nama Hasil + Keterangan Keyakinan Model
// ─────────────────────────────────────────────────────────────────────────────
class _DiseaseNameCard extends StatelessWidget {
  final DiseaseResult result;
  const _DiseaseNameCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final level = result.confidenceLevel;
    final levelColor = _levelColor(level);
    final guess = result.topGuess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.displayName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (result.uncertain) ...[
            const SizedBox(height: 6),
            const Text(
              'Foto kurang jelas atau model belum yakin. Coba ambil ulang lebih dekat dengan cahaya cukup.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Judul + badge tingkat keyakinan
          Row(
            children: [
              Expanded(
                child: Text(
                  result.uncertain
                      ? 'Keyakinan tertinggi model'
                      : 'Keyakinan model',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.confidenceLevelText,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Persentase besar + bar
          Text(
            result.confidencePercent,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: result.confidence.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: levelColor,
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 10),

          if (result.uncertain && guess != null) ...[
            Text(
              'Dugaan terkuat: ${DiseaseResult.nameOf(guess.label)} '
              '(${(guess.probability * 100).round()}%)',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],

          Text(
            result.confidenceNote,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),

          if (result.isAmbiguous) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hasil hampir seimbang antara '
                      '${DiseaseResult.nameOf(result.scores[0].label)} '
                      '(${(result.scores[0].probability * 100).round()}%) dan '
                      '${DiseaseResult.nameOf(result.scores[1].label)} '
                      '(${(result.scores[1].probability * 100).round()}%). '
                      'Bandingkan dengan kondisi daun yang sebenarnya.',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Rincian Probabilitas Semua Kelas
// ─────────────────────────────────────────────────────────────────────────────
class _ProbabilityCard extends StatelessWidget {
  final DiseaseResult result;
  const _ProbabilityCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian probabilitas',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < result.scores.length; i++)
            _ProbabilityRow(score: result.scores[i], isTop: i == 0),
        ],
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  final ClassScore score;
  final bool isTop;
  const _ProbabilityRow({required this.score, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final color = isTop ? AppColors.primaryGreen : const Color(0xFF9CA3AF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DiseaseResult.nameOf(score.label),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(score.probability * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.probability.clamp(0.0, 1.0).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Catatan kaki
// ─────────────────────────────────────────────────────────────────────────────
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Keyakinan menunjukkan seberapa yakin model terhadap pilihan teratasnya, '
      'bukan kepastian diagnosis. Hasil bisa kurang tepat pada foto dengan '
      'cahaya atau latar yang tidak biasa.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11.5,
        height: 1.5,
        color: AppColors.textSecondary,
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
        child: Text(
          result.isUnrecognized
              ? 'Lihat Tips Foto yang Baik'
              : 'Lihat Panduan Pengobatan &\nPenyelamatan',
          textAlign: TextAlign.center,
          style: const TextStyle(
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
    final guide = result.uncertain
        ? _uncertainGuide
        : <String>[
            if (result.confidenceLevel == ConfidenceLevel.low)
              'Keyakinan model rendah (${result.confidencePercent}). Pastikan dulu kondisi daun dengan mengamati langsung atau ulangi foto sebelum mengobati.',
            ..._guideFor(result.label),
          ];
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

  static const List<String> _uncertainGuide = [
    'Model belum yakin dengan foto ini, bukan berarti tanaman bukan Sansevieria.',
    'Ambil foto satu daun dari jarak dekat (sekitar 20–30 cm) dengan bagian bercak di tengah.',
    'Gunakan cahaya alami yang cukup, hindari bayangan dan foto buram.',
    'Usahakan latar tidak terlalu ramai, lalu ulangi pemindaian.',
  ];

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
      case DiseaseLabel.notSansevieria:
        return [
          'Gambar tidak dikenali sebagai daun Sansevieria.',
          'Pastikan kamera diarahkan langsung ke daun tanaman dengan pencahayaan yang cukup.',
          'Hindari latar belakang yang terlalu ramai atau gambar yang buram.',
          'Coba ambil foto ulang dari jarak yang lebih dekat.',
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