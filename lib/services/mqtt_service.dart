import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'database_helper.dart';

enum MqttLink { terputus, menghubungkan, terhubung }

class PerangkatStatus {
  final bool pompa;
  final String sumber; // "manual" | "jadwal" | "-"
  final int sisaDetik;
  final String mode;
  final String waktu;
  final int rssi;
  final int jumlahJadwal;

  const PerangkatStatus({
    required this.pompa,
    required this.sumber,
    required this.sisaDetik,
    required this.mode,
    required this.waktu,
    required this.rssi,
    required this.jumlahJadwal,
  });

  factory PerangkatStatus.fromJson(Map<String, dynamic> j) => PerangkatStatus(
        pompa: j['pompa'] == true,
        sumber: (j['sumber'] ?? '-').toString(),
        sisaDetik: (j['sisa_detik'] as num?)?.toInt() ?? 0,
        mode: (j['mode'] ?? '').toString(),
        waktu: (j['waktu'] ?? '').toString(),
        rssi: (j['rssi'] as num?)?.toInt() ?? 0,
        jumlahJadwal: (j['jumlah_jadwal'] as num?)?.toInt() ?? 0,
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
  static const _dasar = 'florasans/$_idPerangkat/';

  /// Siram manual (sketch membatasi maks 10 menit).
  static const int manualMenit = 5;

  /// Durasi tiap jadwal (sketch: minimal 1, maksimal 120 menit).
  static const int durasiJadwalMenit = 5;

  // ── State yang bisa didengarkan widget ───────────────────────────────────
  final link = ValueNotifier<MqttLink>(MqttLink.terputus);
  final perangkatOnline = ValueNotifier<bool>(false);
  final status = ValueNotifier<PerangkatStatus?>(null);
  final logTerakhir = ValueNotifier<String>('');

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
    _sengajaPutus = false;
    _connecting = true;
    link.value = MqttLink.menghubungkan;

    _langganan?.cancel();
    _langganan = null;

    final id = 'app-$_idPerangkat-${Random().nextInt(0xFFFFFF)}';
    final c = MqttServerClient.withPort(_host, id, _port);
    c.keepAlivePeriod = 30;
    c.autoReconnect = true;
    c.resubscribeOnAutoReconnect = true;
    c.logging(on: false);
    c.onConnected = _onConnected;
    c.onDisconnected = _onDisconnected;
    c.onAutoReconnect = () => link.value = MqttLink.menghubungkan;
    c.onAutoReconnected = _onConnected;
    c.connectionMessage =
        MqttConnectMessage().withClientIdentifier(id).startClean();
    _client = c;

    try {
      await c.connect();
    } catch (e) {
      debugPrint('[MQTT] gagal terhubung: $e');
      c.disconnect();
      link.value = MqttLink.terputus;
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
    for (final t in ['status', 'online', 'log', 'jadwal/data']) {
      c.subscribe('$_dasar$t', MqttQos.atLeastOnce);
    }
    unawaited(kirimJadwalDariDb()); // aplikasi = sumber jadwal
    mintaStatus();
  }

  void _onDisconnected() {
    debugPrint('[MQTT] terputus');
    link.value = MqttLink.terputus;
    perangkatOnline.value = false;
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
        case 'log':
          logTerakhir.value = text;
          break;
      }
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
            'durasi': durasiJadwalMenit,
            'aktif': j.isOn,
          }
      ]
    };
    _kirim('jadwal/set', jsonEncode(data));
  }
}