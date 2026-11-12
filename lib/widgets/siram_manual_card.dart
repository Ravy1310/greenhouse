import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SiramManualCard extends StatelessWidget {
  const SiramManualCard({super.key});

  String _subtitle(MqttLink link, bool online, PerangkatStatus? s) {
    if (link != MqttLink.terhubung) return 'Katup 1 · Belum terhubung ke broker';
    if (!online) return 'Katup 1 · Perangkat offline';
    if (s != null && s.pompa) {
      final m = s.sisaDetik ~/ 60;
      final d = (s.sisaDetik % 60).toString().padLeft(2, '0');
      return 'Katup 1 · Menyiram (${s.sumber}) · sisa $m:$d';
    }
    return 'Katup 1 · Siap digunakan';
  }

  @override
  Widget build(BuildContext context) {
    final svc = MqttService.instance;
    return ListenableBuilder(
      listenable:
          Listenable.merge([svc.link, svc.perangkatOnline, svc.status]),
      builder: (context, _) {
        final s = svc.status.value;
        final siap =
            svc.link.value == MqttLink.terhubung && svc.perangkatOnline.value;
        final menyala = siap && (s?.pompa ?? false);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
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
                    const Text('Siram Manual', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(_subtitle(svc.link.value,
                            svc.perangkatOnline.value, s),
                        style: AppTextStyles.cardSubtitle),
                  ],
                ),
              ),
              Switch(
                value: menyala,
                // null = nonaktif bila perangkat/broker tidak tersedia
                onChanged: siap
                    ? (v) => v
                        ? svc.pompaNyala(MqttService.manualMenit)
                        : svc.pompaMati()
                    : null,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.toggleActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.toggleInactive,
              ),
            ],
          ),
        );
      },
    );
  }
}