import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

enum MqttLink { terputus, menghubungkan, terhubung }

double _dbl(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// "yyyy-MM-dd HH:mm:ss"
String _stempelWaktu(DateTime t) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${p(t.month)}-${p(t.day)} '
      '${p(t.hour)}:${p(t.minute)}:${p(t.second)}';
}
int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

class PerangkatStatus {
  final bool pompa;
  final String sumber; // "manual" | "jadwal" | "-"
  final int sisaDetik;
  final int berjalanDetik; // lama pompa menyala di sesi ini
  final String mode;
  final String waktu;
  final int rssi;
  final int jumlahJadwal;
  final double flowLpm; // debit sekarang (L/menit)
  final double literSesi; // liter pada sesi siram ini
  final double literTotal; // akumulasi liter sejak reset
  final bool alarmFlow; // pompa dimatikan karena tidak ada aliran

  // Sesi penyiraman terakhir (dicatat ESP32, tahan restart)
  final String terakhirWaktu; // "yyyy-MM-dd HH:mm:ss", kosong = belum ada
  final String terakhirSumber; // "manual" | "jadwal"
  final int terakhirDurasiDetik;
  final double terakhirLiter;
  final String terakhirAlasan; // "manual" | "waktu habis" | "tanpa aliran"

  const PerangkatStatus({
    required this.pompa,
    required this.sumber,
    required this.sisaDetik,
    this.berjalanDetik = 0,
    this.mode = '',
    this.waktu = '',
    this.rssi = 0,
    this.jumlahJadwal = 0,
    this.flowLpm = 0,
    this.literSesi = 0,
    this.literTotal = 0,
    this.alarmFlow = false,
    this.terakhirWaktu = '',
    this.terakhirSumber = '-',
    this.terakhirDurasiDetik = 0,
    this.terakhirLiter = 0,
    this.terakhirAlasan = '',
  });

  static const kosong = PerangkatStatus(pompa: false, sumber: '-', sisaDetik: 0);

  /// Pesan topik `status` dari sketch.
  factory PerangkatStatus.fromJson(Map<String, dynamic> j) => PerangkatStatus(
        pompa: j['pompa'] == true,
        sumber: (j['sumber'] ?? '-').toString(),
        sisaDetik: _int(j['sisa_detik']),
        berjalanDetik: _int(j['berjalan']),
        mode: (j['mode'] ?? '').toString(),
        waktu: (j['waktu'] ?? '').toString(),
        rssi: _int(j['rssi']),
        jumlahJadwal: _int(j['jumlah_jadwal']),
        flowLpm: _dbl(j['flow_lpm']),
        literSesi: _dbl(j['liter_sesi']),
        literTotal: _dbl(j['liter_total']),
        alarmFlow: j['alarm_flow'] == true,
        terakhirWaktu: (j['terakhir_waktu'] ?? '').toString(),
        terakhirSumber: (j['terakhir_sumber'] ?? '-').toString(),
        terakhirDurasiDetik: _int(j['terakhir_durasi']),
        terakhirLiter: _dbl(j['terakhir_liter']),
        terakhirAlasan: (j['terakhir_alasan'] ?? '').toString(),
      );

  PerangkatStatus copyWith({
    bool? pompa,
    String? sumber,
    int? sisaDetik,
    int? berjalanDetik,
    double? flowLpm,
    double? literSesi,
  }) =>
      PerangkatStatus(
        pompa: pompa ?? this.pompa,
        sumber: sumber ?? this.sumber,
        sisaDetik: sisaDetik ?? this.sisaDetik,
        berjalanDetik: berjalanDetik ?? this.berjalanDetik,
        mode: mode,
        waktu: waktu,
        rssi: rssi,
        jumlahJadwal: jumlahJadwal,
        flowLpm: flowLpm ?? this.flowLpm,
        literSesi: literSesi ?? this.literSesi,
        literTotal: literTotal,
        alarmFlow: alarmFlow,
        terakhirWaktu: terakhirWaktu,
        terakhirSumber: terakhirSumber,
        terakhirDurasiDetik: terakhirDurasiDetik,
        terakhirLiter: terakhirLiter,
        terakhirAlasan: terakhirAlasan,
      );
}

