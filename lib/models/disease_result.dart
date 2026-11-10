/// Label hasil klasifikasi model (3 kelas)
enum DiseaseLabel {
  anthracnose, // Snake_Plant_Anthracnose
  healthy, // Snake_Plant_Healthy
  leafWithering, // Snake_Plant_Leaf_Withering
}

/// Tingkat keyakinan model untuk ditampilkan ke pengguna.
enum ConfidenceLevel { high, medium, low }

/// Probabilitas satu kelas dari keluaran model.
class ClassScore {
  final DiseaseLabel label;
  final double probability; // 0.0 – 1.0
  const ClassScore(this.label, this.probability);
}

/// Hasil inferensi dari model TFLite
class DiseaseResult {
  /// Batas tampilan tingkat keyakinan (bukan hasil kalibrasi statistik;
  /// ubah sesuai kebutuhan setelah menguji di foto lapangan).
  static const double highThreshold = 0.85;
  static const double mediumThreshold = 0.60;

  /// Bila selisih dua kelas teratas kurang dari ini, hasil dianggap "hampir seimbang".
  static const double ambiguousMargin = 0.15;

  /// Kelas dengan probabilitas tertinggi.
  final DiseaseLabel label;

  /// Probabilitas kelas teratas (0.0 – 1.0).
  final double confidence;

  /// Probabilitas semua kelas, urut dari yang terbesar.
  final List<ClassScore> scores;

  const DiseaseResult({
    required this.label,
    required this.confidence,
    this.scores = const [],
  });

  // ── Keyakinan ──────────────────────────────────────────────────────────────

  /// Persentase kepercayaan, mis. "96%"
  String get confidencePercent => '${(confidence * 100).round()}%';

  ConfidenceLevel get confidenceLevel {
    if (confidence >= highThreshold) return ConfidenceLevel.high;
    if (confidence >= mediumThreshold) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  String get confidenceLevelText {
    switch (confidenceLevel) {
      case ConfidenceLevel.high:
        return 'Tinggi';
      case ConfidenceLevel.medium:
        return 'Sedang';
      case ConfidenceLevel.low:
        return 'Rendah';
    }
  }

  /// Penjelasan singkat sesuai tingkat keyakinan.
  String get confidenceNote {
    switch (confidenceLevel) {
      case ConfidenceLevel.high:
        return 'Model cukup yakin dengan hasil ini. Tetap cocokkan dengan kondisi daun yang sebenarnya.';
      case ConfidenceLevel.medium:
        return 'Model cukup yakin, tetapi masih ada kemungkinan lain. Lihat rincian probabilitas dan ulangi foto dari jarak dekat bila ragu.';
      case ConfidenceLevel.low:
        return 'Keyakinan rendah, hasil kurang dapat diandalkan. Ambil ulang foto satu daun dari jarak ±20–30 cm dengan cahaya cukup dan latar sederhana. '
            'Perlu diingat, model tidak mengenali foto non-daun: benda lain pun tetap diberi salah satu label.';
    }
  }

  /// True bila dua kelas teratas hampir sama kuat.
  bool get isAmbiguous =>
      scores.length >= 2 &&
      (scores[0].probability - scores[1].probability) < ambiguousMargin;

  // ── Display helpers ────────────────────────────────────────────────────────

  String get displayName => nameOf(label);

  /// Label chip di atas gambar, mis. "Anthracnose 96%"
  String get chipLabel => '$displayName $confidencePercent';

  bool get isHealthy => label == DiseaseLabel.healthy;

  /// Nama tampilan untuk sebuah label.
  static String nameOf(DiseaseLabel label) {
    switch (label) {
      case DiseaseLabel.anthracnose:
        return 'Anthracnose';
      case DiseaseLabel.healthy:
        return 'Sehat';
      case DiseaseLabel.leafWithering:
        return 'Layu Daun';
    }
  }

  // ── Raw label → enum ───────────────────────────────────────────────────────

  /// Mengubah nama kelas dari meta.json menjadi enum.
  /// Melempar [FormatException] bila nama kelas tidak dikenal, agar ketidakcocokan
  /// model dan aplikasi ketahuan saat model dimuat, bukan menampilkan label keliru.
  static DiseaseLabel labelFromString(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('anthracnose')) return DiseaseLabel.anthracnose;
    if (s.contains('whiter') || s.contains('wither')) {
      return DiseaseLabel.leafWithering;
    }
    if (s.contains('healthy')) return DiseaseLabel.healthy;
    throw FormatException('Nama kelas tidak dikenal: "$raw"');
  }

  @override
  String toString() =>
      'DiseaseResult(label: $displayName, confidence: $confidencePercent, '
      'level: $confidenceLevelText)';
}