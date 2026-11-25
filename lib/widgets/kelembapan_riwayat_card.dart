import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Riwayat penyiraman. Setiap kali pompa menyala (manual maupun jadwal)
/// punya catatan sendiri: jam, durasi, dan total liter. Data dari ESP32.
class KelembapanRiwayatCard extends StatefulWidget {
  const KelembapanRiwayatCard({super.key});

  @override
  State<KelembapanRiwayatCard> createState() => _KelembapanRiwayatCardState();
}

class _KelembapanRiwayatCardState extends State<KelembapanRiwayatCard> {
  static const _batasRingkas = 5;
  bool _semua = false;

  static const _namaHari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  DateTime? _parse(String raw) =>
      DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));

  /// "2026-11-20 14:05:10" -> "14:05"
  String _jam(String raw) {
    final t = _parse(raw);
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// "2026-11-20 14:05:10" -> "Hari ini" / "Kemarin" / "Senin" / "12/11/2026"
  String _tanggal(String raw) {
    final t = _parse(raw);
    if (t == null) return 'Waktu tidak tercatat';
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final selisih = hariIni.difference(DateTime(t.year, t.month, t.day)).inDays;
    if (selisih <= 0) return 'Hari ini';
    if (selisih == 1) return 'Kemarin';
    if (selisih < 7) return _namaHari[t.weekday - 1];
    return '${t.day}/${t.month}/${t.year}';
  }

  String _fmtDurasi(int detik) {
    if (detik < 60) return '$detik detik';
    final m = detik ~/ 60;
    final d = detik % 60;
    return d == 0 ? '$m menit' : '$m menit $d detik';
  }

  String _namaSumber(String sumber) =>
      sumber == 'jadwal' ? 'Otomatis' : 'Manual';

  Widget _baris(RiwayatSesi r) {
    final gagal = r.alasan == 'tanpa aliran';
    final subtitle = '${_tanggal(r.waktu)} • ${_fmtDurasi(r.durasiDetik)} • '
        '${_namaSumber(r.sumber)}${gagal ? ' • Tanpa aliran' : ''}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: gagal ? const Color(0xFFFFEEEE) : AppColors.mintGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              gagal ? Icons.error_outline : Icons.water_drop_outlined,
              size: 20,
              color: gagal ? Colors.red : AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_jam(r.waktu), style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Text('${r.liter.toStringAsFixed(1)} L',
              style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = MqttService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge(
          [svc.link, svc.perangkatOnline, svc.riwayat]),
      builder: (context, _) {
        final daftar = svc.riwayat.value; // null = belum ada data
        final live =
            svc.link.value == MqttLink.terhubung && svc.perangkatOnline.value;

        final tampil = daftar == null
            ? const <RiwayatSesi>[]
            : (_semua ? daftar : daftar.take(_batasRingkas).toList());

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Opacity(
            // Redup bila belum terhubung (data = yang terakhir diketahui).
            opacity: live ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Riwayat penyiraman', style: AppTextStyles.hint),
                const SizedBox(height: 6),

                if (tampil.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      (daftar == null && !live)
                          ? 'Menunggu data dari perangkat'
                          : 'Belum ada penyiraman',
                      style: AppTextStyles.lastWateringTitle,
                    ),
                  )
                else
                  for (int i = 0; i < tampil.length; i++) ...[
                    _baris(tampil[i]),
                    if (i != tampil.length - 1)
                      const Divider(height: 1, color: AppColors.sliderTrack),
                  ],

                if (daftar != null && daftar.length > _batasRingkas)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _semua = !_semua),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _semua
                            ? 'Tampilkan lebih sedikit'
                            : 'Lihat semua (${daftar.length})',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}