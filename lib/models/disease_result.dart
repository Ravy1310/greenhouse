/// Label hasil klasifikasi model
enum DiseaseLabel {
  notSansevieria, // Not_Sansevieria — bukan daun / tidak yakin
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

  final DiseaseLabel label;

  /// Probabilitas kelas teratas model (0.0 – 1.0).
  final double confidence;

  /// True bila label = notSansevieria karena keyakinan di bawah ambang
  /// (bukan karena model memilih kelas Not_Sansevieria).
  final bool uncertain;

  /// Probabilitas mentah kelas Not_Sansevieria (null bila model tidak punya kelas ini).
  final double? pNeg;

  /// Probabilitas semua kelas, urut dari yang terbesar.
  final List<ClassScore> scores;

  const DiseaseResult({
    required this.label,
    required this.confidence,
    this.uncertain = false,
    this.pNeg,
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
        return 'Keyakinan rendah, hasil kurang dapat diandalkan. Ambil ulang foto satu daun dari jarak ±20–30 cm dengan cahaya cukup dan latar sederhana.';
    }
  }

  /// Dugaan terkuat model (sebelum aturan "tidak yakin" diterapkan).
  ClassScore? get topGuess => scores.isEmpty ? null : scores.first;

  /// True bila dua kelas teratas hampir sama kuat.
  bool get isAmbiguous =>
      scores.length >= 2 &&
      (scores[0].probability - scores[1].probability) < ambiguousMargin;

  // ── Display helpers ────────────────────────────────────────────────────────

  String get displayName => nameOf(label, uncertain: uncertain);

  /// Label chip di atas gambar, mis. "Anthracnose 96%"
  String get chipLabel => '$displayName $confidencePercent';

  bool get isHealthy => label == DiseaseLabel.healthy;

  /// True jika gambar tidak dikenali sebagai daun sansevieria
  /// atau keyakinan di bawah ambang
  bool get isUnrecognized => label == DiseaseLabel.notSansevieria;

  /// Nama tampilan untuk sebuah label.
  static String nameOf(DiseaseLabel label, {bool uncertain = false}) {
    switch (label) {
      case DiseaseLabel.notSansevieria:
        return uncertain ? 'Tidak yakin' : 'Bukan Sansevieria';
      case DiseaseLabel.anthracnose:
        return 'Anthracnose';
      case DiseaseLabel.healthy:
        return 'Sehat';
      case DiseaseLabel.leafWithering:
        return 'Layu Daun';
    }
  }

  // ── Raw label → enum ───────────────────────────────────────────────────────

  static DiseaseLabel labelFromString(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('not_sansevieria') || s.contains('not sansevieria')) {
      return DiseaseLabel.notSansevieria;
    }
    if (s.contains('anthracnose')) return DiseaseLabel.anthracnose;
    if (s.contains('whiter') || s.contains('wither')) {
      return DiseaseLabel.leafWithering;
    }
    if (s.contains('healthy')) return DiseaseLabel.healthy;
    // fallback — tidak dikenali
    return DiseaseLabel.notSansevieria;
  }

  @override
  String toString() =>
      'DiseaseResult(label: $displayName, confidence: $confidencePercent, '
      'level: $confidenceLevelText, uncertain: $uncertain, '
      'pNeg: ${pNeg?.toStringAsFixed(3)})';
}
