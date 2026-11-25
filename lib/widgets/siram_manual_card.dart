import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SiramManualCard extends StatefulWidget {
  const SiramManualCard({super.key});

  @override
  State<SiramManualCard> createState() => _SiramManualCardState();
}

class _SiramManualCardState extends State<SiramManualCard> {
  /// Nilai yang diminta pengguna dan sedang menunggu konfirmasi ESP32.
  /// null = tidak ada perintah yang menunggu.
  bool? _tunggu;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _bersihkanTunggu() {
    _tunggu = null;
    _timer?.cancel();
    _timer = null;
  }

  void _ubah(bool nyala, MqttService svc) {
    if (_tunggu != null) return; // abaikan ketukan saat masih menunggu
    setState(() => _tunggu = nyala);
    if (nyala) {
      svc.pompaNyala(MqttService.manualMenit);
    } else {
      svc.pompaMati();
    }
    // Bila ESP32 tidak membalas, kembali ke status sebenarnya.
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(_bersihkanTunggu);
    });
  }

  /// Dipanggil saat tombol nonaktif diketuk: jelaskan penyebabnya.
  void _tampilAlasan(BuildContext context, MqttService svc) {
    final pesan = svc.link.value != MqttLink.terhubung
        ? 'Belum terhubung ke broker MQTT. Periksa koneksi internet HP.'
        : 'Perangkat offline. Nyalakan ESP32 atau jalankan simulasi Wokwi dulu.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  String _fmt(int detik) {
    final m = detik ~/ 60;
    final d = (detik % 60).toString().padLeft(2, '0');
    return '$m:$d';
  }

  String _subtitle(MqttLink link, bool online, PerangkatStatus s) {
    if (link != MqttLink.terhubung) return 'Katup 1 · Belum terhubung ke broker';
    if (!online) return 'Katup 1 · Perangkat offline';
    if (_tunggu != null) return 'Katup 1 · Mengirim perintah…';
    if (s.pompa) {
      return 'Katup 1 · Menyiram (${s.sumber})';
    }
    if (s.alarmFlow) return 'Katup 1 · Pompa dimatikan: tidak ada aliran';
    return 'Katup 1 · Siap digunakan';
  }

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }

  /// Selalu ditampilkan. "--" bila belum terhubung / perangkat offline.
  Widget _statistik(PerangkatStatus s, bool siap, bool menyala) {
    // Kosong ("--") sampai pompa dinyalakan; setelah itu terisi otomatis,
    // dan setelah pompa mati tetap menampilkan hasil sesi terakhir.
    final terisi = menyala || MqttService.instance.pernahMenyala.value;
    final waktu = terisi ? _fmt(s.berjalanDetik) : '--';
    final total = terisi ? '${s.literSesi.toStringAsFixed(1)} L' : '--';
    final debit = !terisi
        ? '--'
        : '${(menyala ? s.flowLpm : 0.0).toStringAsFixed(1)} L/mnt';
    return Opacity(
      // Agak redup bila belum terhubung, tapi tetap terlihat.
      opacity: siap ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(Icons.timer_outlined, 'Waktu', waktu),
              _stat(Icons.opacity, 'Total air', total),
              _stat(Icons.speed, 'Debit', debit),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            terisi
                ? 'Akumulasi: ${s.literTotal.toStringAsFixed(1)} L'
                : 'Akumulasi: --',
            style: AppTextStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = MqttService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge(
          [svc.link, svc.perangkatOnline, svc.status, svc.pernahMenyala]),
      builder: (context, _) {
        // Tidak nullable: pakai nilai kosong bila belum ada data dari ESP32.
        final s = svc.status.value ?? PerangkatStatus.kosong;
        final siap =
            svc.link.value == MqttLink.terhubung && svc.perangkatOnline.value;
        final menyala = siap && s.pompa; // status sebenarnya dari ESP32

        // ESP32 sudah membalas sesuai permintaan, atau koneksi putus:
        // lepaskan status "menunggu".
        if (_tunggu != null && (!siap || menyala == _tunggu)) {
          _bersihkanTunggu();
        }

        // Switch mengikuti ketukan pengguna selama menunggu balasan.
        final tampilNyala = _tunggu ?? menyala;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_outlined,
                        color: AppColors.primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Siram Manual',
                            style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(
                              svc.link.value, svc.perangkatOnline.value, s),
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: siap ? null : () => _tampilAlasan(context, svc),
                    child: AbsorbPointer(
                      absorbing: !siap,
                      child: Switch(
                        value: tampilNyala,
                        // null = nonaktif bila perangkat/broker tidak tersedia
                        onChanged: siap ? (v) => _ubah(v, svc) : null,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.toggleActive,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: AppColors.toggleInactive,
                      ),
                    ),
                  ),
                ],
              ),
              _statistik(s, siap, menyala),
            ],
          ),
        );
      },
    );
  }
}