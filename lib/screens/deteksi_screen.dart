import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';

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
  File? _capturedImage;

  bool _showDetection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
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

  Future<void> _capturePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.isTakingPicture) return;
    try {
      final xFile = await ctrl.takePicture();
      setState(() {
        _capturedImage = File(xFile.path);
        _showDetection = true;
      });
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null && mounted) {
      setState(() {
        _capturedImage = File(xFile.path);
        _showDetection = true;
      });
    }
  }

  void _reset() {
    setState(() {
      _capturedImage = null;
      _showDetection = false;
    });
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
          // ── Kamera / gambar memenuhi seluruh layar ──────────────────────
          Positioned.fill(
            child: _buildFullScreenCamera(),
          ),

          // ── Overlay UI di atas kamera ───────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Ruang kosong atas agar viewfinder tidak terlalu ke atas
                const SizedBox(height: 16),

                // ── Viewfinder brackets ditengah layar ──────────────────
                Expanded(
                  child: _buildViewfinderOverlay(),
                ),

                // ── Bottom controls ─────────────────────────────────────
                const SizedBox(height: 12),
                _BottomControls(
                  onCapture: _capturedImage != null ? _reset : _capturePhoto,
                  onGallery: _pickFromGallery,
                  isCaptured: _capturedImage != null,
                ),
                SizedBox(height: navBarSpace),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kamera / foto mengisi seluruh layar dengan BoxFit.cover
  Widget _buildFullScreenCamera() {
    final ctrl = _controller;

    // Gambar yang sudah diambil
    if (_capturedImage != null) {
      return Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Izin kamera ditolak
    if (_permissionDenied) {
      return const _CameraPlaceholder(
        icon: Icons.no_photography_outlined,
        message: 'Izin kamera ditolak.\nBuka Pengaturan untuk mengaktifkan.',
      );
    }

    // Kamera belum siap
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

  // Hanya corner brackets + detection overlay di atas kamera
  Widget _buildViewfinderOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // Corner brackets hijau
          if (_capturedImage == null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),

          // Detection overlay setelah foto
          if (_showDetection && _capturedImage != null)
            Positioned(
              bottom: constraints.maxHeight * 0.28,
              left: constraints.maxWidth * 0.22,
              child: const _DetectionBox(),
            ),
        ],
      );
    });
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
// Detection Overlay Box
// ─────────────────────────────────────────────────────────────────────────────
class _DetectionBox extends StatelessWidget {
  const _DetectionBox();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2.5),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Area infeksi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera Placeholder (loading / no permission)
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
  final bool isCaptured;

  const _BottomControls({
    required this.onCapture,
    required this.onGallery,
    required this.isCaptured,
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
                onTap: onGallery,
                tooltip: 'Galeri',
              ),

              // Capture / Reset
              GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCaptured
                        ? const Color(0xFF55645C)
                        : AppColors.primaryGreen,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    isCaptured ? Icons.refresh : Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // Riwayat
              _CircleIconButton(
                icon: Icons.history,
                onTap: () {},
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
  final VoidCallback onTap;
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
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
