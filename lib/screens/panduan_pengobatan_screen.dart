import 'package:flutter/material.dart';

import '../models/disease_result.dart';
import '../theme/app_colors.dart';

const String _font = 'Plus Jakarta Sans';
const Color _mint = Color(0xFFE3F1E8);
const Color _warnBg = Color(0xFFFDE8D8);
const Color _warnFg = Color(0xFFB4410B);

/// Layar "Protokol Penyelamatan" — dibuka dari tombol panduan di hasil deteksi.
/// Berisi: status & progres, bahan yang disiapkan, langkah ber-checklist,
/// rekomendasi obat, pemantauan pasca-perawatan, dan opsi penyelamatan.
class PanduanPengobatanScreen extends StatefulWidget {
  final DiseaseResult result;
  const PanduanPengobatanScreen({super.key, required this.result});

  @override
  State<PanduanPengobatanScreen> createState() =>
      _PanduanPengobatanScreenState();
}

class _PanduanPengobatanScreenState extends State<PanduanPengobatanScreen> {
  late final _Protocol? _protocol;
  late final List<List<bool>> _checks;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _protocol = (r.uncertain || r.isUnrecognized || r.isHealthy)
        ? null
        : _protocolFor(r.label);
    _checks = [
      for (final s in _protocol?.steps ?? const <_Step>[])
        List<bool>.filled(s.tasks.length, false),
    ];
  }

  bool _isDone(int i) => _checks[i].every((c) => c);
  int get _doneCount => List.generate(_checks.length, _isDone).where((d) => d).length;

  @override
  Widget build(BuildContext context) {
    final p = _protocol;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: p == null ? 'Tips Foto yang Baik' : 'Protokol Penyelamatan Daun',
              subtitle: p == null ? null : widget.result.displayName,
            ),
            Expanded(
              child: p == null
                  ? _PhotoTips(result: widget.result)
                  : _buildProtocol(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocol(_Protocol p) {
    final total = p.steps.length;
    final done = _doneCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Status & progres ────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _warnBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.severity,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _warnFg,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$done dari $total langkah selesai',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  color: AppColors.primaryGreen,
                  backgroundColor: const Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                p.estimate,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Siapkan dulu ────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Siapkan dulu', style: _titleStyle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in p.supplies)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14532D),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── Langkah-langkah ─────────────────────────────────────────────
        for (var i = 0; i < p.steps.length; i++) ...[
          const SizedBox(height: 14),
          _StepCard(
            index: i + 1,
            step: p.steps[i],
            checks: _checks[i],
            done: _isDone(i),
            onToggle: (t, v) => setState(() => _checks[i][t] = v),
          ),
        ],

        // ── Rekomendasi obat ────────────────────────────────────────────
        if (p.meds.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 10),
            child: Text('Rekomendasi Obat & Formula', style: _titleStyle),
          ),
          for (final m in p.meds) ...[
            _MedCard(med: m),
            const SizedBox(height: 14),
          ],
        ],

        // ── Pemantauan ──────────────────────────────────────────────────
        const SizedBox(height: 4),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pemantauan pasca-perawatan', style: _titleStyle),
              const SizedBox(height: 12),
              for (var i = 0; i < p.monitoring.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                _MonitorRow(item: p.monitoring[i]),
              ],
            ],
          ),
        ),

        // ── Opsi penyelamatan ───────────────────────────────────────────
        const SizedBox(height: 14),
        _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_outlined,
                    size: 20, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.rescueTitle,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.rescueText, style: _bodyStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Style & komponen umum
// ─────────────────────────────────────────────────────────────────────────────
const TextStyle _titleStyle = TextStyle(
  fontFamily: _font,
  fontSize: 15.5,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

const TextStyle _bodyStyle = TextStyle(
  fontFamily: _font,
  fontSize: 12.5,
  height: 1.45,
  color: AppColors.textSecondary,
);

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _Header({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left,
                  size: 24, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 40), // penyeimbang tombol kembali
        ],
      ),
    );
  }
}

