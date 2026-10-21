import 'package:flutter/material.dart';
import '../models/jadwal_item.dart';
import '../services/database_helper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────
class JadwalOtomatisCard extends StatefulWidget {
  const JadwalOtomatisCard({super.key});

  @override
  State<JadwalOtomatisCard> createState() => _JadwalOtomatisCardState();
}

class _JadwalOtomatisCardState extends State<JadwalOtomatisCard> {
  final _db = DatabaseHelper.instance;
  List<JadwalItem> _jadwalList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  // ── Database ops ───────────────────────────────────────────────────────────
  Future<void> _loadJadwal() async {
    final list = await _db.getAll();
    if (mounted) setState(() { _jadwalList = list; _loading = false; });
  }

  Future<void> _toggleJadwal(JadwalItem item, bool val) async {
    final updated = item.copyWith(isOn: val);
    await _db.update(updated);
    setState(() {
      final i = _jadwalList.indexWhere((j) => j.id == item.id);
      if (i != -1) _jadwalList[i] = updated;
    });
  }

  Future<void> _saveNew(JadwalItem item) async {
    final saved = await _db.insert(item);
    setState(() => _jadwalList
      ..add(saved)
      ..sort((a, b) => a.time.hour != b.time.hour
          ? a.time.hour.compareTo(b.time.hour)
          : a.time.minute.compareTo(b.time.minute)));
  }

  Future<void> _saveEdit(JadwalItem updated) async {
    await _db.update(updated);
    setState(() {
      final i = _jadwalList.indexWhere((j) => j.id == updated.id);
      if (i != -1) _jadwalList[i] = updated;
      _jadwalList.sort((a, b) => a.time.hour != b.time.hour
          ? a.time.hour.compareTo(b.time.hour)
          : a.time.minute.compareTo(b.time.minute));
    });
  }

  Future<void> _delete(JadwalItem item) async {
    await _db.delete(item.id!);
    setState(() => _jadwalList.removeWhere((j) => j.id == item.id));
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────
  void _openTambah() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JadwalSheet(
        title: 'Tambah Jadwal',
        onSave: _saveNew,
      ),
    );
  }

  void _openEdit(JadwalItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JadwalSheet(
        title: 'Edit Jadwal',
        initialTime: item.time,
        initialDays: Set.from(item.days),
        onSave: (edited) => _saveEdit(edited.copyWith(id: item.id, isOn: item.isOn)),
        onDelete: () => _confirmDelete(item),
      ),
    );
  }

  void _confirmDelete(JadwalItem item) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal?', style: AppTextStyles.cardTitle),
        content: Text(
          'Jadwal ${item.timeString} akan dihapus secara permanen.',
          style: AppTextStyles.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(item);
            },
            child: const Text('Hapus',
                style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text('Jadwal Otomatis Cerdas',
                    style: AppTextStyles.sectionTitle),
              ),
              GestureDetector(
                onTap: _openTambah,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.mintGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add,
                      color: AppColors.primaryGreen, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Konten ──────────────────────────────────────────────────────
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen, strokeWidth: 2),
              ),
            )
          else if (_jadwalList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Belum ada jadwal. Tekan + untuk menambahkan.',
                  style: AppTextStyles.hint,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._jadwalList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == _jadwalList.length - 1;
              return Column(
                children: [
                  _buildRow(item),
                  if (!isLast)
                    const Divider(
                        height: 24, thickness: 1, color: AppColors.sliderTrack),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRow(JadwalItem item) {
    return Row(
      children: [
        // Area tap untuk edit (ikon + teks saja)
        Expanded(
          child: InkWell(
            onTap: () => _openEdit(item),
            borderRadius: BorderRadius.circular(10),
            splashColor: AppColors.mintGreen,
            highlightColor: AppColors.mintGreen.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule,
                        color: AppColors.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.timeString, style: AppTextStyles.scheduleTime),
                      const SizedBox(height: 2),
                      Text(item.subtitle, style: AppTextStyles.cardSubtitle),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Switch di luar InkWell agar tidak tertangkap gesture-nya
        Switch(
          value: item.isOn,
          onChanged: (val) => _toggleJadwal(item, val),
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.toggleActive,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.toggleInactive,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable bottom sheet — Tambah & Edit
// ─────────────────────────────────────────────────────────────────────────────
class _JadwalSheet extends StatefulWidget {
  final String title;
  final TimeOfDay? initialTime;
  final Set<int>? initialDays;
  final void Function(JadwalItem) onSave;
  final VoidCallback? onDelete;

  const _JadwalSheet({
    required this.title,
    required this.onSave,
    this.initialTime,
    this.initialDays,
    this.onDelete,
  });

  @override
  State<_JadwalSheet> createState() => _JadwalSheetState();
}

class _JadwalSheetState extends State<_JadwalSheet> {
  late TimeOfDay _time;
  late Set<int> _days;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime ?? TimeOfDay.now();
    _days = widget.initialDays != null
        ? Set.from(widget.initialDays!)
        : {0, 1, 2, 3, 4, 5, 6};
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeString {
    final h = _time.hour.toString().padLeft(2, '0');
    final m = _time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _formattedDays {
    if (_days.length == 7) return 'Setiap hari';
    if (_days.isEmpty) return 'Pilih minimal satu hari';
    final sorted = _days.toList()..sort();
    return sorted.map((d) => _dayLabels[d]).join(', ');
  }

  void _save() {
    // Tutup sheet dulu, baru callback — agar setState di parent bisa berjalan
    // saat widget card masih mounted.
    Navigator.pop(context);
    widget.onSave(JadwalItem(time: _time, days: Set.from(_days), isOn: true));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.onDelete != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sliderTrack,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Judul + tombol hapus
          Row(
            children: [
              Expanded(
                  child: Text(widget.title, style: AppTextStyles.sectionTitle)),
              if (isEdit)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text('Hapus',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isEdit
                ? 'Ubah waktu atau hari penyiraman.'
                : 'Tentukan waktu dan hari penyiraman otomatis.',
            style: AppTextStyles.cardSubtitle,
          ),
          const SizedBox(height: 24),

          // Pilih Waktu
          const Text('Waktu', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: AppColors.primaryGreen, size: 22),
                  const SizedBox(width: 12),
                  Text(_timeString,
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 22,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: AppColors.primaryGreen, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pilih Hari
          const Text('Hari', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final selected = _days.contains(i);
              return GestureDetector(
                onTap: () => setState(() =>
                    selected ? _days.remove(i) : _days.add(i)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryGreen
                        : AppColors.mintGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.primaryGreen,
                        fontSize: 11,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(_formattedDays, style: AppTextStyles.hint),
          const SizedBox(height: 28),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _days.isEmpty ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor: AppColors.sliderTrack,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan Jadwal',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
