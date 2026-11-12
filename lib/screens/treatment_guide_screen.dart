import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/treatment_guides.dart';
import '../models/disease_result.dart';
import '../models/treatment_guide.dart';
import '../theme/app_colors.dart';

// =============================================================================
// TREATMENT GUIDE SCREEN
// =============================================================================

/// Layar penuh panduan pengobatan & penyelamatan tanaman.
/// Data konten dibaca dari [TreatmentGuides] (lib/data/treatment_guides.dart).
class TreatmentGuideScreen extends StatelessWidget {
  final DiseaseResult result;
  const TreatmentGuideScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final guide = TreatmentGuides.forLabel(result.label);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _GuideTopBar(result: result, guide: guide),
            Expanded(
              child: guide == null
                  ? _HealthyPlaceholder(result: result)
                  : _GuideBody(result: result, guide: guide),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _GuideTopBar extends StatelessWidget {
  final DiseaseResult result;
  final TreatmentGuide? guide;
  const _GuideTopBar({required this.result, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul + tombol kembali ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'Protokol Penyelamatan Daun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Tab + urgensi chip ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Row(
              children: [
                // Tab aktif
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.displayName,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Urgensi chip — Flexible agar tidak overflow
                if (guide != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _urgencyBg(guide!.urgency),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        guide!.urgencyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _urgencyFg(guide!.urgency),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _urgencyBg(GuideUrgency u) {
    switch (u) {
      case GuideUrgency.urgent:
        return const Color(0xFFFFF1F2);
      case GuideUrgency.diagnose:
        return const Color(0xFFFFFBEB);
    }
  }

  static Color _urgencyFg(GuideUrgency u) {
    switch (u) {
      case GuideUrgency.urgent:
        return const Color(0xFF991B1B);
      case GuideUrgency.diagnose:
        return const Color(0xFF92400E);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder tanaman sehat
// ─────────────────────────────────────────────────────────────────────────────
class _HealthyPlaceholder extends StatelessWidget {
  final DiseaseResult result;
  const _HealthyPlaceholder({required this.result});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Color(0xFF16A34A)),
            const SizedBox(height: 16),
            const Text(
              'Tanaman Sehat',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada panduan pengobatan yang diperlukan.\n'
              'Lanjutkan perawatan rutin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            if (result.confidenceLevel == ConfidenceLevel.low) ...[
              const SizedBox(height: 20),
              _LowConfidenceBanner(result: result),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body utama panduan
// ─────────────────────────────────────────────────────────────────────────────
class _GuideBody extends StatelessWidget {
  final DiseaseResult result;
  final TreatmentGuide guide;
  const _GuideBody({required this.result, required this.guide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Low-confidence warning
          if (result.confidenceLevel == ConfidenceLevel.low) ...[
            _LowConfidenceBanner(result: result),
            const SizedBox(height: 12),
          ],

          // 1. Intro + judul
          _IntroCard(guide: guide),
          const SizedBox(height: 12),

          // 2. Siapkan bahan
          _MaterialsCard(materials: guide.materials),
          const SizedBox(height: 12),

          // 3. Langkah-langkah
          for (var i = 0; i < guide.steps.length; i++) ...[
            _StepCard(stepNumber: i + 1, step: guide.steps[i], guide: guide),
            const SizedBox(height: 10),
          ],

          // 4. Rekomendasi obat
          _MedicineSection(guide: guide),
          const SizedBox(height: 10),

          // 5. Tidak terbukti
          if (guide.notProven != null) ...[
            _NotProvenCard(text: guide.notProven!),
            const SizedBox(height: 10),
          ],

          // 6. Pemantauan
          _MonitoringSection(entries: guide.monitoring),
          const SizedBox(height: 10),

          // 7. Opsi penyelamatan
          if (guide.rescue != null) ...[
            _RescueCard(rescue: guide.rescue!, guide: guide),
            const SizedBox(height: 10),
          ],

          // 8. Sumber referensi
          _SourcesSection(guide: guide),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Intro card
// ─────────────────────────────────────────────────────────────────────────────
class _IntroCard extends StatelessWidget {
  final TreatmentGuide guide;
  const _IntroCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            guide.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            guide.subtitle,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            guide.intro,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Siapkan bahan
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialsCard extends StatelessWidget {
  final List<String> materials;
  const _MaterialsCard({required this.materials});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_outlined,
                  size: 16, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Siapkan dulu',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: materials
                .map((m) => _PrepChip(label: m))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PrepChip extends StatelessWidget {
  final String label;
  const _PrepChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mintGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 13, color: AppColors.primaryGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Step card
// ─────────────────────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final int stepNumber;
  final GuideStep step;
  final TreatmentGuide guide;
  const _StepCard(
      {required this.stepNumber, required this.step, required this.guide});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nomor bulat
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Deskripsi ─────────────────────────────────────────────────────
          Text(
            step.description,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // ── Item checklist ────────────────────────────────────────────────
          for (final item in step.items) _ChecklistItem(text: item),

          // ── Tip ───────────────────────────────────────────────────────────
          if (step.tip != null) ...[
            const SizedBox(height: 8),
            _InfoBox(
              text: step.tip!,
              icon: Icons.lightbulb_outline,
              bg: const Color(0xFFEFF6FF),
              border: const Color(0xFFBFDBFE),
              fg: const Color(0xFF1D4ED8),
            ),
          ],

          // ── Warning ───────────────────────────────────────────────────────
          if (step.warning != null) ...[
            const SizedBox(height: 8),
            _InfoBox(
              text: step.warning!,
              icon: Icons.warning_amber_rounded,
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              fg: const Color(0xFF92400E),
            ),
          ],

          // ── Source badges ─────────────────────────────────────────────────
          if (step.sourceIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SourceBadges(ids: step.sourceIds, guide: guide),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String text;
  const _ChecklistItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border:
                  Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bg, border, fg;
  const _InfoBox({
    required this.text,
    required this.icon,
    required this.bg,
    required this.border,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.45,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Rekomendasi obat
// ─────────────────────────────────────────────────────────────────────────────
class _MedicineSection extends StatelessWidget {
  final TreatmentGuide guide;
  const _MedicineSection({required this.guide});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.local_pharmacy_outlined,
                  size: 16, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Rekomendasi Bahan / Obat',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Catatan (opsional)
          if (guide.medicinesNote != null) ...[
            Text(
              guide.medicinesNote!,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 1),
          // Item obat
          for (final med in guide.medicines) ...[
            const SizedBox(height: 10),
            _MedicineItem(med: med, guide: guide),
          ],
        ],
      ),
    );
  }
}

class _MedicineItem extends StatelessWidget {
  final MedicineItem med;
  final TreatmentGuide guide;
  const _MedicineItem({required this.med, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama + tag
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  med.tag,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Bahan aktif
          _MedRow(
              icon: Icons.science_outlined,
              text: med.ingredient,
              color: AppColors.textSecondary),
          const SizedBox(height: 4),
          // Cara pakai
          _MedRow(
              icon: Icons.info_outline,
              text: med.usage,
              color: AppColors.textSecondary),
          // Warning — tampilkan hanya jika tidak kosong
          if (med.warning.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoBox(
              text: med.warning,
              icon: Icons.warning_amber_rounded,
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              fg: const Color(0xFF92400E),
            ),
          ],
          // Source badges
          if (med.sourceIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _SourceBadges(ids: med.sourceIds, guide: guide),
          ],
        ],
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MedRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              height: 1.4,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Tidak terbukti
// ─────────────────────────────────────────────────────────────────────────────
class _NotProvenCard extends StatelessWidget {
  final String text;
  const _NotProvenCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.block_outlined, size: 15, color: Color(0xFFEA580C)),
              SizedBox(width: 6),
              Text(
                'Tidak direkomendasikan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF7C2D12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Pemantauan
// ─────────────────────────────────────────────────────────────────────────────
class _MonitoringSection extends StatelessWidget {
  final List<MonitorEntry> entries;
  const _MonitoringSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline_outlined,
                  size: 16, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Jadwal pemantauan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < entries.length; i++) ...[
            _MonitorRow(entry: entries[i], isLast: i == entries.length - 1),
          ],
        ],
      ),
    );
  }
}

class _MonitorRow extends StatelessWidget {
  final MonitorEntry entry;
  final bool isLast;
  const _MonitorRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline garis + titik
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label hari
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      entry.day,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Good / bad
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 13, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.good,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel_outlined,
                          size: 13, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.bad,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Rescue card
// ─────────────────────────────────────────────────────────────────────────────
class _RescueCard extends StatelessWidget {
  final RescueOption rescue;
  final TreatmentGuide guide;
  const _RescueCard({required this.rescue, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.emergency_outlined,
                    size: 16, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rescue.title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rescue.description,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF7F1D1D),
            ),
          ),
          if (rescue.sourceIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SourceBadges(ids: rescue.sourceIds, guide: guide),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Sumber referensi
// ─────────────────────────────────────────────────────────────────────────────
class _SourcesSection extends StatelessWidget {
  final TreatmentGuide guide;
  const _SourcesSection({required this.guide});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.menu_book_outlined,
                  size: 16, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Sumber Referensi',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final src in guide.sources) _SourceRow(src: src),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final GuideSource src;
  const _SourceRow({required this.src});

  Future<void> _launch() async {
    final uri = Uri.parse(src.url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID badge
          Container(
            width: 28,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              src.id,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _launch,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    src.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    src.publisher,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source badges (inline di dalam step/obat)
// ─────────────────────────────────────────────────────────────────────────────
class _SourceBadges extends StatelessWidget {
  final List<String> ids;
  final TreatmentGuide guide;
  const _SourceBadges({required this.ids, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: ids.map((id) {
        final src = guide.sourceById(id);
        return GestureDetector(
          onTap: src == null
              ? null
              : () async {
                  final uri = Uri.parse(src.url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Text(
              id,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Low confidence banner
// ─────────────────────────────────────────────────────────────────────────────
class _LowConfidenceBanner extends StatelessWidget {
  final DiseaseResult result;
  const _LowConfidenceBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keyakinan model rendah (${result.confidencePercent}). '
              'Panduan ini bersifat informatif. Pastikan kondisi daun secara '
              'langsung sebelum mengambil tindakan.',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable card
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
