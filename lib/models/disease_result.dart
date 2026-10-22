import 'package:flutter/material.dart';

/// Label mentah dari labels.txt
enum DiseaseLabel {
  anthracnose,
  healthy,
  leafWithering,
}

/// Hasil inferensi dari model TFLite
class DiseaseResult {
  final DiseaseLabel label;
  final double confidence; // 0.0 – 1.0

  /// Bounding-box relatif terhadap ukuran gambar (nilai 0.0–1.0).
  /// Null jika model adalah classifier murni (tidak mengembalikan bbox).
  final Rect? boundingBox;

  const DiseaseResult({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  // ── Display helpers ────────────────────────────────────────────────────────

  String get displayName {
    switch (label) {
      case DiseaseLabel.anthracnose:
        return 'Anthracnose';
      case DiseaseLabel.healthy:
        return 'Sehat';
      case DiseaseLabel.leafWithering:
        return 'Layu Daun';
    }
  }

  /// Persentase kepercayaan, mis. "96%"
  String get confidencePercent =>
      '${(confidence * 100).round()}%';

  /// Label chip di atas bounding box, mis. "Anthracnose 96%"
  String get chipLabel => '$displayName $confidencePercent';

  bool get isHealthy => label == DiseaseLabel.healthy;

  // ── Raw label → enum ───────────────────────────────────────────────────────
  static DiseaseLabel labelFromString(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.contains('anthracnose')) return DiseaseLabel.anthracnose;
    if (s.contains('whiter') || s.contains('wither')) {
      return DiseaseLabel.leafWithering;
    }
    return DiseaseLabel.healthy;
  }

  @override
  String toString() =>
      'DiseaseResult(label: $displayName, confidence: $confidencePercent)';
}
