import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;

import 'riwayat_deteksi_service.dart';

/// Cadangkan & pulihkan riwayat deteksi (data + foto) ke Google Drive.
/// Versi untuk google_sign_in 7.x.
///
/// Isi folder "Greenhouse Backup" di Drive:
///   - riwayat_deteksi.json  → seluruh data riwayat
///   - <timestamp>.jpg       → foto scan
class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  // ⚠️ GANTI dengan Client ID dari OAuth client bertipe "Web application"
  // (Google Auth Platform → Clients). Bentuknya:
  // 1234567890-abcdefg.apps.googleusercontent.com
  static const String _serverClientId =
      '242771120101-rkn3975ge22o90j6asaf7f5ejeril36b.apps.googleusercontent.com';

  static const _namaFolder = 'Greenhouse Backup';
  static const _namaJson = 'riwayat_deteksi.json';
  static const List<String> _scopes = [drive.DriveApi.driveFileScope];

  GoogleSignInAccount? _akun;
  Future<void>? _init;

  Future<void> _pastikanInit() => _init ??=
      GoogleSignIn.instance.initialize(serverClientId: _serverClientId);

  /// Email akun yang sedang masuk (null jika belum masuk).
  String? get email => _akun?.email;

  Future<String?> masukSenyap() async {
    await _pastikanInit();
    final proses = GoogleSignIn.instance.attemptLightweightAuthentication();
    _akun = proses == null ? null : await proses;
    return _akun?.email;
  }

  Future<String?> masuk() async {
    await _pastikanInit();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Perangkat ini tidak mendukung masuk dengan Google.');
    }
    _akun = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    return _akun?.email;
  }

  Future<void> keluar() async {
    await _pastikanInit();
    await GoogleSignIn.instance.signOut();
    _akun = null;
  }

  // ── Helper Drive ──────────────────────────────────────────────────────────

  Future<T> _dengan<T>(Future<T> Function(drive.DriveApi api) kerja) async {
    final akun = _akun;
    if (akun == null) {
      throw Exception('Belum masuk ke akun Google.');
    }
    final klien = akun.authorizationClient;
    var izin = await klien.authorizationForScopes(_scopes);
    izin ??= await klien.authorizeScopes(_scopes);

    final http = izin.authClient(scopes: _scopes);
    try {
      return await kerja(drive.DriveApi(http));
    } finally {
      http.close();
    }
  }

  Future<String> _idFolder(drive.DriveApi api) async {
    final res = await api.files.list(
      q: "name = '$_namaFolder' and "
          "mimeType = 'application/vnd.google-apps.folder' and "
          "trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    final ada = res.files;
    if (ada != null && ada.isNotEmpty) return ada.first.id!;

    final baru = await api.files.create(
      drive.File()
        ..name = _namaFolder
        ..mimeType = 'application/vnd.google-apps.folder',
      $fields: 'id',
    );
    return baru.id!;
  }

  /// Nama file → id file, untuk semua isi folder.
  Future<Map<String, String>> _isiFolder(
      drive.DriveApi api, String folderId) async {
    final hasil = <String, String>{};
    String? token;
    do {
      final res = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        pageSize: 200,
        pageToken: token,
        $fields: 'nextPageToken, files(id, name)',
      );
      for (final f in res.files ?? const <drive.File>[]) {
        if (f.name != null && f.id != null) hasil[f.name!] = f.id!;
      }
      token = res.nextPageToken;
    } while (token != null);
    return hasil;
  }

  Future<List<int>> _unduh(drive.DriveApi api, String id) async {
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final out = <int>[];
    await for (final chunk in media.stream) {
      out.addAll(chunk);
    }
    return out;
  }

  // ── Cadangkan ─────────────────────────────────────────────────────────────

  /// Unggah data + foto baru. Foto di Drive yang sudah dihapus dari aplikasi
  /// ikut dihapus, sehingga isi Drive selalu sama dengan isi aplikasi.
  Future<({int total, int fotoBaru, int fotoDihapus})> cadangkan() {
    return _dengan((api) async {
      final folder = await _idFolder(api);
      final isi = await _isiFolder(api, folder);
      final svc = RiwayatDeteksiService.instance;
      final baris = await svc.eksporBaris();
      final dir = await svc.fotoDir();

      var fotoBaru = 0;
      final fotoLokal = <String>{};

      for (final b in baris) {
        final nama = b['foto'] as String?;
        if (nama == null) continue;
        final file = File(p.join(dir.path, nama));
        if (!await file.exists()) {
          b['foto'] = null;
          continue;
        }
        fotoLokal.add(nama);
        if (isi.containsKey(nama)) continue;

        await api.files.create(
          drive.File()
            ..name = nama
            ..parents = [folder],
          uploadMedia: drive.Media(file.openRead(), await file.length()),
        );
        fotoBaru++;
      }

      // Data JSON (buat baru atau timpa yang lama)
      final bytes = utf8.encode(jsonEncode({
        'versi': 1,
        'dibuat': DateTime.now().toIso8601String(),
        'data': baris,
      }));
      final media = drive.Media(Stream.value(bytes), bytes.length);
      final idJson = isi[_namaJson];
      if (idJson == null) {
        await api.files.create(
          drive.File()
            ..name = _namaJson
            ..parents = [folder],
          uploadMedia: media,
        );
      } else {
        await api.files.update(drive.File(), idJson, uploadMedia: media);
      }

      // Hapus foto yatim di Drive (sudah dihapus dari aplikasi)
      var fotoDihapus = 0;
      for (final e in isi.entries) {
        if (!e.key.endsWith('.jpg')) continue;
        if (fotoLokal.contains(e.key)) continue;
        await api.files.delete(e.value);
        fotoDihapus++;
      }

      return (
        total: baris.length,
        fotoBaru: fotoBaru,
        fotoDihapus: fotoDihapus,
      );
    });
  }

  // ── Pulihkan ──────────────────────────────────────────────────────────────

  /// Ambil data dari Drive. Hanya menambah data yang belum ada di perangkat,
  /// tidak menimpa atau menghapus data lokal. Return jumlah data yang masuk.
  Future<int> pulihkan() {
    return _dengan((api) async {
      final folder = await _idFolder(api);
      final isi = await _isiFolder(api, folder);
      final idJson = isi[_namaJson];
      if (idJson == null) {
        throw Exception('Belum ada cadangan di Google Drive.');
      }

      final teks = utf8.decode(await _unduh(api, idJson));
      final data = ((jsonDecode(teks) as Map<String, dynamic>)['data']
              as List)
          .cast<Map<String, dynamic>>();

      final svc = RiwayatDeteksiService.instance;
      final dir = await svc.fotoDir();
      var masuk = 0;

      for (final b in data) {
        String? fotoPath;
        final nama = b['foto'] as String?;
        if (nama != null && isi.containsKey(nama)) {
          final tujuan = File(p.join(dir.path, nama));
          if (!await tujuan.exists()) {
            await tujuan.writeAsBytes(await _unduh(api, isi[nama]!));
          }
          fotoPath = tujuan.path;
        }

        final baru = await svc.sisipkan(
          kodeDeteksi: (b['kode_deteksi'] as String?) ?? '',
          kodeTanaman: b['kode_tanaman'] as String,
          namaTanaman: (b['nama_tanaman'] as String?) ?? '',
          label: b['label'] as String,
          keyakinan: (b['keyakinan'] as num).toDouble(),
          waktuMs: b['waktu'] as int,
          fotoPath: fotoPath,
        );
        if (baru) masuk++;
      }

      svc.segarkan();
      return masuk;
    });
  }
}