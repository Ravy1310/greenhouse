import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoraHeader extends StatelessWidget {
  const LoraHeader({super.key});

  String _kualitas(int rssi) {
    if (rssi == 0) return 'RSSI -';
    if (rssi >= -67) return 'RSSI Baik';
    if (rssi >= -80) return 'RSSI Sedang';
    return 'RSSI Lemah';
  }

  @override
  Widget build(BuildContext context) {
    final svc = MqttService.instance;
    return ListenableBuilder(
      listenable:
          Listenable.merge([svc.link, svc.perangkatOnline, svc.status]),
      builder: (context, _) {
        final link = svc.link.value;
        final online = svc.perangkatOnline.value;
        final rssi = svc.status.value?.rssi ?? 0;

        final judul = link != MqttLink.terhubung
            ? (link == MqttLink.menghubungkan
                ? 'Menghubungkan ke broker…'
                : 'Broker Terputus')
            : (online ? 'Perangkat Terhubung' : 'Perangkat Offline');

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(online ? Icons.wifi : Icons.wifi_off,
                  color: AppColors.lightGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul, style: AppTextStyles.headerTitle),
                    const SizedBox(height: 2),
                    const Text('Wi-Fi + MQTT · Sansevieria Teras',
                        style: AppTextStyles.headerSubtitle),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(online && rssi != 0 ? '$rssi dBm' : '-- dBm',
                      style: AppTextStyles.headerTitle),
                  const SizedBox(height: 2),
                  Text(online ? _kualitas(rssi) : 'RSSI -',
                      style: AppTextStyles.headerSubtitle),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}