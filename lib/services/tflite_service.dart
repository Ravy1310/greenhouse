import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/disease_result.dart';

/// Ukuran input model (224×224 standar MobileNet-based models)
const int _kInputSize = 224;

class TfliteService {
  TfliteService._internal();
  static final TfliteService instance = TfliteService._internal();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Muat model dan label dari assets. Panggil sekali sebelum inferensi.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      // Load TFLite model dari assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/sansevieria_mobilenetv2.tflite',
      );

      // Bungkus dengan IsolateInterpreter agar inference tidak memblokir UI
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter!.address,
      );

      // Load label file
      final labelData =
          await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  // ── Inference ──────────────────────────────────────────────────────────────

  /// Jalankan klasifikasi pada [imageFile].
  /// Kembalikan [DiseaseResult] dengan label dan confidence tertinggi.
  Future<DiseaseResult> classify(File imageFile) async {
    if (!_isLoaded) await load();

    final isolateInterpreter = _isolateInterpreter!;

    // 1. Baca & resize gambar ke 224×224
    final rawBytes = await imageFile.readAsBytes();
    final original = img.decodeImage(rawBytes);
    if (original == null) throw Exception('Gagal mendekode gambar.');

    final resized = img.copyResize(
      original,
      width: _kInputSize,
      height: _kInputSize,
    );

    // 2. Bentuk tensor [1, 224, 224, 3] dengan nilai piksel asli 0–255 (float32).
    //    Model sudah meng-handle normalisasi secara internal.
    final input = _imageToInput(resized);

    // 3. Siapkan output buffer — [1, numLabels]
    final numLabels = _labels.length;
    final outputBuffer =
        List.generate(1, (_) => List.filled(numLabels, 0.0));

    // 4. Log input/output tensor shapes untuk debug
    if (kDebugMode) {
      final inputTensor  = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint('[TFLite] Input  tensor → shape: ${inputTensor.shape}, type: ${inputTensor.type}');
      debugPrint('[TFLite] Output tensor → shape: ${outputTensor.shape}, type: ${outputTensor.type}');
      debugPrint('[TFLite] Labels loaded  → $_labels');
      debugPrint('[TFLite] outputBuffer shape → [${outputBuffer.length}, ${outputBuffer[0].length}]');
    }

    // 4. Jalankan inferensi di isolate terpisah (tidak memblokir UI)
    await isolateInterpreter.run(input, outputBuffer);

    // 5. Ambil probabilitas dari output[0]
    final probabilities = List<double>.from(outputBuffer[0]);

    // DEBUG: cetak semua probabilitas ke console
    debugPrint('[TFLite] Raw probabilities:');
    for (int i = 0; i < probabilities.length; i++) {
      final lbl = i < _labels.length ? _labels[i] : 'idx$i';
      debugPrint('  [$i] $lbl = ${probabilities[i]}');
    }

    // 6. Cari indeks dengan nilai tertinggi
    int bestIdx = 0;
    double bestConf = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > bestConf) {
        bestConf = probabilities[i];
        bestIdx = i;
      }
    }

    debugPrint('[TFLite] → Best: idx=$bestIdx label=${_labels[bestIdx]} conf=$bestConf');

    final rawLabel =
        bestIdx < _labels.length ? _labels[bestIdx] : 'Unknown';
    final diseaseLabel = DiseaseResult.labelFromString(rawLabel);

    return DiseaseResult(
      label: diseaseLabel,
      confidence: bestConf,
      // Model adalah pure classifier — tidak ada koordinat bbox.
      boundingBox: null,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Konversi [img.Image] → nested list dengan shape [1, H, W, 3].
  /// Nilai piksel dikirim apa adanya sebagai float32 (0–255).
  /// Normalisasi dilakukan secara internal oleh model.
  List<List<List<List<double>>>> _imageToInput(img.Image image) {
    final h = image.height;
    final w = image.width;

    return List.generate(1, (_) {
      return List.generate(h, (y) {
        return List.generate(w, (x) {
          final pixel = image.getPixel(x, y);
          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        });
      });
    });
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _isolateInterpreter?.close();
    _interpreter?.close();
    _isolateInterpreter = null;
    _interpreter = null;
    _isLoaded = false;
  }
}