/// Satu kali pompa menyala (manual maupun jadwal), dicatat oleh ESP32.
class RiwayatSesi {
  final String waktu; // "yyyy-MM-dd HH:mm:ss" saat pompa mulai
  final String sumber; // "manual" | "jadwal"
  final String alasan; // "manual" | "waktu habis" | "tanpa aliran"
  final int durasiDetik;
  final double liter;

  const RiwayatSesi({
    required this.waktu,
    required this.sumber,
    required this.alasan,
    required this.durasiDetik,
    required this.liter,
  });

  factory RiwayatSesi.fromJson(Map<String, dynamic> j) => RiwayatSesi(
        waktu: (j['w'] ?? '').toString(),
        sumber: (j['s'] ?? 'manual').toString(),
        alasan: (j['a'] ?? '').toString(),
        durasiDetik: _int(j['d']),
        liter: _dbl(j['l']),
      );
}

/// Komunikasi MQTT dengan ESP32 (sketch.ino).
class MqttService {
  MqttService._();
  static final MqttService instance = MqttService._();

  // ── HARUS sama dengan sketch.ino ─────────────────────────────────────────
  static const _host = 'broker.hivemq.com';
  static const _port = 1883;
  static const _idPerangkat = 'florasan_gh'; // = ID_PERANGKAT di sketch
  // Sketch memakai "greenhouse/<ID>/" (sebelumnya di sini salah: "florasans/").
  static const _dasar = 'greenhouse/$_idPerangkat/';

  /// Siram manual (sketch membatasi maks 10 menit).
  static const int manualMenit = 5;

  /// Durasi tiap jadwal (sketch: minimal 1, maksimal 120 menit).
  static const int durasiJadwalMenit = 5;

  // ── State yang bisa didengarkan widget ───────────────────────────────────
  final link = ValueNotifier<MqttLink>(MqttLink.terputus);
  final perangkatOnline = ValueNotifier<bool>(false);
  final status = ValueNotifier<PerangkatStatus?>(null);
  final logTerakhir = ValueNotifier<String>('');

  /// Riwayat penyiraman (maks 10, terbaru di indeks 0). null = belum ada data.
  final riwayat = ValueNotifier<List<RiwayatSesi>?>(null);

  // Pencatat cadangan di aplikasi: bila ESP32 belum mengirim topik 'riwayat'
  // (mis. sketch lama), sesi dicatat dari data live ke SQLite.
  bool _sesiLokal = false;
  DateTime? _mulaiLokal;
  String _sumberLokal = 'manual';

  /// true setelah aplikasi menerima data live dari pompa yang menyala.
  /// Dipakai agar data lama (retained) dari ESP32 tidak langsung tampil.
  final pernahMenyala = ValueNotifier<bool>(false);

  MqttServerClient? _client;
  StreamSubscription? _langganan;
  Timer? _ulang;
  bool _connecting = false;
  bool _sengajaPutus = false;

  bool get terhubung =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // ── Koneksi ──────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_connecting || terhubung) return;
    unawaited(_muatRiwayat()); // tampilkan riwayat tersimpan walau offline
    _sengajaPutus = false;
    _connecting = true;
    _ulang?.cancel();
    link.value = MqttLink.menghubungkan;

    _langganan?.cancel();
    _langganan = null;

    // Bersihkan client lama tanpa memicu callback-nya.
    final lama = _client;
    if (lama != null) {
      lama.onDisconnected = null;
      lama.disconnect();
    }

    final id = 'app-$_idPerangkat-${Random().nextInt(0xFFFFFF)}';
    final c = MqttServerClient.withPort(_host, id, _port);
    c.keepAlivePeriod = 30;
    // Auto-reconnect bawaan dimatikan: reconnect ditangani _jadwalkanUlang(),
    // supaya tidak ada dua mekanisme yang saling bentrok.
    c.autoReconnect = false;
    c.logging(on: false);
    c.onConnected = _onConnected;
    c.onDisconnected = _onDisconnected;
    c.connectionMessage =
        MqttConnectMessage().withClientIdentifier(id).startClean();
    _client = c;

