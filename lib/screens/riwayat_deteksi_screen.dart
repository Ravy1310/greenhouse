import 'dart:io';

import 'package:flutter/material.dart';

import '../models/riwayat_deteksi.dart';
import '../services/drive_backup_service.dart';
import '../services/riwayat_deteksi_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Konstanta & helper
// ─────────────────────────────────────────────────────────────────────────────
enum _Filter { semua, sehat, sakit }

enum _Status { sehat, sakit, lain }

const _fontFamily = 'Plus Jakarta Sans';
const _hijau = Color(0xFF16A34A);
const _merah = Color(0xFFEF4444);
const _abu = Color(0xFF6B7280);

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

_Status _statusDari(String label) {
  if (label.contains('Healthy') || label.contains('Sehat')) {
    return _Status.sehat;
  }
  if (label.contains('Not_Sansevieria') || label.contains('Bukan')) {
    return _Status.lain;
  }
  return _Status.sakit;
}

Color _warnaStatus(_Status s) {
  switch (s) {
    case _Status.sehat:
      return _hijau;
    case _Status.sakit:
      return _merah;
    case _Status.lain:
      return _abu;
  }
}

IconData _ikonStatus(_Status s) {
  switch (s) {
    case _Status.sehat:
      return Icons.check_circle;
    case _Status.sakit:
      return Icons.warning_rounded;
    case _Status.lain:
      return Icons.help_rounded;
  }
}

String _namaLabel(String label) => label
    .replaceAll('Snake_Plant_', '')
    .replaceAll('Not_Sansevieria', 'Bukan Sansevieria')
    .replaceAll('Healthy', 'Sehat')
    .replaceAll('Anthracnose', 'Antraknosa')
    .replaceAll('Leaf_Withering', 'Layu Daun')
    .replaceAll('_', ' ');

String _dua(int n) => n.toString().padLeft(2, '0');

String _jam(DateTime d) => '${_dua(d.hour)}.${_dua(d.minute)}';

