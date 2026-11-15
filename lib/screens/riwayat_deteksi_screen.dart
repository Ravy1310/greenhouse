import 'dart:io';

import 'package:flutter/material.dart';

import '../models/riwayat_deteksi.dart';
import '../services/drive_backup_service.dart';
import '../services/riwayat_deteksi_service.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────
enum _Filter { semua, sehat, sakit }

enum _Status { sehat, sakit, lain }

const _fontFamily = 'Plus Jakarta Sans';
const _hijau = Color(0xFF16A34A);
const _merah = Color(0xFFEF4444);
const _abu = Color(0xFF6B7280);

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

String _namaLabel(String label) => label
    .replaceAll('Snake_Plant_', '')
    .replaceAll('Not_Sansevieria', 'Bukan Sansevieria')
    .replaceAll('Healthy', 'Sehat')
    .replaceAll('Anthracnose', 'Antraknosa')
    .replaceAll('Leaf_Withering', 'Layu Daun')
    .replaceAll('_', ' ');

String _tgl(DateTime d) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${bulan[d.month - 1]} ${d.year} • '
      '${two(d.hour)}.${two(d.minute)}';
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

  List<RiwayatDeteksi> _semua = [];
  bool _memuat = true;
  String? _error;
  _Filter _filter = _Filter.semua;

  @override
  void initState() {
    super.initState();
    // Otomatis muat ulang tiap ada simpan/hapus/pulihkan
    _svc.berubah.addListener(_muat);
    _muat();
  }

  @override
  void dispose() {
    _svc.berubah.removeListener(_muat);
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

  List<RiwayatDeteksi> get _tampil {
    switch (_filter) {
      case _Filter.semua:
        return _semua;
      case _Filter.sehat:
        return _semua
            .where((r) => _statusDari(r.label) == _Status.sehat)
            .toList();
      case _Filter.sakit:
        return _semua
            .where((r) => _statusDari(r.label) == _Status.sakit)
            .toList();
    }
  }

  void _snack(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<bool> _konfirmasi({
    required String judul,
    required String isi,
    required String tombol,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  void _lihatFoto(RiwayatDeteksi r) {
    final path = r.fotoPath;
    if (path == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Tutup',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _hapusFoto(r);
                    },
                    icon: const Icon(Icons.delete_outline, color: _merah),
                    label: const Text('Hapus foto',
                        style: TextStyle(color: _merah)),
                  ),
                ],
              ),
            ),
          ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _DriveSheet(),
    );
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
      return const _PesanKosong(
        ikon: Icons.history,
        judul: 'Belum ada riwayat deteksi',
        isi: 'Scan daun lalu tekan "Simpan Data" agar hasilnya muncul di '
            'sini. Punya cadangan? Pulihkan lewat ikon awan di kanan atas.',
      );
    }

    final list = _tampil;
    final nSehat =
        _semua.where((r) => _statusDari(r.label) == _Status.sehat).length;
    final nSakit =
        _semua.where((r) => _statusDari(r.label) == _Status.sakit).length;

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: list.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        angka: _semua.length,
                        label: 'Total scan',
                        warna: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          angka: nSehat, label: 'Sehat', warna: _hijau),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          angka: nSakit, label: 'Sakit', warna: _merah),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('Semua', _Filter.semua),
                    _chip('Sehat', _Filter.sehat),
                    _chip('Sakit', _Filter.sakit),
                  ],
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Tidak ada data untuk filter ini.',
                        style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            );
          }

          final r = list[i - 1];
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
                padding: const EdgeInsets.only(right: 22),
                decoration: BoxDecoration(
                  color: _merah,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _RiwayatCard(
                r: r,
                onFoto: () => _lihatFoto(r),
                onHapus: () => _hapusRiwayat(r),
              ),
            ),
          );
        },
      ),
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
// Kartu statistik
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final int angka;
  final String label;
  final Color warna;
  const _StatCard(
      {required this.angka, required this.label, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$angka',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: warna,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu riwayat
// ─────────────────────────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  final RiwayatDeteksi r;
  final VoidCallback onFoto;
  final VoidCallback onHapus;

  const _RiwayatCard({
    required this.r,
    required this.onFoto,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusDari(r.label);
    final warna = _warnaStatus(status);
    final adaFoto = r.fotoPath != null && File(r.fotoPath!).existsSync();
    final persen = (r.keyakinan * 100).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          GestureDetector(
            onTap: adaFoto ? onFoto : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 88,
                height: 88,
                child: adaFoto
                    ? Image.file(File(r.fotoPath!),
                        fit: BoxFit.cover, cacheWidth: 260)
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
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onHapus,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: _merah),
                      ),
                    ),
                  ],
                ),
                Text(
                  r.namaTanaman.isEmpty
                      ? 'Tanaman ${r.kodeTanaman}'
                      : '${r.kodeTanaman} • ${r.namaTanaman}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: warna.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _namaLabel(r.label),
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: warna,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$persen%',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _tgl(r.waktu),
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
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
            Icon(ikon, size: 56, color: AppColors.mutedGreen),
            const SizedBox(height: 14),
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
            if (aksi != null) ...[const SizedBox(height: 8), aksi!],
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

  Future<void> _jalankan(
    Future<String> Function() kerja,
  ) async {
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
          Row(
            children: const [
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