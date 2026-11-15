class RiwayatDeteksi {
  final int id;
  final String kodeDeteksi;  // contoh: DET-20261114195223
  final String kodeTanaman;
  final String namaTanaman;  // contoh: Meja 1 • Kolom 2 • Baris 3
  final String label;
  final double keyakinan;    // 0.0–1.0
  final DateTime waktu;
  final String? fotoPath;

  const RiwayatDeteksi({
    required this.id,
    required this.kodeDeteksi,
    required this.kodeTanaman,
    required this.namaTanaman,
    required this.label,
    required this.keyakinan,
    required this.waktu,
    this.fotoPath,
  });
}