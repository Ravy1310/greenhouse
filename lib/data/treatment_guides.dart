import '../models/disease_result.dart';
import '../models/treatment_guide.dart';

/// Isi panduan pengobatan. Setiap klaim menunjuk ke sumber (id "S..") yang
/// tercantum di bagian `sources` tiap panduan dan ditampilkan di layar.
///
/// Catatan penting untuk pengembang:
/// - Panduan ini ringkasan dari literatur/extension, bukan resep dokter tanaman.
/// - Nama merek obat SENGAJA tidak dicantumkan: izin edar berbeda antar negara.
/// - Jadwal pemantauan adalah panduan praktis, bukan batas waktu dari penelitian.
class TreatmentGuides {
  TreatmentGuides._();

  static TreatmentGuide? forLabel(DiseaseLabel label) {
    switch (label) {
      case DiseaseLabel.anthracnose:
        return anthracnose;
      case DiseaseLabel.leafWithering:
        return leafWithering;
      case DiseaseLabel.healthy:
        return null;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ANTRAKNOSA
  // ───────────────────────────────────────────────────────────────────────────

  static const TreatmentGuide anthracnose = TreatmentGuide(
    title: 'Protokol Penanganan Antraknosa',
    subtitle: 'Bercak daun akibat jamur Colletotrichum',
    urgencyLabel: 'Menular lewat percikan air · Tangani segera',
    urgency: GuideUrgency.urgent,
    intro:
        'Antraknosa pada sansevieria disebabkan jamur Colletotrichum sansevieriae. '
        'Jamur menyebar lewat percikan air serta tangan dan alat yang menyentuh '
        'tanaman sakit. Fungisida hanya melindungi jaringan yang masih sehat dan '
        'tidak menyembuhkan bercak yang sudah ada, sehingga penanganan utamanya: '
        'buang daun bergejala, jaga daun tetap kering, dan cegah penularan.',
    materials: [
      'Gunting/pisau tajam',
      'Alkohol (untuk disinfeksi alat)',
      'Sarung tangan',
      'Kantong plastik',
      'Alas koran/kain',
      'Fungisida terdaftar (opsional)',
    ],
    steps: [
      GuideStep(
        title: 'Isolasi tanaman',
        description:
            'Spora jamur berpindah lewat percikan air, tangan, dan alat. Pisahkan '
            'tanaman sakit dari sansevieria lain, karena jamur ini hanya diketahui '
            'menyerang sansevieria.',
        items: [
          'Pindahkan pot ke tempat terpisah, jauh dari sansevieria lain',
          'Cuci tangan dan alat setelah menyentuh tanaman sakit',
          'Jangan menyemprot daun; hindari percikan air antar pot',
        ],
        tip: 'Catat tanggal mulai gejala agar perkembangannya bisa dibandingkan '
            'saat pemantauan.',
        sourceIds: ['S2', 'S3'],
      ),
      GuideStep(
        title: 'Buang daun yang bergejala',
        description:
            'Daun bergejala dibuang dan dimusnahkan. Lakukan saat daun kering dan '
            'gunakan alat yang sudah didisinfeksi.',
        items: [
          'Lakukan saat daun dan alas kering, jangan memangkas dalam kondisi basah',
          'Disinfeksi gunting sebelum memotong dan di antara setiap potongan',
          'Potong daun bercak sampai pangkal, setinggi permukaan media',
          'Bungkus potongan dengan plastik lalu buang; jangan ditinggal di media',
        ],
        tip: 'Fungisida tidak menyembuhkan bercak yang sudah ada, jadi membuang '
            'daun yang terparah adalah langkah utama.',
        warning: 'Memangkas saat basah mempermudah penyebaran spora ke daun lain.',
        sourceIds: ['S1', 'S2', 'S6'],
      ),
      GuideStep(
        title: 'Jaga daun tetap kering',
        description:
            'Infeksi berlangsung saat permukaan daun tetap basah. Menurut UF/IFAS, '
            'bila daun basah empat jam atau lebih setelah disiram atau terkena '
            'hujan, jamur mulai mematikan jaringan.',
        items: [
          'Siram langsung ke media, jangan ke daun atau celah antar daun',
          'Siram pagi hari agar daun sempat kering sebelum malam',
          'Beri jarak antar pot agar udara bersirkulasi',
          'Lindungi dari percikan hujan dan hindari melukai daun',
        ],
        tip: 'Siram hanya saat media kering; sansevieria tidak butuh air '
            'sesering tanaman lain.',
        sourceIds: ['S1', 'S2', 'S3', 'S6', 'S14'],
      ),
      GuideStep(
        title: 'Pertimbangkan fungisida (opsional)',
        description:
            'Fungisida melindungi daun yang masih sehat, bukan menyembuhkan bercak '
            'lama. Pertimbangkan bila penyakit terus menyebar ke daun sehat atau '
            'tanaman bernilai tinggi.',
        items: [
          'Pilih produk yang terdaftar dan berlabel untuk tanaman hias di negara Anda',
          'Semprot daun sehat sesuai dosis dan interval pada label '
              '(UF/IFAS: umumnya 7–10 hari saat lembap, lebih longgar saat kering)',
          'Ikuti semua petunjuk keselamatan pada label produk',
          'Bila diulang, gilir bahan aktif dengan cara kerja berbeda',
        ],
        warning: 'Jangan melebihi dosis pada label. Hasil uji laboratorium pada '
            'daun terpisah belum tentu sama pada tanaman di rumah Anda.',
        sourceIds: ['S2', 'S3', 'S4'],
      ),
    ],
    medicinesNote:
        'Yang tercantum adalah bahan aktif (bukan merek) yang disebut dalam '
        'rekomendasi extension atau diuji pada jamur ini. Cek produk yang '
        'terdaftar di negara Anda dan ikuti label.',
    medicines: [
      MedicineItem(
        name: 'Fungisida kontak (protektan)',
        tag: 'Kimia',
        ingredient: 'Mankozeb, atau tembaga (mis. tembaga oksiklorida).',
        usage:
            'Disemprot pada permukaan daun sehat sebagai perlindungan, sesuai '
            'label. UF/IFAS menyebut mankozeb, klorotalonil, dan fungisida tembaga '
            'sebagai protektan untuk Colletotrichum pada tanaman hias. Pada uji di '
            'cawan petri terhadap jamur ini, tembaga oksiklorida dan tiofanat-metil '
            'memberi daya hambat tertinggi dari lima fungisida yang diuji.',
        warning: 'Hanya melindungi jaringan sehat; tidak menyembuhkan bercak lama.',
        sourceIds: ['S2', 'S4', 'S5'],
      ),
      MedicineItem(
        name: 'Fungisida sistemik',
        tag: 'Kimia',
        ingredient: 'Azoksistrobin, atau tiofanat-metil.',
        usage:
            'Semprot sebelum penyakit meluas. UF/IFAS: fungisida sistemik memberi '
            'kontrol terbaik bila diaplikasikan sebelum penyakit berkembang. Pada '
            'uji daun terpisah, azoksistrobin melindungi 100% daun bila diberikan '
            'pada hari inokulasi, tetapi efek penyembuhannya terbatas bila baru '
            'diberikan tiga hari setelah infeksi.',
        warning: 'Gunakan sesuai label dan gilir bahan aktif. Hasil laboratorium '
            'pada daun terpisah belum tentu sama pada tanaman utuh.',
        sourceIds: ['S2', 'S4'],
      ),
    ],
    notProven:
        'Sengaja tidak direkomendasikan: (1) minyak esensial seperti thyme, bubuk '
        'kayu manis, dan bahan "alami" lain. Efeknya pada jamur ini baru diuji di '
        'cawan petri (thyme menghambat 88% perkecambahan spora), belum terbukti pada '
        'tanaman hidup, dan bisa melukai daun. (2) Bakterisida: antraknosa '
        'disebabkan jamur, bukan bakteri. (3) Campuran dengan karbendazim memang '
        'efektif di laboratorium, tetapi status izinnya berbeda antar negara; '
        'tanyakan penyuluh pertanian setempat.',
    monitoring: [
      MonitorEntry(
        day: 'Hari 1–3',
        title: 'Cek bekas potongan dan daun di sekitarnya',
        good: 'bekas potongan kering, tidak ada bercak baru',
        bad: 'bercak basah berair muncul di daun yang sehat',
      ),
      MonitorEntry(
        day: 'Hari 7',
        title: 'Cek bercak lama dan daun lain',
        good: 'bercak lama tidak melebar, tidak ada bercak baru',
        bad: 'bercak melebar atau saling menyatu',
      ),
      MonitorEntry(
        day: 'Hari 14',
        title: 'Cek ulang seluruh daun (gejala baru bisa muncul sampai ±10 hari)',
        good: 'tidak ada gejala baru',
        bad: 'bercak baru atau titik hitam melingkar pada bercak',
      ),
      MonitorEntry(
        day: 'Hari 30',
        title: 'Evaluasi akhir',
        good: 'daun baru tumbuh tanpa bercak',
        bad: 'gejala berulang: ulangi langkah 2–3 dan tanyakan penyuluh pertanian',
      ),
    ],
    rescue: RescueOption(
      'Opsi penyelamatan: anakan yang sehat',
      'Jika sebagian besar daun sudah terinfeksi, pertahankan anakan atau rumpun '
          'yang bebas bercak: pisahkan dari tanaman induk dan tanam di pot bersih '
          'dengan media baru (menurut Penn State Extension, perbanyakan paling mudah '
          'adalah dengan membagi rumpun). Jangan mengambil bahan tanam dari daun '
          'yang bergejala.',
      sourceIds: ['S6'],
    ),
    sources: [
      GuideSource(
        'S1',
        'Colletotrichum sansevieriae Causing Anthracnose of Sansevieria '
            "trifasciata 'Laurentii' and 'Moonshine' in South Florida",
        'Campoverde & Palmateer, Proc. Fla. State Hort. Soc. 125 (2012)',
        'https://journals.flvc.org/fshs/article/download/84019/80994/102092',
      ),
      GuideSource(
        'S2',
        'Anthracnose Disease of Landscape Plants (ENH1395/EP659)',
        'UF/IFAS Extension, University of Florida',
        'https://ask.ifas.ufl.edu/publication/EP659',
      ),
      GuideSource(
        'S3',
        'A new anthracnose on Sansevieria',
        'J. Marquez, Hawaii Department of Agriculture (2023)',
        'https://hawaiiscape.starchapter.com/blog/id/28',
      ),
      GuideSource(
        'S4',
        'Chemical control of anthracnose of Sansevieria trifasciata var. Hahnii '
            'on a detached-leaf system',
        'Pérez-León dkk., Agronomía Mesoamericana 26(2), 2015',
        'https://revistas.ucr.ac.cr/index.php/agromeso/article/view/19323',
      ),
      GuideSource(
        'S5',
        'The first report of Colletotrichum isolates causing Sansevieria leaf rot '
            'and their control with plant essential oils in Guilan province',
        'Jurnal Perlindungan Tanaman (Iran); uji in vitro',
        'https://jopp.gau.ac.ir/article_7596.html?lang=en',
      ),
      GuideSource(
        'S6',
        'Snake Plant: A Forgiving, Low-maintenance Houseplant',
        'Penn State Extension (2023)',
        'https://extension.psu.edu/snake-plant-a-forgiving-low-maintenance-houseplant',
      ),
      GuideSource(
        'S14',
        'Snake Plant Care',
        'White Flower Farm (publikasi kebun, bukan universitas)',
        'https://www.whiteflowerfarm.com/snake-plant-care',
      ),
    ],
  );

  // ───────────────────────────────────────────────────────────────────────────
  // LAYU DAUN (LEAF WITHERING)
  // ───────────────────────────────────────────────────────────────────────────

  static const TreatmentGuide leafWithering = TreatmentGuide(
    title: 'Protokol Penanganan Daun Layu',
    subtitle: 'Gejala layu atau mengering: cari penyebabnya dulu',
    urgencyLabel: 'Diagnosa penyebab dulu · Jangan langsung diobati',
    urgency: GuideUrgency.diagnose,
    intro:
        'Label "Leaf Withering" pada dataset menggambarkan gejala (daun layu atau '
        'mengering), bukan satu penyakit tertentu, dan dataset tidak menyebut '
        'penyebabnya. Pada sansevieria, busuk akar akibat media terlalu basah adalah '
        'masalah yang umum; penyebab lain antara lain kekurangan air, suhu dingin, '
        'sengatan matahari, dan hama. Karena penyebab tidak bisa dipastikan dari '
        'foto, ikuti pemeriksaan di bawah sebelum mengobati.',
    materials: [
      'Jari atau tusuk kayu (cek media)',
      'Gunting bersih + alkohol',
      'Pot baru berlubang drainase',
      'Media porous (campuran kaktus/perlite)',
      'Kapas + alkohol isopropil',
      'Kantong plastik',
    ],
    steps: [
      GuideStep(
        title: 'Cek media dan akar',
        description:
            'Kelebihan air dan kekurangan air bisa tampak sama pada tanaman (daun '
            'layu), jadi periksa media dan akar sebelum menyiram atau mengobati.',
        items: [
          'Tusukkan jari ±5 cm ke media: becek berarti kelebihan air, kering total '
              'berarti kekurangan',
          'Keluarkan tanaman dari pot dan periksa akar',
          'Akar sehat kokoh dan berwarna terang; akar busuk cokelat atau hitam, '
              'lunak, dan mudah lepas',
        ],
        tip: 'Jangan menyiram lebih banyak sebelum tahu medianya basah atau kering.',
        sourceIds: ['S6', 'S7', 'S11', 'S14'],
      ),
      GuideStep(
        title: 'Jika akar busuk: selamatkan',
        description:
            'Tanaman bisa pulih bila masih ada akar sehat. Bila terlambat, mungkin '
            'tidak dapat diselamatkan.',
        items: [
          'Buang media lama dan bersihkan akar dari sisa media',
          'Disinfeksi gunting, lalu potong semua akar cokelat, hitam, atau lunak '
              'sampai jaringan sehat',
          'Tanam di pot bersih berlubang drainase dengan media baru yang porous',
          'Jangan taruh kerikil atau pecahan di dasar pot (menghambat drainase)',
          'Jangan memupuk sampai akar baru tumbuh',
        ],
        tip: 'Setelah ditanam ulang, tunggu sampai media kering sebelum menyiram.',
        warning: 'Bila hampir semua akar busuk dan pangkal sudah lunak, peluang '
            'pulih kecil. Pertimbangkan menyelamatkan anakan yang masih keras.',
        sourceIds: ['S6', 'S7', 'S10', 'S11', 'S14', 'S16'],
      ),
      GuideStep(
        title: 'Perbaiki penyiraman, suhu, dan cahaya',
        description:
            'Sansevieria menyimpan air di daun dan mudah busuk bila media basah '
            'terus-menerus. Siram hanya saat media kering.',
        items: [
          'Biarkan media kering sepenuhnya di antara penyiraman',
          'Cek dengan jari sebelum menyiram, bukan menurut jadwal',
          'Jangan biarkan air menggenang di tatakan atau di sela daun',
          'Jauhkan dari suhu di bawah 10 °C dan embusan dingin',
          'Hindari matahari langsung yang terik; cahaya terang tidak langsung paling baik',
        ],
        tip: 'Kebutuhan air turun saat udara dingin atau lembap, sesuaikan frekuensinya.',
        sourceIds: ['S6', 'S12', 'S13', 'S14'],
      ),
      GuideStep(
        title: 'Periksa hama dan rapikan daun',
        description:
            'Bila media dan akar baik, periksa hama. Kutu putih (mealybug) dan '
            'tungau kadang menyerang sansevieria.',
        items: [
          'Periksa pangkal dan sela daun: bercak putih seperti kapas (kutu putih) '
              'atau jaring halus (tungau)',
          'Bila ada, isolasi tanaman; lap dengan kapas berisi alkohol isopropil '
              'atau semprot air kuat; ulangi sampai bersih',
          'Daun yang rusak dipotong di permukaan media dengan gunting bersih',
        ],
        warning: 'Uji dulu alkohol atau sabun pada sebagian kecil daun; beberapa '
            'tanaman peka dan daunnya bisa rusak.',
        sourceIds: ['S6', 'S8', 'S9', 'S17'],
      ),
    ],
    medicinesNote:
        'Tidak ada obat tunggal untuk "daun layu" karena penyebabnya beragam. '
        'Perbaikan media, drainase, dan penyiraman adalah penanganan utama. '
        'Fungisida hanya relevan bila penyebabnya jamur akar yang terkonfirmasi dan '
        'efeknya bergantung jenis patogen; tanyakan penyuluh pertanian.',
    medicines: [
      MedicineItem(
        name: 'Alkohol atau sabun insektisida',
        tag: 'Hanya bila ada hama',
        ingredient: 'Alkohol isopropil pada kapas, atau sabun insektisida untuk '
            'tanaman dalam ruang.',
        usage: 'Lap atau semprot bagian yang terserang kutu putih atau tungau, '
            'ulangi sesuai petunjuk. Pada serangan ringan, mencabut hama secara '
            'manual atau menyemprot air juga efektif.',
        warning: 'Uji dulu pada sebagian kecil daun. Hindari alkohol berlebih '
            'pada daun karena bisa merusaknya.',
        sourceIds: ['S8', 'S9', 'S17'],
      ),
    ],
    notProven:
        'Sengaja tidak direkomendasikan: bubuk kayu manis, hidrogen peroksida, dan '
        'arang aktif sebagai "obat" busuk akar. Klaim itu hanya saya temukan di blog '
        'berkebun, bukan di sumber universitas. Langkah yang konsisten di sumber '
        'tepercaya: buang akar busuk, ganti media, dan perbaiki penyiraman.',
    monitoring: [
      MonitorEntry(
        day: 'Hari 1–3',
        title: 'Cek media dan pangkal daun',
        good: 'media mulai mengering, pangkal tetap kokoh',
        bad: 'pangkal makin lunak atau berbau, daun roboh bertambah',
      ),
      MonitorEntry(
        day: 'Hari 7',
        title: 'Cek daun yang masih tegak',
        good: 'tidak ada daun baru yang layu',
        bad: 'layu bertambah: periksa akar lagi',
      ),
      MonitorEntry(
        day: 'Hari 14',
        title: 'Cek media dan hama',
        good: 'daun tetap tegak, media kering di antara penyiraman',
        bad: 'media selalu basah atau hama muncul kembali',
      ),
      MonitorEntry(
        day: 'Hari 30',
        title: 'Evaluasi akhir',
        good: 'tunas atau daun baru muncul',
        bad: 'tidak ada pertumbuhan dan pangkal lunak: selamatkan anakan',
      ),
    ],
    rescue: RescueOption(
      'Opsi penyelamatan: bagi rumpun',
      'Jika pangkal sudah lunak hampir seluruhnya, ambil anakan atau bagian '
          'rimpang yang masih keras, lalu tanam di media baru dan pot bersih '
          '(pembagian rumpun adalah cara perbanyakan paling mudah menurut Penn '
          'State Extension). Bila tidak ada bagian yang sehat, tanaman mungkin '
          'tidak dapat diselamatkan.',
      sourceIds: ['S6', 'S14'],
    ),
    sources: [
      GuideSource(
        'S6',
        'Snake Plant: A Forgiving, Low-maintenance Houseplant',
        'Penn State Extension (2023)',
        'https://extension.psu.edu/snake-plant-a-forgiving-low-maintenance-houseplant',
      ),
      GuideSource(
        'S7',
        'Can I save my Sansevieria trifasciata Hahnii that has root rot? (#780324)',
        'Ask Extension (jawaban pakar penyuluh)',
        'https://ask.extension.org/kb/faq.php?id=780324',
      ),
      GuideSource(
        'S8',
        'Houseplant Insect Control (ENTFACT-406)',
        'University of Kentucky Extension',
        'https://entomology.ca.uky.edu/files/ef406.pdf',
      ),
      GuideSource(
        'S9',
        'Mealybugs on Indoor Plants',
        'University of Maryland Extension',
        'https://extension.umd.edu/resource/mealybugs-indoor-plants',
      ),
      GuideSource(
        'S10',
        'Root rot in house plants',
        'BBC Gardeners\u2019 World (majalah berkebun, bukan universitas)',
        'https://gardenersworld.com/house-plants/root-rot-house-plants',
      ),
      GuideSource(
        'S11',
        'Root Rot: When Overwatering Damages Plant Roots',
        'Old Farmer\u2019s Almanac (publikasi berkebun, bukan universitas)',
        'https://www.almanac.com/pest/root-rot-when-overwatering-damages-plant-roots',
      ),
      GuideSource(
        'S12',
        'Mother-in-law\u2019s tongue',
        'University of Illinois Extension',
        'https://extension.illinois.edu/houseplants/mother-law-tongue',
      ),
      GuideSource(
        'S13',
        'Snake Plant Care',
        'Old Farmer\u2019s Almanac (publikasi berkebun, bukan universitas)',
        'https://www.almanac.com/plant/snake-plants',
      ),
      GuideSource(
        'S14',
        'Snake Plant Care',
        'White Flower Farm (publikasi kebun, bukan universitas)',
        'https://www.whiteflowerfarm.com/snake-plant-care',
      ),
      GuideSource(
        'S15',
        'Indoor Plant Disease Image Dataset for Classification',
        'Mendeley Data (deskripsi kelas dataset)',
        'https://data.mendeley.com/datasets/7wbstnfpjy/2',
      ),
      GuideSource(
        'S16',
        'Houseplant Root Rot 101: Symptoms, Causes, and Easy Fixes',
        'Gardening Know How (situs berkebun, bukan universitas)',
        'https://www.gardeningknowhow.com/plant-problems/disease/houseplant-root-rot.htm',
      ),
      GuideSource(
        'S17',
        'Mealy bugs on houseplants',
        'CSU Extension PlantTalk Colorado',
        'https://planttalk.colostate.edu/topics/insects-diseases/1466-mealy-bugs-houseplants',
      ),
    ],
  );
}