    try {
      await c.connect();
    } catch (e) {
      debugPrint('[MQTT] gagal terhubung: $e');
      c.onDisconnected = null;
      c.disconnect();
      link.value = MqttLink.terputus;
      perangkatOnline.value = false;
      _connecting = false;
      _jadwalkanUlang();
      return;
    }
    _connecting = false;
  }

  void disconnect() {
    _sengajaPutus = true;
    _ulang?.cancel();
    _client?.disconnect();
  }

  void _jadwalkanUlang() {
    _ulang?.cancel();
    if (_sengajaPutus) return;
    _ulang = Timer(const Duration(seconds: 5), connect);
  }

  void _onConnected() {
    debugPrint('[MQTT] tersambung ke broker');
    link.value = MqttLink.terhubung;
    final c = _client!;
    // Pasang pendengar SEBELUM subscribe agar pesan retained tidak terlewat.
    _langganan ??= c.updates!.listen(_onPesan);
    // 'live' = data realtime 1 detik (debit, liter, waktu berjalan).
    for (final t in ['status', 'online', 'log', 'jadwal/data', 'live', 'riwayat']) {
      c.subscribe('$_dasar$t', MqttQos.atLeastOnce);
    }
    unawaited(kirimJadwalDariDb()); // aplikasi = sumber jadwal
    mintaStatus();
  }

  void _onDisconnected() {
    debugPrint('[MQTT] terputus');
    link.value = MqttLink.terputus;
    perangkatOnline.value = false;
    _connecting = false;
    _jadwalkanUlang();
  }

  // `events` dibiarkan dynamic agar kompatibel dengan beberapa versi mqtt_client.
  void _onPesan(dynamic events) {
    for (final e in (events as List)) {
      final msg = e.payload as MqttPublishMessage;
      final text = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
      final topic = e.topic as String;
      final sub =
          topic.startsWith(_dasar) ? topic.substring(_dasar.length) : topic;
      debugPrint('[MQTT] $sub <- $text');

      switch (sub) {
        case 'online':
          perangkatOnline.value = text.trim() == 'online';
          break;
        case 'status':
          try {
            status.value = PerangkatStatus.fromJson(
                jsonDecode(text) as Map<String, dynamic>);
          } catch (_) {}
          break;
        case 'live':
          try {
            final j = jsonDecode(text) as Map<String, dynamic>;
            if (j['pompa'] == true) pernahMenyala.value = true;
            _catatSesiLokal(j);
            status.value = (status.value ?? PerangkatStatus.kosong).copyWith(
              pompa: j['pompa'] == true,
              sumber: (j['sumber'] ?? '-').toString(),
              sisaDetik: _int(j['sisa']),
              berjalanDetik: _int(j['berjalan']),
              flowLpm: _dbl(j['lpm']),
              literSesi: _dbl(j['liter']),
            );
          } catch (_) {}
          break;
        case 'riwayat':
          try {
            final j = jsonDecode(text) as Map<String, dynamic>;
            final list = [
              for (final e in (j['riwayat'] as List? ?? const []))
                RiwayatSesi.fromJson(e as Map<String, dynamic>)
            ];
            unawaited(_simpanDariEsp(list));
          } catch (_) {}
          break;
        case 'log':
          logTerakhir.value = text;
          break;
      }
    }
  }

  // ── Riwayat di SQLite ────────────────────────────────────────────────────
  Future<void> _muatRiwayat() async {
    try {
      final rows = await _RiwayatDb.instance.semua();
      riwayat.value = [
        for (final r in rows)
          RiwayatSesi(
            waktu: (r['waktu'] ?? '').toString(),
            sumber: (r['sumber'] ?? 'manual').toString(),
            alasan: (r['alasan'] ?? '').toString(),
            durasiDetik: _int(r['durasi']),
            liter: _dbl(r['liter']),
          )
      ];
    } catch (e) {
      debugPrint('[RIWAYAT] gagal memuat: $e');
      riwayat.value ??= const <RiwayatSesi>[];
    }
  }

  Future<void> _simpanDariEsp(List<RiwayatSesi> list) async {
    try {
      // Dari yang paling lama agar urutan simpan sesuai kronologi.
      for (final r in list.reversed) {
        await _RiwayatDb.instance.simpan(
          waktu: r.waktu.trim().isEmpty ? _stempelWaktu(DateTime.now()) : r.waktu,
          sumber: r.sumber,
          alasan: r.alasan,
          durasi: r.durasiDetik,
          liter: r.liter,
          dariEsp: true,
        );
      }
    } catch (e) {
      debugPrint('[RIWAYAT] gagal menyimpan: $e');
    }
    await _muatRiwayat();
  }

  Future<void> _simpanLokal(RiwayatSesi r) async {
    try {
      await _RiwayatDb.instance.simpan(
        waktu: r.waktu.trim().isEmpty ? _stempelWaktu(DateTime.now()) : r.waktu,
        sumber: r.sumber,
        alasan: r.alasan,
        durasi: r.durasiDetik,
        liter: r.liter,
        dariEsp: false,
      );
    } catch (e) {
      debugPrint('[RIWAYAT] gagal menyimpan: $e');
    }
    await _muatRiwayat();
  }

  /// Catat satu sesi penyiraman dari pesan `live` (cadangan bila ESP32 belum
  /// mengirim riwayat sendiri).
  void _catatSesiLokal(Map<String, dynamic> j) {
    final menyala = j['pompa'] == true;
    if (menyala && !_sesiLokal) {
      _sesiLokal = true;
      _mulaiLokal =
          DateTime.now().subtract(Duration(seconds: _int(j['berjalan'])));
      _sumberLokal = (j['sumber'] ?? 'manual').toString();
    } else if (!menyala && _sesiLokal) {
      _sesiLokal = false;
      final t = _mulaiLokal ?? DateTime.now();
      String p(int n) => n.toString().padLeft(2, '0');
      final sesi = RiwayatSesi(
        waktu: '${t.year}-${p(t.month)}-${p(t.day)} '
            '${p(t.hour)}:${p(t.minute)}:${p(t.second)}',
        sumber: _sumberLokal,
        alasan: '',
        durasiDetik: _int(j['berjalan']),
        liter: _dbl(j['liter']),
      );
      unawaited(_simpanLokal(sesi));
    }
  }

  // ── Perintah ke ESP32 ────────────────────────────────────────────────────
  bool _kirim(String sub, String payload) {
    if (!terhubung) return false;
    final b = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage('$_dasar$sub', MqttQos.atLeastOnce, b.payload!);
    debugPrint('[MQTT] $sub -> $payload');
    return true;
  }

  bool pompaNyala([int menit = manualMenit]) => _kirim('pompa/cmd', 'ON:$menit');
  bool pompaMati() => _kirim('pompa/cmd', 'OFF');
  bool mintaStatus() => _kirim('status/get', '1');

  /// Reset total liter akumulasi di ESP32.
  bool resetTotalLiter() => _kirim('flow/reset', '1');

  bool aturWaktu(DateTime t) {
    String p(int n) => n.toString().padLeft(2, '0');
    return _kirim('waktu/set',
        '${t.year}-${p(t.month)}-${p(t.day)} ${p(t.hour)}:${p(t.minute)}:${p(t.second)}');
  }

  /// Kirim seluruh jadwal dari SQLite ke ESP32 (topik jadwal/set).
  /// Hari di aplikasi: 0=Sen … 6=Min. Hari di sketch: 0=Min, 1=Sen … 6=Sab.
  Future<void> kirimJadwalDariDb() async {
    final list = await DatabaseHelper.instance.getAll();
    final data = {
      'jadwal': [
        for (final j in list.take(10)) // sketch: maksimum 10 jadwal
          {
            'hari': ([for (final d in j.days) (d + 1) % 7]..sort()),
            'jam': j.time.hour,
            'menit': j.time.minute,
            // Durasi yang diatur pengguna per jadwal (sketch: 1..120 menit).
            'durasi': j.durasi.clamp(1, 120).toInt(),
            'aktif': j.isOn,
          }
      ]
    };
    _kirim('jadwal/set', jsonEncode(data));
  }
}

