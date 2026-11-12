import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/jadwal_item.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  static const _dbName = 'greenhouse.db';
  static const _dbVersion = 1;
  static const _tableJadwal = 'jadwal';

  // ── Open / create ──────────────────────────────────────────────────────────
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableJadwal (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        hour     INTEGER NOT NULL,
        minute   INTEGER NOT NULL,
        days_csv TEXT    NOT NULL,
        is_on    INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Seed data default
    await db.insert(_tableJadwal, {
      'hour': 6, 'minute': 0, 'days_csv': '0,1,2,3,4,5,6', 'is_on': 1,
    });
    await db.insert(_tableJadwal, {
      'hour': 17, 'minute': 30, 'days_csv': '0,1,2,3,4,5,6', 'is_on': 1,
    });
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  /// Ambil semua jadwal, diurutkan berdasarkan jam
  Future<List<JadwalItem>> getAll() async {
    final db = await database;
    final rows = await db.query(
      _tableJadwal,
      orderBy: 'hour ASC, minute ASC',
    );
    return rows.map(JadwalItem.fromMap).toList();
  }

  /// Tambah jadwal baru, kembalikan item dengan id yang baru di-assign
  Future<JadwalItem> insert(JadwalItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    final id = await db.insert(_tableJadwal, map);
    return item.copyWith(id: id);
  }

  /// Update jadwal yang sudah ada (berdasarkan id)
  Future<void> update(JadwalItem item) async {
    if (item.id == null) {
      debugPrint('[DB] update() dipanggil tanpa id, diabaikan.');
      return;
    }
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    await db.update(
      _tableJadwal,
      map,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Hapus jadwal berdasarkan id
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete(_tableJadwal, where: 'id = ?', whereArgs: [id]);
  }

  /// Tutup koneksi (opsional, dipanggil saat app dispose)
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
