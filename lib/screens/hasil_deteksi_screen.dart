import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';
import 'treatment_guide_screen.dart';

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
                          // BACKEND: class DeteksiService (paling bawah file ini)
                          await DeteksiService.instance.simpan(data);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Data ${data.idTanaman} tersimpan'),
                            ),
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
// Helpers warna
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
// MODEL DATA
// ─────────────────────────────────────────────────────────────────────────────

/// Data identitas tanaman + hasil deteksi (dikirim dari UI ke backend).
class IdentitasTanaman {
  final String idTanaman; // contoh: M1-K2-B3
  final int meja;
  final int kolom;
  final int baris;
  final String idDeteksi; // contoh: DET-20261114101239
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

// WIDGET UI SAJA — tidak ada logika database di sini.
// Data keluar lewat onSimpan, data scan lama masuk lewat onCariSebelumnya.

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
  // Ubah jumlah pilihan sesuai kondisi kebun/greenhouse kamu.
  static const int _maxMeja = 10;
  static const int _maxKolom = 10;
  static const int _maxBaris = 10;

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
    _idDeteksi = _generateIdDeteksi(_tanggal);
  }

  String _generateIdDeteksi(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'DET-${t.year}${two(t.month)}${two(t.day)}'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  bool get _lokasiLengkap => _meja != null && _kolom != null && _baris != null;

  String get _idTanaman =>
      _lokasiLengkap ? 'M$_meja-K$_kolom-B$_baris' : '-';

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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  hint: 'Meja',
                  value: _meja,
                  max: _maxMeja,
                  onChanged: (v) {
                    setState(() => _meja = v);
                    _cariSebelumnya();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownField(
                  hint: 'Kolom',
                  value: _kolom,
                  max: _maxKolom,
                  onChanged: (v) {
                    setState(() => _kolom = v);
                    _cariSebelumnya();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownField(
                  hint: 'Baris',
                  value: _baris,
                  max: _maxBaris,
                  onChanged: (v) {
                    setState(() => _baris = v);
                    _cariSebelumnya();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── ID Tanaman (otomatis dari Meja-Kolom-Baris) ────────────────
          const _Label('ID Tanaman'),
          const SizedBox(height: 6),
          _ReadOnlyField(text: _idTanaman, icon: Icons.local_florist_outlined),
          const SizedBox(height: 14),

          // ── ID Deteksi (otomatis) ──────────────────────────────────────
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
          ] else if (_sudahCari && !_gagalPrev) ...[
            const SizedBox(height: 10),
            const Text(
              'Ini scan pertama untuk tanaman ini. Scan berikutnya akan '
              'dibandingkan dengan hasil hari ini.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ── Tombol simpan ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Simpan Data',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu perbandingan: scan terakhir vs hari ini
// ─────────────────────────────────────────────────────────────────────────────
class _Verdict {
  final String label;
  final String detail;
  final Color color;
  final IconData icon;
  const _Verdict(this.label, this.detail, this.color, this.icon);
}

_Verdict _bandingkan(IdentitasTanaman prev, DiseaseResult now) {
  const hijau = Color(0xFF16A34A);
  const oranye = Color(0xFFF59E0B);
  const merah = Color(0xFFEF4444);
  final namaNow = now.displayName;

  if (prev.isSehat && now.isHealthy) {
    return const _Verdict(
      'Tetap sehat',
      'Daun sehat di scan sebelumnya dan masih sehat hari ini.',
      hijau,
      Icons.check_circle_outline,
    );
  }
  if (!prev.isSehat && now.isHealthy) {
    return _Verdict(
      'Membaik',
      '${prev.hasilDeteksi} terdeteksi di scan sebelumnya, '
          'hari ini tidak lagi terdeteksi penyakit.',
      hijau,
      Icons.trending_up,
    );
  }
  if (prev.isSehat && !now.isHealthy) {
    return _Verdict(
      'Memburuk',
      'Sebelumnya sehat, hari ini terdeteksi $namaNow. Segera tangani.',
      merah,
      Icons.warning_amber_rounded,
    );
  }
  if (prev.hasilDeteksi == namaNow) {
    return _Verdict(
      'Belum membaik',
      '$namaNow masih terdeteksi seperti di scan sebelumnya. '
          'Bandingkan langsung luas bercak pada daun.',
      oranye,
      Icons.remove_circle_outline,
    );
  }
  return _Verdict(
    'Jenis penyakit berbeda',
    'Sebelumnya ${prev.hasilDeteksi}, hari ini $namaNow.',
    oranye,
    Icons.swap_horiz,
  );
}

class _PerbandinganCard extends StatelessWidget {
  final IdentitasTanaman prev;
  final DiseaseResult now;
  const _PerbandinganCard({required this.prev, required this.now});

  @override
  Widget build(BuildContext context) {
    final v = _bandingkan(prev, now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: v.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perbandingan dengan scan sebelumnya',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _KolomScan(
                  judul: 'Terakhir',
                  tanggal: _fmtRelatif(prev.tanggal),
                  hasil: prev.hasilDeteksi,
                  keyakinan: prev.keyakinan,
                  sehat: prev.isSehat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KolomScan(
                  judul: 'Hari ini',
                  tanggal: 'Sekarang',
                  hasil: now.displayName,
                  keyakinan: now.confidence.toDouble(),
                  sehat: now.isHealthy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(v.icon, size: 18, color: v.color),
              const SizedBox(width: 6),
              Text(
                v.label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: v.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            v.detail,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keyakinan model bukan tingkat keparahan penyakit. '
            'Cocokkan juga dengan kondisi daun secara langsung.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KolomScan extends StatelessWidget {
  final String judul;
  final String tanggal;
  final String hasil;
  final double keyakinan;
  final bool sehat;

  const _KolomScan({
    required this.judul,
    required this.tanggal,
    required this.hasil,
    required this.keyakinan,
    required this.sehat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            tanggal,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusDot(sehat),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasil,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Keyakinan ${(keyakinan * 100).round()}%',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
Color _statusDot(bool sehat) =>
    sehat ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

/// Contoh: 14 November 2026 • 10.12
String _fmtTanggal(DateTime d) {
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year} • '
      '${two(d.hour)}.${two(d.minute)}';
}

/// Contoh: "Kemarin", "5 hari lalu", "1 minggu lalu", "2 bulan lalu"
String _fmtRelatif(DateTime d) {
  final now = DateTime.now();
  final hari = DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (hari <= 0) return 'Hari ini';
  if (hari == 1) return 'Kemarin';
  if (hari < 7) return '$hari hari lalu';
  if (hari < 30) return '${hari ~/ 7} minggu lalu';
  return '${hari ~/ 30} bulan lalu';
}

const TextStyle _valueStyle = TextStyle(
  fontFamily: 'Plus Jakarta Sans',
  fontSize: 13.5,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

InputDecoration _fieldDecoration() => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? dotColor;
  const _ReadOnlyField({required this.text, this.icon, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
          ] else if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(text, style: _valueStyle)),
        ],
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
    return InputDecorator(
      decoration: _fieldDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          style: _valueStyle,
          items: [
            for (var i = 1; i <= max; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKEND — simpan & baca riwayat deteksi (SQLite)
// ─────────────────────────────────────────────────────────────────────────────

/// BACKEND: simpan & baca riwayat deteksi (SQLite).
/// UI hanya memanggil method di bawah, tidak tahu soal SQL.
///
/// Butuh package: sqflite dan path (pubspec.yaml).
/// Database-nya berdiri sendiri (deteksi.db), jadi tidak mengganggu
/// database_helper.dart yang sudah ada. Kalau mau digabung, pindahkan
/// isi _open() ke database_helper.dart.
class DeteksiService {
  DeteksiService._();
  static final DeteksiService instance = DeteksiService._();

  static const String _table = 'deteksi';
  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;

    final path = p.join(await getDatabasesPath(), 'deteksi.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id_deteksi    TEXT PRIMARY KEY,
            id_tanaman    TEXT NOT NULL,
            meja          INTEGER NOT NULL,
            kolom         INTEGER NOT NULL,
            baris         INTEGER NOT NULL,
            hasil_deteksi TEXT NOT NULL,
            sehat         INTEGER NOT NULL,
            keyakinan     REAL NOT NULL,
            tanggal       TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_deteksi_tanaman ON $_table (id_tanaman, tanggal)',
        );
      },
    );
    _db = db;
    return db;
  }

  /// Dipanggil saat tombol "Simpan Data" ditekan.
  Future<void> simpan(IdentitasTanaman data) async {
    final db = await _open();
    await db.insert(
      _table,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Scan terakhir untuk satu tanaman (mis. "M1-K2-B3").
  /// [sebelum]: hanya ambil scan yang lebih lama dari waktu ini,
  /// supaya scan hari ini tidak ikut terbaca sebagai "sebelumnya".
  Future<IdentitasTanaman?> deteksiTerakhir(
    String idTanaman, {
    DateTime? sebelum,
  }) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: sebelum == null
          ? 'id_tanaman = ?'
          : 'id_tanaman = ? AND tanggal < ?',
      whereArgs: sebelum == null
          ? [idTanaman]
          : [idTanaman, sebelum.toIso8601String()],
      orderBy: 'tanggal DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return IdentitasTanaman.fromMap(rows.first);
  }

  /// Semua riwayat (opsional difilter per tanaman), terbaru dulu.
  Future<List<IdentitasTanaman>> riwayat({String? idTanaman}) async {
    final db = await _open();
    final rows = await db.query(
      _table,
      where: idTanaman == null ? null : 'id_tanaman = ?',
      whereArgs: idTanaman == null ? null : [idTanaman],
      orderBy: 'tanggal DESC',
    );
    return rows.map(IdentitasTanaman.fromMap).toList();
  }
}