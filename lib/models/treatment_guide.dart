/// Tingkat peringatan pada banner di atas panduan.
enum GuideUrgency { urgent, diagnose }

/// Satu rujukan sumber. Setiap langkah/obat menunjuk ke id sumber ini.
class GuideSource {
  final String id; // mis. "S1"
  final String title;
  final String publisher;
  final String url;

  const GuideSource(this.id, this.title, this.publisher, this.url);
}

/// Satu langkah penanganan, mis. "Isolasi tanaman segera".
class GuideStep {
  final String title;
  final String description;

  /// Daftar tindakan yang bisa dicentang pengguna.
  final List<String> items;

  /// Kotak hijau "Tips".
  final String? tip;

  /// Kotak oranye "Perhatian".
  final String? warning;

  /// Id sumber yang mendukung langkah ini.
  final List<String> sourceIds;

  const GuideStep({
    required this.title,
    required this.description,
    required this.items,
    this.tip,
    this.warning,
    this.sourceIds = const [],
  });
}

/// Kartu "Rekomendasi Obat & Formula".
class MedicineItem {
  final String name;
  final String tag;        // mis. "Kimia", "Bahan aktif"
  final String ingredient; // "Kandungan"
  final String usage;      // "Cara pakai"
  final String warning;    // selalu ada — bisa kosong ""
  final List<String> sourceIds;

  const MedicineItem({
    required this.name,
    required this.tag,
    required this.ingredient,
    required this.usage,
    required this.warning,
    this.sourceIds = const [],
  });
}

/// Satu baris pada "Pemantauan pasca-perawatan".
class MonitorEntry {
  final String day;   // mis. "Hari 7"
  final String title; // apa yang dicek
  final String good;  // "Pulih: ..."
  final String bad;   // "Memburuk: ..."

  const MonitorEntry({
    required this.day,
    required this.title,
    required this.good,
    required this.bad,
  });
}

/// Kartu "Opsi penyelamatan" di bagian bawah.
class RescueOption {
  final String title;
  final String description;
  final List<String> sourceIds;

  const RescueOption(this.title, this.description,
      {this.sourceIds = const []});
}

class TreatmentGuide {
  final String title;    // mis. "Protokol Penanganan Antraknosa"
  final String subtitle; // mis. "Colletotrichum sansevieriae"
  final String urgencyLabel; // teks badge, mis. "Menular · Tangani segera"
  final GuideUrgency urgency;
  final String intro;          // paragraf ringkas di bawah progress
  final List<String> materials; // "Siapkan dulu"
  final List<GuideStep> steps;
  final List<MedicineItem> medicines;
  final String? medicinesNote;  // catatan umum di atas kartu obat (opsional)
  final List<MonitorEntry> monitoring;
  final RescueOption? rescue;

  /// Hal yang SENGAJA tidak direkomendasikan karena bukti tidak ada/lemah.
  final String? notProven;

  final List<GuideSource> sources;

  const TreatmentGuide({
    required this.title,
    required this.subtitle,
    required this.urgencyLabel,
    required this.urgency,
    required this.intro,
    required this.materials,
    required this.steps,
    required this.medicines,
    this.medicinesNote,
    required this.monitoring,
    this.rescue,
    this.notProven,
    required this.sources,
  });

  /// Cari sumber berdasarkan id.
  GuideSource? sourceById(String id) {
    try {
      return sources.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
