import 'package:flutter/material.dart';

class JadwalItem {
  final int? id;
  TimeOfDay time;
  Set<int> days; // 0=Sen … 6=Min
  bool isOn;

  JadwalItem({
    this.id,
    required this.time,
    required this.days,
    required this.isOn,
  });

  // ── Label helpers ──────────────────────────────────────────────────────────
  static const _dayLabels = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  String get timeString {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get periodLabel {
    final h = time.hour;
    if (h >= 5 && h < 12) return 'Pagi';
    if (h >= 12 && h < 15) return 'Siang';
    if (h >= 15 && h < 18) return 'Sore';
    return 'Malam';
  }

  String get daysLabel {
    if (days.length == 7) return 'Setiap hari';
    if (days.isEmpty) return '-';
    final sorted = days.toList()..sort();
    return sorted.map((d) => _dayLabels[d]).join(', ');
  }

  String get subtitle => '$periodLabel • $daysLabel';

  // ── SQLite serialization ───────────────────────────────────────────────────
  /// Days stored as comma-separated integers, e.g. "0,1,2,3,4,5,6"
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'days_csv': (days.toList()..sort()).join(','),
        'is_on': isOn ? 1 : 0,
      };

  factory JadwalItem.fromMap(Map<String, dynamic> map) {
    final csv = (map['days_csv'] as String?) ?? '';
    final days = csv.isEmpty
        ? <int>{}
        : csv.split(',').map(int.parse).toSet();

    return JadwalItem(
      id: map['id'] as int?,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      days: days,
      isOn: (map['is_on'] as int) == 1,
    );
  }

  JadwalItem copyWith({
    int? id,
    TimeOfDay? time,
    Set<int>? days,
    bool? isOn,
  }) =>
      JadwalItem(
        id: id ?? this.id,
        time: time ?? this.time,
        days: days ?? Set.from(this.days),
        isOn: isOn ?? this.isOn,
      );
}
