import 'package:flutter/material.dart';
import '../models/jadwal_item.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class KelembapanRiwayatCard extends StatefulWidget {
  const KelembapanRiwayatCard({super.key});

  @override
  State<KelembapanRiwayatCard> createState() => _KelembapanRiwayatCardState();
}

class _KelembapanRiwayatCardState extends State<KelembapanRiwayatCard> {
  late Future<_Terakhir?> _future;

  @override
  void initState() {
    super.initState();
    _future = _muat();
  }

  static const _namaHari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// Cari jadwal aktif yang paling baru sudah lewat (maks. 7 hari ke belakang).
  Future<_Terakhir?> _muat() async {
    final list = await DatabaseHelper.instance.getAll();
    final aktif = list.where((j) => j.isOn && j.days.isNotEmpty).toList();
    if (aktif.isEmpty) return null;

    final now = DateTime.now();
    for (int mundur = 0; mundur <= 7; mundur++) {
      final tgl = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: mundur));
      final hari = tgl.weekday - 1; // 0 = Senin
      JadwalItem? terbaik;
      for (final j in aktif) {
        if (!j.days.contains(hari)) continue;
        final waktu = DateTime(
            tgl.year, tgl.month, tgl.day, j.time.hour, j.time.minute);
        if (waktu.isAfter(now)) continue; // belum terjadi
        if (terbaik == null ||
            j.time.hour * 60 + j.time.minute >
                terbaik.time.hour * 60 + terbaik.time.minute) {
          terbaik = j;
        }
      }
      if (terbaik != null) {
        final label = mundur == 0
            ? 'Hari ini'
            : mundur == 1
                ? 'Kemarin'
                : _namaHari[hari];
        return _Terakhir('$label, ${terbaik.timeString}', terbaik.durasi);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FutureBuilder<_Terakhir?>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Penyiraman terakhir',
                      style: AppTextStyles.hint),
                  if (data != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Berhasil',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data?.waktu ?? 'Belum ada penyiraman',
                style: AppTextStyles.lastWateringTitle,
              ),
              const SizedBox(height: 4),
              Text(
                data == null
                    ? 'Atur jadwal otomatis di atas'
                    : '${data.durasi} menit • Otomatis',
                style: AppTextStyles.hint,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Terakhir {
  final String waktu;
  final int durasi;
  const _Terakhir(this.waktu, this.durasi);
}