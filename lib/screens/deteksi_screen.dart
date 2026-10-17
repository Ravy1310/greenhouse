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

  // Camera preview aspect ratio – stored so the captured photo can be
  // displayed with the same crop as the live preview (no zoom difference).
  double? _previewAspectRatio;

  // Sensor orientation (0/90/180/270). 90 or 270 means the preview is
  // rotated 90° on screen, so the on-screen aspect ratio is the inverse
  // of value.aspectRatio.
  int? _sensorOrientation;

  // Simulated detection state – in production replace with real ML
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
      _previewAspectRatio = ctrl.value.aspectRatio;
      _sensorOrientation = ctrl.description.sensorOrientation;
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Controller init error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || ctrl.value.isTakingPicture) {
      return;
    }
    try {
      final xFile = await ctrl.takePicture();
      setState(() {
        _capturedImage = File(xFile.path);
        _showDetection = true; // simulate detection result
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Bottom nav bar is overlaid via Stack in HomeScreen; reserve space so
    // the capture / gallery / history buttons are not hidden behind it.
    final navBarSpace = MediaQuery.of(context).padding.bottom + 84;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2018),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Status bar
            _StatusBar(
              lightOk: _isInitialized,
              distanceHint: _isInitialized ? null : 'Menginisialisasi...',
            ),

            // ── Hint chip
            const SizedBox(height: 16),
            _HintChip(
              label: _capturedImage != null
                  ? 'Hasil Deteksi'
                  : 'Arahkan ke Daun Sakit',
            ),
            const SizedBox(height: 16),

            // ── Camera / image area  ────────────────────────────────────────
            Expanded(
              child: _buildCameraArea(),
            ),

            // ── Bottom controls  ────────────────────────────────────────────
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
    );
  }

  Widget _buildCameraArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final ctrl = _controller;

      // Use the camera's preview aspect ratio for BOTH live preview and
      // captured image so they show the exact same crop — no zoom
      // difference between before and after taking a photo.
      //
      // value.aspectRatio is the sensor coordinate-space ratio (often
      // landscape, e.g. 1920/1080).  For back/front cameras with
      // sensorOrientation 90 or 270, the preview is rotated 90° on
      // screen, so the on-screen ratio is the INVERSE (portrait).
      final rawRatio = (ctrl != null && ctrl.value.isInitialized)
          ? ctrl.value.aspectRatio
          : (_previewAspectRatio ?? 3 / 4);

      final sensor = (ctrl != null && ctrl.value.isInitialized)
          ? ctrl.description.sensorOrientation
          : (_sensorOrientation ?? 90);

      final isRotated = sensor == 90 || sensor == 270;
      final cameraRatio = isRotated ? 1 / rawRatio : rawRatio;

      // Compute "cover" dimensions: fill the box while keeping the
      // camera's aspect ratio, overflowing the excess for ClipRRect.
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

      // Live preview or captured photo both use the cover-sized box.
      // Placeholders (loading / permission denied) fill the box directly.
      final hasContent = _capturedImage != null ||
          (ctrl != null && ctrl.value.isInitialized && !_permissionDenied);

      return Stack(
        alignment: Alignment.center,
        children: [
          // ── Camera preview / captured image ────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: hasContent
                  ? Center(
                      child: SizedBox(
                        width: coverW,
                        height: coverH,
                        child: _buildPreview(),
                      ),
                    )
                  : _buildPreview(),
            ),
          ),

          // ── Viewfinder corner brackets ──────────────────────────────────
          if (_capturedImage == null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),

          // ── Detection overlay (after capture) ──────────────────────────
          if (_showDetection && _capturedImage != null)
            Positioned(
              bottom: constraints.maxHeight * 0.28,
              left: constraints.maxWidth * 0.22,
              child: _DetectionBox(),
            ),
        ],
      );
    });
  }

  Widget _buildPreview() {
    // Show captured image
    if (_capturedImage != null) {
      return Image.file(
        _capturedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Permission denied
    if (_permissionDenied) {
      return const _CameraPlaceholder(
        icon: Icons.no_photography_outlined,
        message: 'Izin kamera ditolak.\nBuka Pengaturan untuk mengaktifkan.',
      );
    }

    // Not yet initialised
    if (!_isInitialized || _controller == null) {
      return const _CameraPlaceholder(
        icon: Icons.camera_alt_outlined,
        message: 'Memulai kamera...',
        showLoader: true,
      );
    }

    // Live camera preview (fallback – normally handled by _buildCameraArea)
    return CameraPreview(_controller!);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Bar
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final bool lightOk;
  final String? distanceHint;

  const _StatusBar({required this.lightOk, this.distanceHint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatusChip(
            color: lightOk
                ? const Color(0xFF4ADE80)
                : const Color(0xFFFBBF24),
            label: lightOk ? 'Cahaya: Baik' : 'Cahaya: Memeriksa',
          ),
          _StatusChip(
            color: const Color(0xFFFBBF24),
            label: distanceHint ?? 'Jarak: Dekatkan 10 cm',
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint Chip
// ─────────────────────────────────────────────────────────────────────────────
class _HintChip extends StatelessWidget {
  final String label;

  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
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
        ..arcToPoint(const Offset(r, 0),
            radius: const Radius.circular(r))
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
        ..arcToPoint(Offset(w, h - r),
            radius: const Radius.circular(r))
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