/// Kotak Tips (hijau) / Perhatian (oranye)
class _NoteBox extends StatelessWidget {
  final String label;
  final String text;
  final bool warning;
  const _NoteBox({
    required this.label,
    required this.text,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final fg = warning ? _warnFg : const Color(0xFF166534);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning ? _warnBg : _mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
        style: TextStyle(
          fontFamily: _font,
          fontSize: 12.5,
          height: 1.45,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu langkah
// ─────────────────────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int index;
  final _Step step;
  final List<bool> checks;
  final bool done;
  final void Function(int task, bool value) onToggle;

  const _StepCard({
    required this.index,
    required this.step,
    required this.checks,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: done ? AppColors.primaryGreen : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$index',
                          style: const TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(step.title, style: _titleStyle)),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.description, style: _bodyStyle),
          const SizedBox(height: 6),
          for (var t = 0; t < step.tasks.length; t++)
            InkWell(
              onTap: () => onToggle(t, !checks[t]),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: checks[t],
                        onChanged: (v) => onToggle(t, v ?? false),
                        activeColor: AppColors.primaryGreen,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.tasks[t],
                        style: const TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (step.tip != null)
            _NoteBox(label: 'Tips', text: step.tip!, warning: false),
          if (step.warning != null)
            _NoteBox(label: 'Perhatian', text: step.warning!, warning: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu obat
// ─────────────────────────────────────────────────────────────────────────────
class _MedCard extends StatelessWidget {
  final _Med med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontFamily: _font,
      fontSize: 12.5,
      height: 1.45,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_outlined,
                    size: 20, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(med.name, style: _titleStyle.copyWith(fontSize: 14.5)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  med.tag,
                  style: const TextStyle(
                    fontFamily: _font,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Kandungan: ', style: label),
              TextSpan(text: med.content),
            ]),
            style: _bodyStyle,
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Cara pakai: ', style: label),
              TextSpan(text: med.usage),
            ]),
            style: _bodyStyle,
          ),
          _NoteBox(label: 'Perhatian', text: med.caution, warning: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Baris pemantauan
// ─────────────────────────────────────────────────────────────────────────────
class _MonitorRow extends StatelessWidget {
  final _Monitor item;
  const _MonitorRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.day,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.check,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text('Pulih: ${item.good}', style: _bodyStyle),
              Text('Memburuk: ${item.bad}', style: _bodyStyle),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tampilan tips foto (hasil tidak yakin / bukan Sansevieria)
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoTips extends StatelessWidget {
  final DiseaseResult result;
  const _PhotoTips({required this.result});

  @override
  Widget build(BuildContext context) {
    final tips = <String>[
      if (result.uncertain)
        'Model belum yakin dengan foto ini, bukan berarti tanaman bukan Sansevieria.'
      else
        'Gambar tidak dikenali sebagai daun Sansevieria.',
      'Ambil foto satu daun dari jarak dekat (sekitar 20–30 cm) dengan bagian bercak di tengah.',
      'Gunakan cahaya alami yang cukup, hindari bayangan dan foto buram.',
      'Usahakan latar tidak terlalu ramai, lalu ulangi pemindaian.',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tips.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == tips.length - 1 ? 0 : 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: _font,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            tips[i],
                            style: const TextStyle(
                              fontFamily: _font,
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model data protokol
// ─────────────────────────────────────────────────────────────────────────────
class _Step {
  final String title;
  final String description;
  final List<String> tasks;
  final String? tip;
  final String? warning;
  const _Step({
    required this.title,
    required this.description,
    required this.tasks,
    this.tip,
    this.warning,
  });
}

class _Med {
  final String name;
  final String tag; // Kimia / Alami
  final String content;
  final String usage;
  final String caution;
  const _Med({
    required this.name,
    required this.tag,
    required this.content,
    required this.usage,
    required this.caution,
  });
}

class _Monitor {
  final String day;
  final String check;
  final String good;
  final String bad;
  const _Monitor({
    required this.day,
    required this.check,
    required this.good,
    required this.bad,
  });
}

class _Protocol {
  final String severity;
  final String estimate;
  final List<String> supplies;
  final List<_Step> steps;
  final List<_Med> meds;
  final List<_Monitor> monitoring;
  final String rescueTitle;
  final String rescueText;
  const _Protocol({
    required this.severity,
    required this.estimate,
    required this.supplies,
    required this.steps,
    required this.meds,
    required this.monitoring,
    required this.rescueTitle,
    required this.rescueText,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Isi protokol per penyakit
// ─────────────────────────────────────────────────────────────────────────────
_Protocol? _protocolFor(DiseaseLabel label) {
  switch (label) {
    case DiseaseLabel.anthracnose:
      return _anthracnose;
    case DiseaseLabel.leafWithering:
      return _leafWithering;
    case DiseaseLabel.healthy:
    case DiseaseLabel.notSansevieria:
      return null;
  }
}

const _Protocol _anthracnose = _Protocol(
  severity: 'Perlu penanganan · Segera tangani',
  estimate:
      'Estimasi: ±30 menit untuk penanganan awal, lalu pantau 3–4 minggu. '
      'Mulai dari langkah 1 dan jangan melompat urutan.',
  supplies: [
    'Gunting/cutter steril',
    'Alkohol 70%',
    'Sarung tangan',
    'Kantong plastik',
    'Fungisida',
    'Sprayer',
  ],
  steps: [
    _Step(
      title: 'Isolasi tanaman segera',
      description:
          'Spora jamur menyebar lewat percikan air, udara, dan sentuhan. '
          'Pisahkan tanaman agar tidak menulari koleksi lain.',
      tasks: [
        'Pindahkan pot ke ruang terpisah, jauh dari tanaman sehat',
        'Cuci tangan dan alas yang tersentuh dengan sabun',
        'Periksa tanaman di sekitarnya: bercak cokelat atau daun berlubang',
      ],
      tip: 'Beri label "karantina" pada pot dan catat tanggalnya di Buku Catatan.',
    ),
    _Step(
      title: 'Buang daun terinfeksi',
      description:
          'Daun bercak adalah sumber spora. Semua bagian yang terinfeksi '
          'harus dibuang.',
      tasks: [
        'Sterilkan gunting dengan alkohol 70% sebelum memotong',
        'Potong daun bercak sampai pangkal, sisakan jaringan sehat',
        'Sterilkan ulang gunting setiap selesai satu potongan',
        'Bungkus sisa potongan dalam plastik dan buang, jangan dikomposkan',
      ],
      warning:
          'Jika lebih dari separuh daun terinfeksi, fokus pada penyelamatan '
          'daun yang masih sehat.',
    ),
    _Step(
      title: 'Semprot fungisida',
      description:
          'Fungisida melindungi jaringan sehat dan menghentikan penyebaran '
          'jamur.',
      tasks: [
        'Gunakan fungisida tembaga (copper-based) atau mankozeb sesuai label',
        'Semprot seluruh bagian tanaman, atas dan bawah daun',
        'Ulangi setiap 7–10 hari selama 3–4 minggu',
      ],
      tip: 'Semprot pagi atau sore hari, hindari terik matahari langsung.',
    ),
    _Step(
      title: 'Atur kelembapan & sirkulasi',
      description:
          'Jamur berkembang di lingkungan lembap. Kurangi kelembapan di '
          'sekitar tanaman.',
      tasks: [
        'Sirami langsung ke media tanam, jangan dari atas daun',
        'Beri jarak antar tanaman agar udara mengalir',
        'Tempatkan di area terang dengan ventilasi baik',
      ],
      warning:
          'Jangan menyiram saat daun masih basah oleh sisa semprotan.',
    ),
  ],
  meds: [
    _Med(
      name: 'Fungisida berbahan tembaga',
      tag: 'Kimia',
      content: 'Tembaga (mis. kupri hidroksida atau oksiklorida) sebagai bahan aktif.',
      usage: 'Larutkan sesuai petunjuk label, lalu semprot ke seluruh permukaan daun.',
      caution: 'Pakai sarung tangan dan jangan melebihi dosis pada label produk.',
    ),
    _Med(
      name: 'Fungisida mankozeb',
      tag: 'Kimia',
      content: 'Mankozeb, fungisida kontak berspektrum luas.',
      usage: 'Semprot setiap 7–10 hari sesuai dosis pada label.',
      caution: 'Gunakan masker dan sarung tangan, hindari terhirup.',
    ),
    _Med(
      name: 'Minyak neem',
      tag: 'Alami',
      content: 'Senyawa alami dengan sifat antijamur ringan.',
      usage: 'Campurkan sesuai label dan semprot tipis pada daun.',
      caution: 'Pendamping saja. Pada infeksi berat, efeknya terbatas dibanding fungisida.',
    ),
  ],
  monitoring: [
    _Monitor(
      day: 'Hari 3',
      check: 'Cek bekas potongan & daun',
      good: 'bercak tidak melebar',
      bad: 'bercak baru muncul',
    ),
    _Monitor(
      day: 'Hari 7',
      check: 'Cek daun & media',
      good: 'daun tegak, media kering',
      bad: 'bercak melebar atau menghitam',
    ),
    _Monitor(
      day: 'Hari 14',
      check: 'Cek seluruh tanaman',
      good: 'tidak ada bercak baru',
      bad: 'bercak menyebar ke daun lain',
    ),
    _Monitor(
      day: 'Hari 30',
      check: 'Evaluasi akhir',
      good: 'daun baru tumbuh sehat',
      bad: 'infeksi berulang: ulangi langkah 3',
    ),
  ],
  rescueTitle: 'Opsi penyelamatan: stek daun sehat',
  rescueText:
      'Jika sebagian besar daun sudah terinfeksi, ambil daun yang masih '
      'sehat, potong, keringkan 1–3 hari, lalu tanam sebagai stek.',
);

const _Protocol _leafWithering = _Protocol(
  severity: 'Perlu perhatian · Segera periksa',
  estimate:
      'Estimasi: ±30 menit untuk penanganan awal, lalu pantau 2–4 minggu. '
      'Mulai dari langkah 1 dan jangan melompat urutan.',
  supplies: [
    'Gunting/cutter steril',
    'Alkohol 70%',
    'Media tanam baru',
    'Pot bersih',
    'Pupuk NPK 10-10-10',
  ],
  steps: [
    _Step(
      title: 'Periksa media & akar',
      description:
          'Layu sering disebabkan media terlalu basah atau terlalu kering. '
          'Pastikan penyebabnya dulu.',
      tasks: [
        'Cek kelembapan media dengan jari sedalam 3–5 cm',
        'Keluarkan tanaman dari pot dan periksa akarnya',
        'Catat kondisi akar: putih kokoh atau cokelat lembek',
      ],
      tip: 'Akar sehat berwarna putih/kuning dan kokoh, tidak berbau.',
    ),
    _Step(
      title: 'Atasi akar busuk',
      description:
          'Akar yang busuk menyebar ke bagian lain bila tidak dibuang.',
      tasks: [
        'Sterilkan gunting dengan alkohol 70%',
        'Potong akar busuk sampai jaringan sehat',
        'Tanam ulang di pot bersih dengan media yang lebih porous',
      ],
      warning:
          'Tunda penyiraman sekitar 1 minggu setelah tanam ulang.',
    ),
    _Step(
      title: 'Atur cahaya & penyiraman',
      description:
          'Sansevieria tahan kering dan tidak menyukai media yang terus basah.',
      tasks: [
        'Tempatkan di cahaya tidak langsung yang cukup (bright indirect light)',
        'Sirami setiap 2–4 minggu sesuai kondisi lingkungan',
        'Hindari suhu ekstrem dan angin kencang langsung',
      ],
      tip: 'Siram hanya jika media sudah kering total.',
    ),
    _Step(
      title: 'Bantu pemulihan nutrisi',
      description: 'Beri nutrisi seimbang setelah tanaman mulai stabil.',
      tasks: [
        'Berikan pupuk NPK 10-10-10 setiap 2 bulan di musim tumbuh',
        'Gunakan dosis setengah dari anjuran label',
        'Pantau pertumbuhan daun baru sebagai tanda pulih',
      ],
      warning: 'Jangan memupuk saat akar masih dalam pemulihan.',
    ),
  ],
  meds: [
    _Med(
      name: 'Pupuk NPK seimbang',
      tag: 'Kimia',
      content: 'Nitrogen, fosfor, dan kalium dengan rasio 10-10-10.',
      usage: 'Larutkan setengah dosis, siram ke media setiap 2 bulan.',
      caution: 'Jangan berlebihan, dapat membakar akar yang lemah.',
    ),
    _Med(
      name: 'Kompos / pupuk organik',
      tag: 'Alami',
      content: 'Bahan organik yang memperbaiki struktur media.',
      usage: 'Campurkan tipis ke media tanam saat tanam ulang.',
      caution: 'Pendamping saja. Pastikan media tetap porous dan cepat kering.',
    ),
  ],
  monitoring: [
    _Monitor(
      day: 'Hari 3',
      check: 'Cek media & daun',
      good: 'media mulai kering, daun tidak melemas',
      bad: 'media tetap basah atau bau asam',
    ),
    _Monitor(
      day: 'Hari 7',
      check: 'Cek daun & media',
      good: 'daun kembali tegak',
      bad: 'daun makin lunak atau menguning',
    ),
    _Monitor(
      day: 'Hari 14',
      check: 'Cek pangkal daun',
      good: 'pangkal kokoh dan tegak',
      bad: 'pangkal lembek atau berbau',
    ),
    _Monitor(
      day: 'Hari 30',
      check: 'Evaluasi akhir',
      good: 'tunas atau daun baru muncul',
      bad: 'layu berlanjut: ulangi langkah 2',
    ),
  ],
  rescueTitle: 'Opsi penyelamatan: pisahkan anakan',
  rescueText:
      'Jika induk sulit dipulihkan, pisahkan anakan sehat beserta '
      'rimpangnya, keringkan 1–3 hari, lalu tanam di media baru.',
);