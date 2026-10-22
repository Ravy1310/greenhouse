import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tflite_service.dart';
import '../theme/app_colors.dart';
import 'hasil_deteksi_screen.dart';

class DeteksiScreen extends StatefulWidget {
  const DeteksiScreen({super.key});

  @override
  State<DeteksiScreen> createState() => _DeteksiScreenState();
}

class _DeteksiScreenState extends State<DeteksiScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _permissionDenied = false;

  /// true saat sedang menjalankan inferensi model
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    // Muat model di background agar siap saat user menekan capture
    TfliteService.instance.load().catchError(
      (e) => debugPrint('[TFLite] Gagal memuat model: $e'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(ctrl.description);
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _initCameraController(_cameras.first);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription desc) async {
    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;
    try {
      await ctrl.initialize();
      await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Controller init error: $e');
    }
  }

  // ── Capture + Analisis ───────────────────────────────────────────────────

  Future<void> _captureAndAnalyze() async {
    final ctrl = _controller;
    if (ctrl == null ||
        !ctrl.value.isInitialized ||
        ctrl.value.isTakingPicture ||
        _isAnalyzing) {
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final xFile = await ctrl.takePicture();
      await _runAnalysis(File(xFile.path));
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;

    setState(() => _isAnalyzing = true);
    await _runAnalysis(File(xFile.path));
  }

  /// Jalankan TFLite inference lalu navigasi ke layar hasil
  Future<void> _runAnalysis(File imageFile) async {
    try {
      final result = await TfliteService.instance.classify(imageFile);

      if (!mounted) return;

      // Navigasi ke layar hasil — kamera tetap berjalan di background
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HasilDeteksiScreen(
            imageFile: imageFile,
            result: result,
            plantName: 'Sansevieria',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[TFLite] Analisis gagal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analisis gagal: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navBarSpace = MediaQuery.of(context).padding.bottom + 84;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2018),
      body: Stack(
        children: [
          // ── Kamera memenuhi seluruh layar ──────────────────────────────
          Positioned.fill(child: _buildFullScreenCamera()),

          // ── Overlay UI di atas kamera ───────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Viewfinder brackets
                Expanded(child: _buildViewfinderOverlay()),

                const SizedBox(height: 12),

                // Bottom controls
                _BottomControls(
                  onCapture: _captureAndAnalyze,
                  onGallery: _pickFromGallery,
                  isAnalyzing: _isAnalyzing,
                ),
                SizedBox(height: navBarSpace),
              ],
            ),
          ),

          // ── Loading overlay selama inferensi ────────────────────────────
          if (_isAnalyzing) _AnalyzingOverlay(),
        ],
      ),
    );
  }

  Widget _buildFullScreenCamera() {
    final ctrl = _controller;

    if (_permissionDenied) {
      return const _CameraPlaceholder(
        icon: Icons.no_photography_outlined,
        message: 'Izin kamera ditolak.\nBuka Pengaturan untuk mengaktifkan.',
      );
    }

    if (!_isInitialized || ctrl == null) {
      return const _CameraPlaceholder(
        icon: Icons.camera_alt_outlined,
        message: 'Memulai kamera...',
        showLoader: true,
      );
    }

    // Live preview — cover sizing agar tidak gepeng
    final rawRatio = ctrl.value.aspectRatio;
    final sensor = ctrl.description.sensorOrientation;
    final isRotated = sensor == 90 || sensor == 270;
    final cameraRatio = isRotated ? 1 / rawRatio : rawRatio;

    return LayoutBuilder(builder: (context, constraints) {
      final containerRatio = constraints.maxWidth / constraints.maxHeight;
      final double coverW;
      final double coverH;
      if (cameraRatio > containerRatio) {
        coverH = constraints.maxHeight;
        coverW = constraints.maxHeight * cameraRatio;
      } else {
        coverW = constraints.maxWidth;
        coverH = constraints.maxWidth / cameraRatio;
      }
      return ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: SizedBox(
            width: coverW,
            height: coverH,
            child: CameraPreview(ctrl),
          ),
        ),
      );
    });
  }

  Widget _buildViewfinderOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // Corner brackets hijau
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ),

          // Label instruksi di bawah viewfinder
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Arahkan kamera ke daun tanaman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analyzing overlay — ditampilkan saat inferensi berjalan
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyzingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryGreen,
              strokeWidth: 3,
            ),
            SizedBox(height: 18),
            Text(
              'Menganalisis gambar...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewfinder Corner Brackets
// ─────────────────────────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 30.0;
    const r = 10.0;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - r)
        ..arcToPoint(Offset(r, h), radius: const Radius.circular(r))
        ..lineTo(len, h),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - r, h)
        ..arcToPoint(Offset(w, h - r), radius: const Radius.circular(r))
        ..lineTo(w, h - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Placeholder
// ─────────────────────────────────────────────────────────────────────────────
class _CameraPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showLoader;

  const _CameraPlaceholder({
    required this.icon,
    required this.message,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D2018),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoader)
              const CircularProgressIndicator(color: AppColors.primaryGreen)
            else
              Icon(icon, color: AppColors.mutedGreen, size: 52),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedGreen,
                fontSize: 13,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Controls
// ─────────────────────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final bool isAnalyzing;

  const _BottomControls({
    required this.onCapture,
    required this.onGallery,
    required this.isAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Galeri
              _CircleIconButton(
                icon: Icons.image_outlined,
                onTap: isAnalyzing ? null : onGallery,
                tooltip: 'Galeri',
              ),

              // Capture
              GestureDetector(
                onTap: isAnalyzing ? null : onCapture,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAnalyzing
                        ? AppColors.mutedGreen
                        : AppColors.primaryGreen,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: isAnalyzing
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),

              // Riwayat (placeholder)
              _CircleIconButton(
                icon: Icons.history,
                onTap: isAnalyzing ? null : () {},
                tooltip: 'Riwayat',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pindai · Galeri · Riwayat',
          style: TextStyle(
            color: AppColors.mutedGreen,
            fontSize: 12,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: onTap != null ? 0.1 : 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: onTap != null ? 1.0 : 0.4),
            size: 22,
          ),
        ),
      ),
    );
  }
}
