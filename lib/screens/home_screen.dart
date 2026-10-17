import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/lora_header.dart';
import '../widgets/siram_manual_card.dart';
import '../widgets/jadwal_otomatis_card.dart';
import '../widgets/durasi_semprot_card.dart';
import '../widgets/kelembapan_riwayat_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'deteksi_screen.dart';
import 'info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Deteksi screen manages its own full-screen scaffold
    if (_currentNavIndex == 1) {
      return Stack(
        children: [
          DeteksiScreen(),
          // Overlay bottom nav so user can switch back
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              selectedIndex: _currentNavIndex,
              onTap: (index) => setState(() => _currentNavIndex = index),
              dark: true,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Fixed top header (only on Kontrol page)
          if (_currentNavIndex == 0) const LoraHeader(),

          Expanded(
            child: _currentNavIndex == 0
                ? const _KontrolPage()
                : const InfoScreen(),
          ),

          // Fixed bottom nav
          BottomNavBar(
            selectedIndex: _currentNavIndex,
            onTap: (index) => setState(() => _currentNavIndex = index),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kontrol page content
// ─────────────────────────────────────────────────────────────────────────────
class _KontrolPage extends StatelessWidget {
  const _KontrolPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: const [
        SiramManualCard(),
        JadwalOtomatisCard(),
        DurasiSemprotCard(),
        KelembapanRiwayatCard(),
        _RiwayatHint(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info page content
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPage extends StatelessWidget {
  const _InfoPage();

  @override
  Widget build(BuildContext context) {
    return const InfoScreen();
  }
}

class _RiwayatHint extends StatelessWidget {
  const _RiwayatHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Riwayat tersimpan lokal · SQLite',
          style: AppTextStyles.hint,
        ),
      ),
    );
  }
}
