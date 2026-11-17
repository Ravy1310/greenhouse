import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';
import 'treatment_guide_screen.dart';
import '../services/riwayat_deteksi_service.dart';
import '../services/drive_backup_service.dart';

Future<void> _cadangOtomatis() async {
  try {
    final d = DriveBackupService.instance;
    if (d.email == null) await d.masukSenyap();
    if (d.email != null) await d.cadangkan();
  } catch (_) {
    // Gagal cadangan tidak boleh mengganggu proses simpan
  }
}

/// Layar hasil deteksi — ditampilkan setelah inferensi selesai.
/// Menampilkan: gambar, nama hasil, keyakinan model, rincian probabilitas,
/// form identitas tanaman, dan tombol panduan.
///
/// SATU FILE berisi: layar hasil, form identitas, model data, dan backend.
/// Bagian BACKEND ada di paling bawah file (class DeteksiService).
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

                    // Form identitas tanaman
                    IdentitasTanamanForm(
                      result: result,
                      onCariSebelumnya: (idTanaman, sebelum) =>
                          DeteksiService.instance
                              .deteksiTerakhir(idTanaman, sebelum: sebelum),
                      onSimpan: (data) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          // 1) Simpan ke riwayat (dibaca layar Riwayat Deteksi)
                          await RiwayatDeteksiService.instance.simpan(
                            kodeDeteksi: data.idDeteksi,
                            kodeTanaman: data.idTanaman,
                            namaTanaman:
                                'Meja ${data.meja}, Kolom ${data.kolom}, Baris ${data.baris}',
                            label: data.hasilDeteksi,
                            keyakinan: data.keyakinan,
                            fotoPath: imageFile.path,
                          );

                          // 2) Tetap simpan ke DeteksiService agar fitur
                          //    "Terakhir di-scan" & perbandingan tetap jalan
                          await DeteksiService.instance.simpan(data);

                          // 3) Cadangkan ke Google Drive (di latar belakang)
                          _cadangOtomatis();

                          messenger.showSnackBar(
                            SnackBar(
                                content: Text('Data ${data.idTanaman} tersimpan')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Gagal menyimpan: $e')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

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
// Helpers warna & dekorasi
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(DiseaseResult r) {
  if (r.isHealthy) return const Color(0xFF16A34A);
  return const Color(0xFFEF4444);
}

Color _statusDot(bool isHealthy) {
  return isHealthy ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
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

          const SizedBox(width: 48),
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
              const Expanded(
                child: Text(
                  'Keyakinan model',
                  style: TextStyle(
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
      child: const Row(
        children: [
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
// MODEL DATA
// ─────────────────────────────────────────────────────────────────────────────

/// Data identitas tanaman + hasil deteksi (dikirim dari UI ke backend).
class IdentitasTanaman {
  final String idTanaman; // contoh: M2-K3-B4
  final int meja;
  final int kolom;
  final int baris;
  final String idDeteksi; // contoh: 001, 002, dst.
  final String hasilDeteksi; // contoh: Anthracnose / Sehat
  final bool isSehat;
  final double keyakinan; // 0.0 - 1.0 (keyakinan model)
  final DateTime tanggal; // waktu scan

  const IdentitasTanaman({
    required this.idTanaman,
    required this.meja,
    required this.kolom,
    required this.baris,
    required this.idDeteksi,
    required this.hasilDeteksi,
    required this.isSehat,
    required this.keyakinan,
    required this.tanggal,
  });

  Map<String, dynamic> toMap() => {
        'id_tanaman': idTanaman,
        'meja': meja,
        'kolom': kolom,
        'baris': baris,
        'id_deteksi': idDeteksi,
        'hasil_deteksi': hasilDeteksi,
        'sehat': isSehat ? 1 : 0,
        'keyakinan': keyakinan,
        'tanggal': tanggal.toIso8601String(),
      };

  factory IdentitasTanaman.fromMap(Map<String, dynamic> m) => IdentitasTanaman(
        idTanaman: m['id_tanaman'] as String,
        meja: m['meja'] as int,
        kolom: m['kolom'] as int,
        baris: m['baris'] as int,
        idDeteksi: m['id_deteksi'] as String,
        hasilDeteksi: m['hasil_deteksi'] as String,
        isSehat: (m['sehat'] as int) == 1,
        keyakinan: (m['keyakinan'] as num).toDouble(),
        tanggal: DateTime.parse(m['tanggal'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM IDENTITAS TANAMAN + PERBANDINGAN SCAN (UI)
// ─────────────────────────────────────────────────────────────────────────────



/// Mencari scan terakhir sebelum [sebelum] untuk tanaman [idTanaman].
typedef CariScanSebelumnya = Future<IdentitasTanaman?> Function(
  String idTanaman,
  DateTime sebelum,
);

/// Form identitas tanaman: lokasi (Meja, Kolom, Baris), ID, hasil deteksi,
/// waktu scan, dan perbandingan dengan scan terakhir tanaman yang sama.
class IdentitasTanamanForm extends StatefulWidget {
  final DiseaseResult result;
  final void Function(IdentitasTanaman data) onSimpan;
  final CariScanSebelumnya onCariSebelumnya;

  const IdentitasTanamanForm({
    super.key,
    required this.result,
    required this.onSimpan,
    required this.onCariSebelumnya,
  });

  @override
  State<IdentitasTanamanForm> createState() => _IdentitasTanamanFormState();
}

class _IdentitasTanamanFormState extends State<IdentitasTanamanForm> {
  // Meja sampai 5, Kolom & Baris sampai 35.
  static const int _maxMeja = 5;
  static const int _maxKolom = 35;
  static const int _maxBaris = 35;

  int? _meja;
  int? _kolom;
  int? _baris;
  late final DateTime _tanggal; // waktu scan hari ini (otomatis)
  late final String _idDeteksi;

  // Data scan sebelumnya untuk tanaman yang dipilih
  IdentitasTanaman? _prev;
  bool _loadingPrev = false;
  bool _gagalPrev = false;
  bool _sudahCari = false;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now();
    // ID Deteksi dibuat sederhana dengan nomor urut acak/waktu singkat 3 digit (mis: 001)
    _idDeteksi = _generateIdDeteksiRingkas();
  }

  // Menghasilkan ID Deteksi ringkas 3 digit (contoh: 001, 045, 128)
  String _generateIdDeteksiRingkas() {
    final now = DateTime.now();
    // Menggunakan kombinasi detik dan milidetik agar unik namun pendek (3 digit terakhir)
    int angkaUnik = (now.second * 1000 + now.millisecond) % 900 + 100;
    return angkaUnik.toString().padLeft(3, '0');
  }

  bool get _lokasiLengkap => _meja != null && _kolom != null && _baris != null;

  /// ID Tanaman dengan format M2-K3-B4
  String get _idTanaman {
    if (!_lokasiLengkap) return '-';
    return 'M$_meja-K$_kolom-B$_baris';
  }

  /// Cari scan terakhir tanaman ini setiap kali lokasi berubah.
  Future<void> _cariSebelumnya() async {
    if (!_lokasiLengkap) {
      setState(() {
        _prev = null;
        _loadingPrev = false;
        _gagalPrev = false;
        _sudahCari = false;
        _lastQuery = null;
      });
      return;
    }

    final id = _idTanaman;
    _lastQuery = id;
    setState(() {
      _prev = null;
      _loadingPrev = true;
      _gagalPrev = false;
      _sudahCari = false;
    });

    IdentitasTanaman? hasil;
    var gagal = false;
    try {
      hasil = await widget.onCariSebelumnya(id, _tanggal);
    } catch (e) {
      debugPrint('[Form] gagal cari scan sebelumnya: $e');
      gagal = true;
    }

    // Abaikan jawaban lama kalau lokasi sudah diganti lagi
    if (!mounted || _lastQuery != id) return;
    setState(() {
      _prev = hasil;
      _loadingPrev = false;
      _gagalPrev = gagal;
      _sudahCari = true;
    });
  }

  String get _teksTerakhir {
    if (!_lokasiLengkap) return 'Pilih lokasi tanaman dulu';
    if (_loadingPrev) return 'Mencari data scan sebelumnya...';
    if (_gagalPrev) return 'Gagal memuat data scan sebelumnya';
    final scanLama = _prev;
    if (scanLama == null) return 'Belum pernah di-scan';
    return '${_fmtRelatif(scanLama.tanggal)} (${_fmtTanggal(scanLama.tanggal)})';
  }

  void _simpan() {
    if (!_lokasiLengkap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi Meja, Kolom, dan Baris dulu.')),
      );
      return;
    }
    widget.onSimpan(
      IdentitasTanaman(
        idTanaman: _idTanaman,
        meja: _meja!,
        kolom: _kolom!,
        baris: _baris!,
        idDeteksi: _idDeteksi,
        hasilDeteksi: widget.result.displayName,
        isSehat: widget.result.isHealthy,
        keyakinan: widget.result.confidence.toDouble(),
        tanggal: _tanggal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prev = _prev;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identitas tanaman',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // ── Lokasi tanaman: Meja, Kolom, Baris ─────────────────────────
          const _Label('Lokasi tanaman'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'Meja',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _DropdownField(
                      hint: 'Pilih',
                      value: _meja,
                      max: _maxMeja,
                      onChanged: (v) {
                        setState(() => _meja = v);
                        _cariSebelumnya();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'Kolom',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _DropdownField(
                      hint: 'Pilih',
                      value: _kolom,
                      max: _maxKolom,
                      onChanged: (v) {
                        setState(() => _kolom = v);
                        _cariSebelumnya();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'Baris',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _DropdownField(
                      hint: 'Pilih',
                      value: _baris,
                      max: _maxBaris,
                      onChanged: (v) {
                        setState(() => _baris = v);
                        _cariSebelumnya();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── ID Tanaman (format M2-K3-B4) ───────────────────────────────
          const _Label('ID Tanaman'),
          const SizedBox(height: 6),
          _ReadOnlyField(text: _idTanaman, icon: Icons.local_florist_outlined),
          const SizedBox(height: 14),

          // ── ID Deteksi (format ringkas 001) ────────────────────────────
          const _Label('ID Deteksi'),
          const SizedBox(height: 6),
          _ReadOnlyField(text: _idDeteksi, icon: Icons.tag),
          const SizedBox(height: 14),

          // ── Hasil Deteksi (dari model) ─────────────────────────────────
          const _Label('Hasil Deteksi'),
          const SizedBox(height: 6),
          _ReadOnlyField(
            text: widget.result.displayName,
            dotColor: _statusDot(widget.result.isHealthy),
          ),
          const SizedBox(height: 14),

          // ── Waktu scan hari ini (otomatis) ─────────────────────────────
          const _Label('Scan hari ini'),
          const SizedBox(height: 6),
          _ReadOnlyField(
            text: _fmtTanggal(_tanggal),
            icon: Icons.event_available_outlined,
          ),
          const SizedBox(height: 14),

          // ── Terakhir di-scan (dari riwayat tanaman yang sama) ──────────
          const _Label('Terakhir di-scan'),
          const SizedBox(height: 6),
          _ReadOnlyField(
            text: _teksTerakhir,
            icon: _loadingPrev ? Icons.hourglass_top : Icons.history,
          ),

          // ── Perbandingan dengan scan sebelumnya ────────────────────────
          if (prev != null) ...[
            const SizedBox(height: 14),
            _PerbandinganCard(prev: prev, now: widget.result),
          ] else if (_sudahCari && !_gagalPrev && _lokasiLengkap) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.new_releases_outlined,
                      size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ini adalah pemindaian pertama untuk tanaman ini.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Tombol Simpan Data (Bisa diklik berkali-kali untuk riwayat baru) ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text(
                'Simpan Data Identitas',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14.5,
 
 
                  fontWeight: FontWeight.w700,
   
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Komponen Kecil Pendukung Form
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final int? value;
  final int max;
  final ValueChanged<int?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 300,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: List.generate(max, (index) {
            final angka = index + 1;
            return DropdownMenuItem<int>(
              value: angka,
              child: Text(
                '$angka',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? dotColor;

  const _ReadOnlyField({
    required this.text,
    this.icon,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerbandinganCard extends StatelessWidget {
  final IdentitasTanaman prev;
  final DiseaseResult now;

  const _PerbandinganCard({required this.prev, required this.now});

  @override
  Widget build(BuildContext context) {
    final prevPct = (prev.keyakinan * 100).round();
    final nowPct = (now.confidence * 100).round();

    String statusPesan;
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!prev.isSehat && now.isHealthy) {
      statusPesan = 'Kondisi membaik! Tanaman pulih menjadi sehat.';
      bgColor = const Color(0xFFDCFCE7);
      borderColor = const Color(0xFF86EFAC);
      textColor = const Color(0xFF166534);
    } else if (prev.isSehat && !now.isHealthy) {
      statusPesan = 'Perhatian: Tanaman sebelumnya sehat, kini terdeteksi penyakit.';
      bgColor = const Color(0xFFFEE2E2);
      borderColor = const Color(0xFFFCA5A5);
      textColor = const Color(0xFF991B1B);
    } else if (prev.hasilDeteksi == now.displayName) {
      statusPesan = 'Hasil sama seperti pemindaian sebelumnya (${prev.hasilDeteksi}).';
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
      textColor = const Color(0xFF1E40AF);
    } else {
      statusPesan =
          'Perubahan deteksi dari ${prev.hasilDeteksi} menjadi ${now.displayName}.';
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perbandingan Scan Sebelumnya',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• Sebelumnya: ${prev.hasilDeteksi} ($prevPct%)\n'
            '• Sekarang: ${now.displayName} ($nowPct%)',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              height: 1.4,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusPesan,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Format Tanggal
// ─────────────────────────────────────────────────────────────────────────────

String _fmtTanggal(DateTime dt) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.day} ${bulan[dt.month - 1]} ${dt.year}, ${two(dt.hour)}:${two(dt.minute)}';
}

String _fmtRelatif(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
  if (diff.inDays < 1) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  return '${diff.inDays} hari lalu';
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKEND SQLITE (DeteksiService)
// ─────────────────────────────────────────────────────────────────────────────

class DeteksiService {
  DeteksiService._();
  static final DeteksiService instance = DeteksiService._();

 
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'identitas_deteksi.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE deteksi_tanaman (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_tanaman TEXT NOT NULL,
            meja INTEGER NOT NULL,
            kolom INTEGER NOT NULL,
            baris INTEGER NOT NULL,
            id_deteksi TEXT NOT NULL,
            hasil_deteksi TEXT NOT NULL,
            sehat INTEGER NOT NULL,
            keyakinan REAL NOT NULL,
            tanggal TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_id_tanaman ON deteksi_tanaman (id_tanaman)',
        );
      },
    );
    return _db!;
  }

  
  Future<void> simpan(IdentitasTanaman data) async {
    final db = await database;
    // Menggunakan insert tanpa conflict conflictAlgorithm replace pada id_tanaman
    // agar data scan baru untuk tanaman yang sama tetap tersimpan sebagai riwayat baru (ganda/berulang).
    await db.insert(
      'deteksi_tanaman',
      data.toMap(),
 
    );
  }


  Future<IdentitasTanaman?> deteksiTerakhir(
    String idTanaman, {
    required DateTime sebelum,
  }) async {
    final db = await database;
    final rows = await db.query(
      'deteksi_tanaman',
      where: 'id_tanaman = ? AND tanggal < ?',
      whereArgs: [idTanaman, sebelum.toIso8601String()],
      orderBy: 'tanggal DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IdentitasTanaman.fromMap(rows.first);
  }
}
