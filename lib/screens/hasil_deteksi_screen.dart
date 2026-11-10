import 'dart:io';

import 'package:flutter/material.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';
import 'treatment_guide_screen.dart';

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
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Judul + badge tingkat keyakinan
          Row(
            children: [
              Expanded(
                child: Text(
                  'Keyakinan model',
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
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TreatmentGuideScreen(result: result),
          ),
        ),
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

// (TreatmentGuideScreen dipindah ke treatment_guide_screen.dart)

class _Unused {
  final String title;
  final String description;
  final List<String> checklistItems;
  final String? tip;
  final IconData icon;

  const _TreatmentStep({
    required this.title,
    required this.description,
    required this.checklistItems,
    this.tip,
    required this.icon,
  });
}

/// Data model rekomendasi obat
class _MedicineRec {
  final String name;
  final String type; // mis. "Kimia" / "Alami" / "Alert"
  final String dosage;
  final String caution;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MedicineRec({
    required this.name,
    required this.type,
    required this.dosage,
    required this.caution,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

/// Data model langkah pasca-perawatan
class _AfterCareStep {
  final String label;
  final String desc;
  final Color color;

  const _AfterCareStep({
    required this.label,
    required this.desc,
    required this.color,
  });
}

/// Layar penuh panduan pengobatan
class TreatmentGuideScreen extends StatelessWidget {
  final DiseaseResult result;
  const TreatmentGuideScreen({super.key, required this.result});

  // ── data per penyakit ────────────────────────────────────────────────────

  List<String> get _prepItems {
    switch (result.label) {
      case DiseaseLabel.anthracnose:
        return [
          'Gunting steril',
          'Alkohol 70%',
          'Sarung plastik',
          'Fungisida tembaga',
        ];
      case DiseaseLabel.leafWithering:
        return [
          'Gunting steril',
          'Media tanam baru',
          'Pot dengan drainase',
          'Pupuk NPK seimbang',
        ];
      case DiseaseLabel.healthy:
        return ['Peralatan perawatan rutin', 'Pupuk pertumbuhan'];
    }
  }

  List<_TreatmentStep> get _steps {
    switch (result.label) {
      case DiseaseLabel.anthracnose:
        return const [
          _TreatmentStep(
            icon: Icons.location_off_outlined,
            title: 'Isolasi tanaman segera',
            description:
                'Pindahkan tanaman yang terinfeksi jauh dari tanaman lain untuk mencegah penyebaran spora melalui air atau angin.',
            checklistItems: [
              'Jauhkan minimal 1 meter dari tanaman sehat',
              'Hindari percikan air saat menyiram',
              'Jangan berbagi alat tanam sebelum disterilkan',
            ],
            tip:
                'Tips: Taruh tanaman di luar ruangan dengan sirkulasi udara baik selama isolasi',
          ),
          _TreatmentStep(
            icon: Icons.content_cut_outlined,
            title: 'Bersih / pangkas bagian terinfeksi',
            description:
                'Pangkas semua daun yang menunjukkan bercak hitam atau coklat menggunakan gunting yang telah dicelup alkohol.',
            checklistItems: [
              'Sterilkan gunting dengan alkohol 70% tiap potongan',
              'Potong 2–3 cm di bawah area yang terlihat sakit',
              'Bakar atau masukkan potongan ke kantong plastik tertutup',
              'Jangan kompos daun yang terinfeksi',
            ],
            tip:
                'Perhatian: Jika lebih dari 70% daun terinfeksi, pertimbangkan mengganti tanaman',
          ),
          _TreatmentStep(
            icon: Icons.science_outlined,
            title: 'Oleskan bakterisida / buluh karis',
            description:
                'Aplikasikan fungisida berbahan tembaga ke seluruh permukaan daun dan batang. Lakukan pada pagi hari agar cepat kering.',
            checklistItems: [
              'Semprotkan fungisida tembaga atau mankozeb',
              'Campurkan sesuai dosis label — jangan berlebihan',
              'Ulangi setiap 7–10 hari selama 3–4 minggu',
            ],
            tip:
                'Tips: Lakukan penyemprotan 2 jam sebelum hujan atau dalam ruangan ber-AC',
          ),
          _TreatmentStep(
            icon: Icons.water_drop_outlined,
            title: 'Identifikasi penyiraman & ganti media',
            description:
                'Kurangi kelembapan berlebih — Anthracnose berkembang di kondisi lembap. Pastikan media tanam memiliki drainase baik.',
            checklistItems: [
              'Sirami langsung ke media, bukan dari atas daun',
              'Biarkan media mengering sebelum penyiraman berikutnya',
              'Pastikan pot memiliki lubang drainase',
              'Ganti media tanam jika sudah terlalu padat',
            ],
          ),
        ];
      case DiseaseLabel.leafWithering:
        return const [
          _TreatmentStep(
            icon: Icons.search_outlined,
            title: 'Periksa kondisi akar',
            description:
                'Keluarkan tanaman dari pot dan periksa akar. Akar yang sehat berwarna putih atau krem; akar busuk berwarna coklat gelap dan berbau.',
            checklistItems: [
              'Keluarkan tanaman dengan hati-hati dari pot',
              'Basuh akar dengan air bersih',
              'Identifikasi akar yang berwarna coklat gelap / berlendir',
              'Potong akar busuk dengan gunting steril',
            ],
            tip:
                'Tips: Biarkan akar mengering 1–2 hari sebelum ditanam ulang',
          ),
          _TreatmentStep(
            icon: Icons.wb_sunny_outlined,
            title: 'Optimalkan cahaya & sirkulasi',
            description:
                'Tempatkan di lokasi dengan cahaya tidak langsung yang cukup. Hindari tempat gelap total atau paparan sinar matahari langsung berlebihan.',
            checklistItems: [
              'Cahaya tidak langsung cerah (bright indirect light)',
              'Hindari paparan AC langsung yang terlalu kuat',
              'Jauhkan dari jendela tanpa tirai di siang hari',
              'Pastikan ruang memiliki sirkulasi udara',
            ],
          ),
          _TreatmentStep(
            icon: Icons.water_outlined,
            title: 'Atur jadwal penyiraman',
            description:
                'Sansevieria sangat rentan terhadap overwatering. Sirami hanya ketika media tanam benar-benar kering.',
            checklistItems: [
              'Siram setiap 2–4 minggu sekali di lingkungan normal',
              'Cek dengan jari — masukkan 5 cm ke media, siram jika kering',
              'Kurangi frekuensi di musim hujan atau ruangan lembap',
              'Gunakan pot dengan lubang drainase yang baik',
            ],
            tip:
                'Perhatian: Overwatering adalah penyebab utama layu pada Sansevieria',
          ),
          _TreatmentStep(
            icon: Icons.grass_outlined,
            title: 'Tanam ulang & pupuk pemulihan',
            description:
                'Gunakan media tanam yang lebih drainable. Tambahkan pupuk pemulihan setelah tanaman mulai stabil.',
            checklistItems: [
              'Campurkan media tanam kaktus + perlite (50:50)',
              'Hindari media yang terlalu lembap atau berbahan gambut tinggi',
              'Berikan pupuk NPK seimbang setelah 2–3 minggu',
              'Jangan pupuk tanaman yang masih stres',
            ],
          ),
        ];
      case DiseaseLabel.healthy:
        return const [
          _TreatmentStep(
            icon: Icons.check_circle_outline,
            title: 'Pertahankan kondisi saat ini',
            description: 'Tanaman dalam kondisi sehat. Lanjutkan rutinitas perawatan yang sudah baik.',
            checklistItems: [
              'Siram sesuai jadwal rutin',
              'Pastikan cahaya cukup',
              'Pantau secara berkala',
            ],
          ),
        ];
    }
  }

  List<_MedicineRec> get _medicines {
    switch (result.label) {
      case DiseaseLabel.anthracnose:
        return const [
          _MedicineRec(
            name: 'Bakterisida berbahan tembaga',
            type: 'Kimia',
            dosage:
                'Campurkan: Larutkan sesuai anjuran label (umumnya 1–2 g/liter air)',
            caution:
                'Perhatian: Pakai sarung tangan dan masker saat mengaplikasikan produk ini',
            icon: Icons.science,
            color: Color(0xFF2563EB),
            bgColor: Color(0xFFEFF6FF),
          ),
          _MedicineRec(
            name: 'Bubuk kayumanis',
            type: 'Alami',
            dosage: 'Taburkan: Langsung ke luka bekas potongan daun',
            caution:
                'Tidak berbahaya, namun efektivitas lebih rendah dari fungisida kimia',
            icon: Icons.eco,
            color: Color(0xFFD97706),
            bgColor: Color(0xFFFFFBEB),
          ),
        ];
      case DiseaseLabel.leafWithering:
        return const [
          _MedicineRec(
            name: 'Pupuk NPK seimbang (10-10-10)',
            type: 'Kimia',
            dosage: 'Campurkan: 1/4 dosis normal, berikan setiap 2 bulan sekali',
            caution:
                'Perhatian: Jangan berikan pupuk saat tanaman masih dalam kondisi stres berat',
            icon: Icons.grass,
            color: Color(0xFF16A34A),
            bgColor: Color(0xFFDCFCE7),
          ),
          _MedicineRec(
            name: 'Hormon perangsang akar (Rootone)',
            type: 'Kimia',
            dosage: 'Oleskan: Ke ujung akar setelah dipangkas sebelum tanam ulang',
            caution:
                'Gunakan secukupnya, kelebihan hormon dapat justru menghambat pertumbuhan',
            icon: Icons.spa,
            color: Color(0xFF7C3AED),
            bgColor: Color(0xFFF5F3FF),
          ),
        ];
      case DiseaseLabel.healthy:
        return const [
          _MedicineRec(
            name: 'Pupuk pertumbuhan rutin',
            type: 'Alami',
            dosage: 'Berikan setiap 2–3 bulan sekali selama musim tumbuh',
            caution: 'Tidak diperlukan perawatan khusus',
            icon: Icons.eco,
            color: Color(0xFF16A34A),
            bgColor: Color(0xFFDCFCE7),
          ),
        ];
    }
  }

  List<_AfterCareStep> get _afterCare {
    switch (result.label) {
      case DiseaseLabel.anthracnose:
        return const [
          _AfterCareStep(
            label: 'Hari 3–7',
            desc: 'Cek kondisi daun',
            color: Color(0xFF16A34A),
          ),
          _AfterCareStep(
            label: 'Hari 8 & 15',
            desc: 'Aplikasikan fungisida',
            color: Color(0xFF2563EB),
          ),
          _AfterCareStep(
            label: 'Evaluasi akhir',
            desc: 'Nilai pemulihan daun',
            color: Color(0xFF7C3AED),
          ),
        ];
      case DiseaseLabel.leafWithering:
        return const [
          _AfterCareStep(
            label: 'Hari 1–2',
            desc: 'Keringkan akar dipangkas',
            color: Color(0xFF16A34A),
          ),
          _AfterCareStep(
            label: 'Hari 7–14',
            desc: 'Pantau pertumbuhan baru',
            color: Color(0xFF2563EB),
          ),
          _AfterCareStep(
            label: 'Evaluasi akhir',
            desc: 'Nilai kondisi keseluruhan',
            color: Color(0xFF7C3AED),
          ),
        ];
      case DiseaseLabel.healthy:
        return const [
          _AfterCareStep(
            label: 'Bulanan',
            desc: 'Periksa kondisi rutin',
            color: Color(0xFF16A34A),
          ),
        ];
    }
  }

  String get _urgencyNote {
    switch (result.label) {
      case DiseaseLabel.anthracnose:
        return 'Ojol penyelamatan: stek daun sehat\n\nJika lebih dari 60–70% tanaman sudah terinfeksi parah, pertimbangkan menyelamatkan bagian sehat dengan cara stek. Potong daun sehat, biarkan mengering, lalu tanam di media baru yang steril.';
      case DiseaseLabel.leafWithering:
        return 'Ojol penyelamatan: pisahkan anakan\n\nJika tanaman induk terlalu parah, pisahkan anakan (pup) yang masih sehat dari induknya. Tanam anakan di pot baru dengan media segar untuk memastikan kelangsungan hidup tanaman.';
      case DiseaseLabel.healthy:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _GuideTopBar(result: result),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Siapkan Dulu ────────────────────────────────────────
                    _PrepSection(items: _prepItems),
                    const SizedBox(height: 16),

                    // ── Langkah-langkah ──────────────────────────────────────
                    for (var i = 0; i < _steps.length; i++) ...[
                      _StepCard(step: i + 1, data: _steps[i]),
                      const SizedBox(height: 12),
                    ],

                    // ── Rekomendasi Obat ─────────────────────────────────────
                    _MedicineSection(medicines: _medicines),
                    const SizedBox(height: 12),

                    // ── Langkah pasca-perawatan ──────────────────────────────
                    _AfterCareSection(steps: _afterCare),
                    const SizedBox(height: 12),

                    // ── Ojol penyelamatan (hanya jika sakit) ─────────────────
                    if (!result.isHealthy && _urgencyNote.isNotEmpty)
                      _UrgencyCard(note: _urgencyNote),

                    const SizedBox(height: 8),

                    // ── Low confidence warning ───────────────────────────────
                    if (result.confidenceLevel == ConfidenceLevel.low)
                      _LowConfidenceWarning(result: result),
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
class _GuideTopBar extends StatelessWidget {
  final DiseaseResult result;
  const _GuideTopBar({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'Protokol Penyelamatan Daun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Tab baris "Penyakit | Semua" + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                // Tab aktif
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.displayName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tab non-aktif
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Semua',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                // Filter chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.tune, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Tingkat + relaksi',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
// Siapkan Dulu Section
// ─────────────────────────────────────────────────────────────────────────────
class _PrepSection extends StatelessWidget {
  final List<String> items;
  const _PrepSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _guideCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siapkan dulu',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => _PrepChip(label: item))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PrepChip extends StatelessWidget {
  final String label;
  const _PrepChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Card
// ─────────────────────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int step;
  final _TreatmentStep data;
  const _StepCard({required this.step, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _guideCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header langkah ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor bulat
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Ikon + judul
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon,
                      size: 18, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Deskripsi ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              data.description,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ── Checklist ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: data.checklistItems
                  .map((item) => _ChecklistRow(text: item))
                  .toList(),
            ),
          ),

          // ── Tips / Perhatian ─────────────────────────────────────────────
          if (data.tip != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _TipBox(text: data.tip!),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String text;
  const _ChecklistRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  const _TipBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final isWarning = text.toLowerCase().startsWith('perhatian');
    final bgColor =
        isWarning ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF);
    final borderColor =
        isWarning ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE);
    final textColor =
        isWarning ? const Color(0xFF92400E) : const Color(0xFF1D4ED8);
    final icon = isWarning ? Icons.warning_amber_rounded : Icons.lightbulb_outline;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rekomendasi Obat & Formula Section
// ─────────────────────────────────────────────────────────────────────────────
class _MedicineSection extends StatelessWidget {
  final List<_MedicineRec> medicines;
  const _MedicineSection({required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _guideCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: const [
                Icon(Icons.local_pharmacy_outlined,
                    size: 18, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Rekomendasi Obat & Formula',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final med in medicines)
            _MedicineCard(med: med),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final _MedicineRec med;
  const _MedicineCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: med.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: med.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: med.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(med.icon, size: 18, color: med.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: med.color,
                        ),
                      ),
                      Text(
                        med.type,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: med.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.science_outlined, text: med.dosage, color: med.color),
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.info_outline, text: med.caution, color: const Color(0xFF92400E)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Langkah Pasca-Perawatan Section
// ─────────────────────────────────────────────────────────────────────────────
class _AfterCareSection extends StatelessWidget {
  final List<_AfterCareStep> steps;
  const _AfterCareSection({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _guideCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: const [
                Icon(Icons.timeline_outlined,
                    size: 18, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Langkah pasca-perawatan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Expanded(child: _AfterCareChip(step: steps[i])),
                  if (i < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Icon(Icons.chevron_right,
                          size: 18, color: const Color(0xFFD1D5DB)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AfterCareChip extends StatelessWidget {
  final _AfterCareStep step;
  const _AfterCareChip({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: step.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            height: 1.3,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu Ojol / Urgensi
// ─────────────────────────────────────────────────────────────────────────────
class _UrgencyCard extends StatelessWidget {
  final String note;
  const _UrgencyCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final lines = note.split('\n\n');
    final title = lines.isNotEmpty ? lines[0] : note;
    final body = lines.length > 1 ? lines[1] : '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emergency_outlined,
                    size: 18, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Low Confidence Warning
// ─────────────────────────────────────────────────────────────────────────────
class _LowConfidenceWarning extends StatelessWidget {
  final DiseaseResult result;
  const _LowConfidenceWarning({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keyakinan model rendah (${result.confidencePercent}). '
              'Panduan di atas bersifat informatif. Pastikan kondisi daun secara langsung sebelum mengambil tindakan pengobatan.',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _guideCardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );