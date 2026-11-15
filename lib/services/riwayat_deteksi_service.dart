import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/riwayat_deteksi.dart';
import 'database_helper.dart';

/// Penyimpanan lokal riwayat deteksi (SQLite) + foto scan.
/// Data lokal dicadangkan ke Google Drive lewat DriveBackupService.
class RiwayatDeteksiService {
  RiwayatDeteksiService._();
  static final RiwayatDeteksiService instance = RiwayatDeteksiService._();

  static const _tabel = 'riwayat_deteksi';
  bool _siap = false;

  /// Nilainya naik setiap kali data berubah (simpan/hapus/pulihkan).
  /// Layar riwayat mendengarkan ini, jadi otomatis ter-refresh.
  final ValueNotifier<int> berubah = ValueNotifier<int>(0);
  void segarkan() => berubah.value++;

  Future<Database> _db() async {
    final db = await DatabaseHelper.instance.database;
    if (!_siap) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tabel (
          id            INTEGER PRIMARY KEY AUTOINCREMENT,
          kode_deteksi  TEXT NOT NULL DEFAULT '',
          kode_tanaman  TEXT NOT NULL,
          nama_tanaman  TEXT NOT NULL DEFAULT '',
          label         TEXT NOT NULL,
          keyakinan     REAL NOT NULL,
          waktu         INTEGER NOT NULL,
          foto_path     TEXT
        )
      ''');
      final info = await db.rawQuery('PRAGMA table_info($_tabel)');
      if (!info.any((c) => c['name'] == 'kode_deteksi')) {
        await db.execute(
            "ALTER TABLE $_tabel ADD COLUMN kode_deteksi TEXT NOT NULL DEFAULT ''");
      }
      _siap = true;
    }
    return db;
  }

  // ── Foto ──────────────────────────────────────────────────────────────────

  /// Folder foto scan di perangkat.
  Future<Directory> fotoDir() async {
    final dir = Directory(p.join(await getDatabasesPath(), 'foto_scan'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _simpanFoto(String? sumber) async {
    if (sumber == null) return null;
    try {
      final dir = await fotoDir();
      final tujuan =
          p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(sumber).copy(tujuan);
      return tujuan;
    } catch (_) {
      return null;
    }
  }

  Future<void> _hapusFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ── Simpan ────────────────────────────────────────────────────────────────

  /// Dipanggil dari tombol "Simpan Data" di layar hasil scan.
  Future<int> simpan({
    String? kodeDeteksi,
    required String kodeTanaman,
    String namaTanaman = '',
    required String label,
    required double keyakinan,
    String? fotoPath,
  }) async {
    final db = await _db();
    final foto = await _simpanFoto(fotoPath);
    final id = await db.insert(_tabel, {
      'kode_deteksi': kodeDeteksi ?? '',
      'kode_tanaman': kodeTanaman,
      'nama_tanaman': namaTanaman,
      'label': label,
      'keyakinan': keyakinan,
      'waktu': DateTime.now().millisecondsSinceEpoch,
      'foto_path': foto,
    });
    if (kodeDeteksi == null || kodeDeteksi.isEmpty) {
      await db.update(
        _tabel,
        {'kode_deteksi': 'D-${id.toString().padLeft(3, '0')}'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    segarkan();
    return id;
  }

  // ── Baca ──────────────────────────────────────────────────────────────────

  Future<List<RiwayatDeteksi>> getAll() async {
    final db = await _db();
    final rows = await db.query(_tabel, orderBy: 'waktu DESC');
    return rows
        .map((r) => RiwayatDeteksi(
              id: r['id'] as int,
              kodeDeteksi: (r['kode_deteksi'] as String).isEmpty
                  ? 'D-${(r['id'] as int).toString().padLeft(3, '0')}'
                  : r['kode_deteksi'] as String,
              kodeTanaman: r['kode_tanaman'] as String,
              namaTanaman: r['nama_tanaman'] as String,
              label: r['label'] as String,
              keyakinan: (r['keyakinan'] as num).toDouble(),
              waktu: DateTime.fromMillisecondsSinceEpoch(r['waktu'] as int),
              fotoPath: r['foto_path'] as String?,
            ))
        .toList();
  }

  // ── Hapus ─────────────────────────────────────────────────────────────────

  /// Hapus satu riwayat beserta fotonya.
  Future<void> hapus(RiwayatDeteksi r) async {
    final db = await _db();
    await db.delete(_tabel, where: 'id = ?', whereArgs: [r.id]);
    await _hapusFile(r.fotoPath);
    segarkan();
  }

  /// Hapus fotonya saja; data riwayat tetap ada.
  Future<void> hapusFoto(RiwayatDeteksi r) async {
    final db = await _db();
    await db.update(
      _tabel,
      {'foto_path': null},
      where: 'id = ?',
      whereArgs: [r.id],
    );
    await _hapusFile(r.fotoPath);
    segarkan();
  }

  // ── Dipakai DriveBackupService ────────────────────────────────────────────

  /// Semua baris untuk dicadangkan. Foto hanya berupa nama file.
  Future<List<Map<String, Object?>>> eksporBaris() async {
    final db = await _db();
    final rows = await db.query(_tabel, orderBy: 'waktu ASC');
    return rows
        .map((r) => <String, Object?>{
              'kode_deteksi': r['kode_deteksi'],
              'kode_tanaman': r['kode_tanaman'],
              'nama_tanaman': r['nama_tanaman'],
              'label': r['label'],
              'keyakinan': r['keyakinan'],
              'waktu': r['waktu'],
              'foto': r['foto_path'] == null
                  ? null
                  : p.basename(r['foto_path'] as String),
            })
        .toList();
  }

  /// Masukkan satu baris hasil pemulihan. Return false jika sudah ada.
  Future<bool> sisipkan({
    required String kodeDeteksi,
    required String kodeTanaman,
    required String namaTanaman,
    required String label,
    required double keyakinan,
    required int waktuMs,
    String? fotoPath,
  }) async {
    final db = await _db();
    final ada = await db.query(
      _tabel,
      columns: ['id'],
      where: 'kode_deteksi = ? AND waktu = ?',
      whereArgs: [kodeDeteksi, waktuMs],
      limit: 1,
    );
    if (ada.isNotEmpty) return false;
    await db.insert(_tabel, {
      'kode_deteksi': kodeDeteksi,
      'kode_tanaman': kodeTanaman,
      'nama_tanaman': namaTanaman,
      'label': label,
      'keyakinan': keyakinan,
      'waktu': waktuMs,
      'foto_path': fotoPath,
    });
    return true;
  }
}