String _tglPanjang(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String _labelHari(DateTime d) {
  final now = DateTime.now();
  final hari = DateTime(now.year, now.month, now.day)
      .difference(DateTime(d.year, d.month, d.day))
      .inDays;
  if (hari <= 0) return 'Hari ini';
  if (hari == 1) return 'Kemarin';
  return _tglPanjang(d);
}

// ─────────────────────────────────────────────────────────────────────────────
// Layar
// ─────────────────────────────────────────────────────────────────────────────
class RiwayatDeteksiScreen extends StatefulWidget {
  const RiwayatDeteksiScreen({super.key});

  @override
  State<RiwayatDeteksiScreen> createState() => _RiwayatDeteksiScreenState();
}

class _RiwayatDeteksiScreenState extends State<RiwayatDeteksiScreen> {
  final _svc = RiwayatDeteksiService.instance;
  final _cari = TextEditingController();

  List<RiwayatDeteksi> _semua = [];
  bool _memuat = true;
  String? _error;
  _Filter _filter = _Filter.semua;
  bool _terbaru = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _svc.berubah.addListener(_muat);
    _muat();
  }

  @override
  void dispose() {
    _svc.berubah.removeListener(_muat);
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final data = await _svc.getAll();
      if (!mounted) return;
      setState(() {
        _semua = data;
        _memuat = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _error = '$e';
      });
    }
  }

  int _hitung(_Status s) =>
      _semua.where((r) => _statusDari(r.label) == s).length;

  List<RiwayatDeteksi> get _tampil {
    Iterable<RiwayatDeteksi> d = _semua;
    if (_filter == _Filter.sehat) {
      d = d.where((r) => _statusDari(r.label) == _Status.sehat);
    } else if (_filter == _Filter.sakit) {
      d = d.where((r) => _statusDari(r.label) == _Status.sakit);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      d = d.where((r) =>
          r.kodeDeteksi.toLowerCase().contains(q) ||
          r.kodeTanaman.toLowerCase().contains(q) ||
          r.namaTanaman.toLowerCase().contains(q) ||
          _namaLabel(r.label).toLowerCase().contains(q));
    }
    final list = d.toList();
    list.sort((a, b) =>
        _terbaru ? b.waktu.compareTo(a.waktu) : a.waktu.compareTo(b.waktu));
    return list;
  }

  /// Sisipkan judul hari di antara kartu.
  List<Object> _susun(List<RiwayatDeteksi> list) {
    final out = <Object>[];
    String? terakhir;
    for (final r in list) {
      final label = _labelHari(r.waktu);
      if (label != terakhir) {
        out.add(label);
        terakhir = label;
      }
      out.add(r);
    }
    return out;
  }

  void _snack(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  // ── Aksi ──────────────────────────────────────────────────────────────────

  Future<bool> _konfirmasi({
    required String judul,
    required String isi,
    required String tombol,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(judul,
            style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(isi,
            style: const TextStyle(
                fontFamily: _fontFamily, fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _merah),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tombol),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _hapusRiwayat(RiwayatDeteksi r) async {
    final ok = await _konfirmasi(
      judul: 'Hapus riwayat ini?',
      isi: '${r.kodeDeteksi} beserta fotonya akan dihapus permanen dari '
          'perangkat.',
      tombol: 'Hapus',
    );
    if (!ok) return;
    await _svc.hapus(r);
    _snack('Riwayat dihapus');
  }

  Future<void> _hapusFoto(RiwayatDeteksi r) async {
    final ok = await _konfirmasi(
      judul: 'Hapus foto ini?',
      isi: 'Foto dihapus, tetapi data deteksinya tetap tersimpan di riwayat.',
      tombol: 'Hapus foto',
    );
    if (!ok) return;
    await _svc.hapusFoto(r);
    _snack('Foto dihapus');
  }

  bool _adaFoto(RiwayatDeteksi r) =>
      r.fotoPath != null && File(r.fotoPath!).existsSync();

  void _foto(RiwayatDeteksi r) {
    final path = r.fotoPath;
    if (path == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _detail(RiwayatDeteksi r) {
    final status = _statusDari(r.label);
    final warna = _warnaStatus(status);
    final ada = _adaFoto(r);
    final persen = (r.keyakinan * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 14, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Foto besar
              GestureDetector(
                onTap: ada
                    ? () {
                        Navigator.pop(ctx);
                        _foto(r);
                      }
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 230,
                    child: ada
                        ? Image.file(File(r.fotoPath!), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.mintGreen,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hide_image_outlined,
                                    size: 40, color: AppColors.textSecondary),
                                SizedBox(height: 6),
                                Text(
                                  'Foto tidak tersedia',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Judul + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.kodeDeteksi,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _Pil(teks: _namaLabel(r.label), warna: warna),
                ],
              ),
              const SizedBox(height: 14),

              _BarisInfo(
                ikon: Icons.local_florist_outlined,
                label: 'ID Tanaman',
                nilai: r.kodeTanaman,
              ),
              if (r.namaTanaman.isNotEmpty)
                _BarisInfo(
                  ikon: Icons.place_outlined,
                  label: 'Lokasi',
                  nilai: r.namaTanaman,
                ),
              _BarisInfo(
                ikon: _ikonStatus(status),
                label: 'Hasil deteksi',
                nilai: _namaLabel(r.label),
                warnaIkon: warna,
              ),
              _BarisInfo(
                ikon: Icons.speed_outlined,
                label: 'Keyakinan model',
                nilai: '$persen%',
              ),
              _BarisInfo(
                ikon: Icons.schedule,
                label: 'Waktu scan',
                nilai: '${_tglPanjang(r.waktu)}, ${_jam(r.waktu)}',
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  if (ada) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _hapusFoto(r);
                        },
                        icon: const Icon(Icons.image_not_supported_outlined,
                            size: 18),
                        label: const Text('Hapus foto'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _merah,
                          side: const BorderSide(color: _merah),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _hapusRiwayat(r);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus riwayat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _merah,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bukaDrive() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _DriveSheet(),
    );
  }

  void _menu(RiwayatDeteksi r, String aksi) {
    switch (aksi) {
      case 'detail':
        _detail(r);
        break;
      case 'foto':
        _hapusFoto(r);
        break;
      case 'hapus':
        _hapusRiwayat(r);
        break;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Deteksi',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cadangan Google Drive',
            icon: const Icon(Icons.cloud_sync_outlined),
            color: AppColors.primaryGreen,
            onPressed: _bukaDrive,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_memuat) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _PesanKosong(
        ikon: Icons.error_outline,
        judul: 'Gagal memuat riwayat',
        isi: _error!,
        aksi: TextButton(onPressed: _muat, child: const Text('Coba lagi')),
      );
    }
    if (_semua.isEmpty) {
      return _PesanKosong(
        ikon: Icons.history,
        judul: 'Belum ada riwayat deteksi',
        isi: 'Scan daun lalu tekan "Simpan Data" agar hasilnya muncul di '
            'sini.',
        aksi: OutlinedButton.icon(
          onPressed: _bukaDrive,
          icon: const Icon(Icons.cloud_download_outlined, size: 18),
          label: const Text('Pulihkan dari Google Drive'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            side: const BorderSide(color: AppColors.primaryGreen),
          ),
        ),
      );
    }

    final tampil = _tampil;
    final item = _susun(tampil);

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: item.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _header(tampil.isEmpty);

          final e = item[i - 1];
          if (e is String) return _JudulHari(teks: e);

          final r = e as RiwayatDeteksi;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey('riwayat-${r.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _konfirmasi(
                judul: 'Hapus riwayat ini?',
                isi: '${r.kodeDeteksi} beserta fotonya akan dihapus '
                    'permanen dari perangkat.',
                tombol: 'Hapus',
              ),
              onDismissed: (_) {
                setState(() => _semua.removeWhere((x) => x.id == r.id));
                _svc.hapus(r);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: _merah,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _RiwayatCard(
                r: r,
                adaFoto: _adaFoto(r),
                onTap: () => _detail(r),
                onFoto: () => _foto(r),
                onMenu: (aksi) => _menu(r, aksi),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header(bool kosong) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RingkasanCard(
          total: _semua.length,
          sehat: _hitung(_Status.sehat),
          sakit: _hitung(_Status.sakit),
          lain: _hitung(_Status.lain),
          onCadangkan: _bukaDrive,
        ),
        const SizedBox(height: 14),

        // Pencarian
        TextField(
          controller: _cari,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontFamily: _fontFamily, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Cari ID tanaman, lokasi, atau hasil...',
            hintStyle: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _cari.clear();
                      setState(() => _query = '');
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter + urutan
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  _chip('Semua', _Filter.semua),
                  _chip('Sehat', _Filter.sehat),
                  _chip('Sakit', _Filter.sakit),
                ],
              ),
            ),
            PopupMenuButton<bool>(
              tooltip: 'Urutkan',
              icon: const Icon(Icons.swap_vert, color: AppColors.textPrimary),
              onSelected: (v) => setState(() => _terbaru = v),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: true,
                  checked: _terbaru,
                  child: const Text('Terbaru dulu'),
                ),
                CheckedPopupMenuItem(
                  value: false,
                  checked: !_terbaru,
                  child: const Text('Terlama dulu'),
                ),
              ],
            ),
          ],
        ),

        if (kosong)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 44, color: AppColors.mutedGreen),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada data yang cocok.',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String teks, _Filter f) {
    final aktif = _filter == f;
    return ChoiceChip(
      label: Text(teks),
      selected: aktif,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = f),
      selectedColor: AppColors.primaryGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: aktif ? AppColors.primaryGreen : const Color(0xFFE5E7EB),
      ),
      labelStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: aktif ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu ringkasan (gradien + bar proporsi)
// ─────────────────────────────────────────────────────────────────────────────
class _RingkasanCard extends StatelessWidget {
  final int total;
  final int sehat;
  final int sakit;
  final int lain;
  final VoidCallback onCadangkan;

  const _RingkasanCard({
    required this.total,
    required this.sehat,
    required this.sakit,
    required this.lain,
    required this.onCadangkan,
  });

  @override
  Widget build(BuildContext context) {
    final gelap = Color.lerp(AppColors.primaryGreen, Colors.black, 0.3)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, gelap],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'scan tersimpan',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onCadangkan,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 15, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Cadangkan',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar proporsi
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (sehat > 0)
                    Expanded(
                      flex: sehat,
                      child: Container(color: const Color(0xFF86EFAC)),
                    ),
                  if (sakit > 0)
                    Expanded(
                      flex: sakit,
                      child: Container(color: const Color(0xFFFCA5A5)),
                    ),
                  if (lain > 0)
                    Expanded(
                      flex: lain,
                      child: Container(color: Colors.white38),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Legenda(warna: const Color(0xFF86EFAC), teks: 'Sehat $sehat'),
              _Legenda(warna: const Color(0xFFFCA5A5), teks: 'Sakit $sakit'),
              if (lain > 0) _Legenda(warna: Colors.white38, teks: 'Lain $lain'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color warna;
  final String teks;
  const _Legenda({required this.warna, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          teks,
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Judul hari
// ─────────────────────────────────────────────────────────────────────────────
class _JudulHari extends StatelessWidget {
  final String teks;
  const _JudulHari({required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
      child: Text(
        teks,
        style: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu riwayat
// ─────────────────────────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  final RiwayatDeteksi r;
  final bool adaFoto;
  final VoidCallback onTap;
  final VoidCallback onFoto;
  final void Function(String aksi) onMenu;

  const _RiwayatCard({
    required this.r,
    required this.adaFoto,
    required this.onTap,
    required this.onFoto,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusDari(r.label);
    final warna = _warnaStatus(status);
    final persen = (r.keyakinan * 100).round();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Garis warna status
                  Container(width: 5, color: warna),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Foto(
                            r: r,
                            adaFoto: adaFoto,
                            status: status,
                            warna: warna,
                            onTap: adaFoto ? onFoto : onTap,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Info(
                              r: r,
                              adaFoto: adaFoto,
                              warna: warna,
                              persen: persen,
                              onMenu: onMenu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  final RiwayatDeteksi r;
  final bool adaFoto;
  final _Status status;
  final Color warna;
  final VoidCallback onTap;

  const _Foto({
    required this.r,
    required this.adaFoto,
    required this.status,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: adaFoto
                    ? Image.file(File(r.fotoPath!),
                        fit: BoxFit.cover, cacheWidth: 280)
                    : Container(
                        color: AppColors.mintGreen,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hide_image_outlined,
                                color: AppColors.textSecondary),
                            SizedBox(height: 4),
                            Text(
                              'Tanpa foto',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(_ikonStatus(status), size: 15, color: warna),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final RiwayatDeteksi r;
  final bool adaFoto;
  final Color warna;
  final int persen;
  final void Function(String aksi) onMenu;

  const _Info({
    required this.r,
    required this.adaFoto,
    required this.warna,
    required this.persen,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                r.kodeDeteksi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 32,
              height: 28,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                onSelected: onMenu,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'detail',
                    child: _ItemMenu(
                        ikon: Icons.info_outline, teks: 'Lihat detail'),
                  ),
                  if (adaFoto)
                    const PopupMenuItem(
                      value: 'foto',
                      child: _ItemMenu(
                        ikon: Icons.image_not_supported_outlined,
                        teks: 'Hapus foto',
                        merah: true,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'hapus',
                    child: _ItemMenu(
                      ikon: Icons.delete_outline,
                      teks: 'Hapus riwayat',
                      merah: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.local_florist_outlined,
                size: 13, color: AppColors.primaryGreen),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                r.kodeTanaman,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (r.namaTanaman.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              r.namaTanaman,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(child: _Pil(teks: _namaLabel(r.label), warna: warna)),
            const Spacer(),
            Text(
              '$persen%',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: warna,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: r.keyakinan.clamp(0.0, 1.0).toDouble(),
            minHeight: 5,
            color: warna,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(Icons.schedule,
                size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Pukul ${_jam(r.waktu)}',
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData ikon;
  final String teks;
  final bool merah;
  const _ItemMenu({required this.ikon, required this.teks, this.merah = false});

  @override
  Widget build(BuildContext context) {
    final warna = merah ? _merah : AppColors.textPrimary;
    return Row(
      children: [
        Icon(ikon, size: 18, color: warna),
        const SizedBox(width: 10),
        Text(
          teks,
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            color: warna,
          ),
        ),
      ],
    );
  }
}

class _Pil extends StatelessWidget {
  final String teks;
  final Color warna;
  const _Pil({required this.teks, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: warna,
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData ikon;
  final String label;
  final String nilai;
  final Color? warnaIkon;

  const _BarisInfo({
    required this.ikon,
    required this.label,
    required this.nilai,
    this.warnaIkon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: warnaIkon ?? AppColors.primaryGreen),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// Tampilan kosong / error
// ─────────────────────────────────────────────────────────────────────────────
class _PesanKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String isi;
  final Widget? aksi;

  const _PesanKosong({
    required this.ikon,
    required this.judul,
    required this.isi,
    this.aksi,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.mintGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(ikon, size: 46, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 18),
            Text(
              judul,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (aksi != null) ...[const SizedBox(height: 14), aksi!],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet: cadangan Google Drive
// ─────────────────────────────────────────────────────────────────────────────
class _DriveSheet extends StatefulWidget {
  const _DriveSheet();

  @override
  State<_DriveSheet> createState() => _DriveSheetState();
}

class _DriveSheetState extends State<_DriveSheet> {
  final _drive = DriveBackupService.instance;

  String? _email;
  bool _sibuk = false;
  String? _pesan;
  bool _pesanError = false;

  @override
  void initState() {
    super.initState();
    _email = _drive.email;
    if (_email == null) _masukSenyap();
  }

  Future<void> _masukSenyap() async {
    try {
      final e = await _drive.masukSenyap();
      if (mounted) setState(() => _email = e);
    } catch (_) {}
  }

  Future<void> _jalankan(Future<String> Function() kerja) async {
    setState(() {
      _sibuk = true;
      _pesan = null;
    });
    try {
      final hasil = await kerja();
      if (!mounted) return;
      setState(() {
        _pesan = hasil;
        _pesanError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pesan = 'Gagal: $e';
        _pesanError = true;
      });
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _masuk() => _jalankan(() async {
        final e = await _drive.masuk();
        if (e == null) return 'Masuk dibatalkan.';
        if (mounted) setState(() => _email = e);
        return 'Berhasil masuk sebagai $e';
      });

  Future<void> _cadangkan() => _jalankan(() async {
        final h = await _drive.cadangkan();
        return 'Cadangan selesai: ${h.total} data, '
            '${h.fotoBaru} foto baru diunggah'
            '${h.fotoDihapus > 0 ? ', ${h.fotoDihapus} foto lama dihapus dari Drive' : ''}.';
      });

  Future<void> _pulihkan() => _jalankan(() async {
        final n = await _drive.pulihkan();
        return n == 0
            ? 'Tidak ada data baru. Semua data Drive sudah ada di perangkat.'
            : '$n data berhasil dipulihkan dari Drive.';
      });

  Future<void> _keluar() async {
    await _drive.keluar();
    if (mounted) {
      setState(() {
        _email = null;
        _pesan = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bawah = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + bawah),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.cloud_sync_outlined,
                  color: AppColors.primaryGreen, size: 22),
              SizedBox(width: 8),
              Text(
                'Cadangan Google Drive',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Data dan foto riwayat disimpan di folder "Greenhouse Backup" '
            'pada Drive-mu. Aplikasi hanya bisa melihat file yang ia buat '
            'sendiri.',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_email == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sibuk ? null : _masuk,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Masuk dengan Google'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined,
                      size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _email!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _sibuk ? null : _keluar,
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sibuk ? null : _cadangkan,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('Cadangkan sekarang'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sibuk ? null : _pulihkan,
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Pulihkan dari Drive'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
          if (_sibuk) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 4),
          ],
          if (_pesan != null) ...[
            const SizedBox(height: 14),
            Text(
              _pesan!,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                height: 1.5,
                color: _pesanError ? _merah : _hijau,
              ),
            ),
          ],
        ],
      ),
    );
  }
}