// ── Penyimpanan riwayat penyiraman di SQLite ───────────────────────────────
/// Penyimpanan riwayat penyiraman di SQLite (database sendiri, terpisah dari
/// database jadwal). Satu baris = satu kali pompa menyala.
class _RiwayatDb {
  _RiwayatDb._();
  static final _RiwayatDb instance = _RiwayatDb._();

  Future<Database>? _future;
  Future<Database> get _database => _future ??= _buka();

  Future<Database> _buka() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/riwayat_penyiraman.db',
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE riwayat(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          waktu TEXT NOT NULL,
          sumber TEXT NOT NULL,
          alasan TEXT NOT NULL,
          durasi INTEGER NOT NULL,
          liter REAL NOT NULL,
          lokal INTEGER NOT NULL
        )
      '''),
    );
  }

  static String _fmt(DateTime t) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${p(t.month)}-${p(t.day)} '
        '${p(t.hour)}:${p(t.minute)}:${p(t.second)}';
  }

  /// Cari baris dengan sumber sama, waktu mulai dan durasi yang hampir sama.
  Future<int?> _cariMirip(
    Database db, {
    required String waktu,
    required String sumber,
    required int durasi,
    required int lokal,
  }) async {
    final t = DateTime.tryParse(waktu.replaceFirst(' ', 'T'));
    if (t == null) return null;
    final rows = await db.query(
      'riwayat',
      columns: ['id'],
      where: 'sumber = ? AND lokal = ? AND waktu BETWEEN ? AND ? '
          'AND durasi BETWEEN ? AND ?',
      whereArgs: [
        sumber,
        lokal,
        _fmt(t.subtract(const Duration(seconds: 90))),
        _fmt(t.add(const Duration(seconds: 90))),
        durasi - 3,
        durasi + 3,
      ],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  /// Simpan satu sesi.
  /// [dariEsp] true  = dicatat ESP32 (data utama, lengkap dengan alasan).
  /// [dariEsp] false = dicatat aplikasi sendiri dari data live (cadangan).
  /// Sesi yang sama tidak akan tersimpan dua kali.
  Future<void> simpan({
    required String waktu,
    required String sumber,
    required String alasan,
    required int durasi,
    required double liter,
    required bool dariEsp,
  }) async {
    final db = await _database;
    final data = <String, Object?>{
      'waktu': waktu,
      'sumber': sumber,
      'alasan': alasan,
      'durasi': durasi,
      'liter': liter,
      'lokal': dariEsp ? 0 : 1,
    };

    if (dariEsp) {
      // ESP32 mengirim ulang seluruh daftarnya tiap terhubung.
      final persis = await db.query('riwayat',
          columns: ['id'],
          where: 'waktu = ? AND sumber = ?',
          whereArgs: [waktu, sumber],
          limit: 1);
      if (persis.isNotEmpty) {
        await db.update('riwayat', data,
            where: 'id = ?', whereArgs: [persis.first['id']]);
        return;
      }
      // Sudah dicatat aplikasi lebih dulu -> ganti dengan data ESP32.
      final id = await _cariMirip(db,
          waktu: waktu, sumber: sumber, durasi: durasi, lokal: 1);
      if (id != null) {
        await db.update('riwayat', data, where: 'id = ?', whereArgs: [id]);
        return;
      }
    } else {
      // ESP32 sudah mencatat sesi ini -> tidak perlu dobel.
      final id = await _cariMirip(db,
          waktu: waktu, sumber: sumber, durasi: durasi, lokal: 0);
      if (id != null) return;
    }
    await db.insert('riwayat', data);
  }

  /// Terbaru di urutan pertama.
  Future<List<Map<String, Object?>>> semua({int limit = 200}) async {
    final db = await _database;
    return db.query('riwayat', orderBy: 'waktu DESC, id DESC', limit: limit);
  }

  Future<void> hapusSemua() async {
    final db = await _database;
    await db.delete('riwayat');
  }
}