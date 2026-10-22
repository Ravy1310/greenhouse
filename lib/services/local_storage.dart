import 'package:shared_preferences/shared_preferences.dart';

/// Service sederhana untuk menyimpan state lokal ke SharedPreferences.
/// Data tetap ada meskipun app ditutup atau handphone tidak terhubung ke laptop.
class LocalStorage {
  LocalStorage._internal();
  static final LocalStorage instance = LocalStorage._internal();

  static const _keySiramManual = 'siram_manual_on';

  // ── Siram Manual ──────────────────────────────────────────────────────────

  /// Ambil status siram manual (default: false)
  Future<bool> getSiramManual() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySiramManual) ?? false;
  }

  /// Simpan status siram manual
  Future<void> setSiramManual(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySiramManual, value);
  }
}
