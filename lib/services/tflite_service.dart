import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/disease_result.dart';

/// Argumen untuk preprocessing di isolate terpisah.
class _PreArgs {
  final String path;
  final int size;
  const _PreArgs(this.path, this.size);
}

/// Decode + perbaiki rotasi EXIF + resize + ubah ke Float32 (RGB, 0–255).
/// Berjalan di isolate agar UI tidak macet saat memproses foto beresolusi besar.
///
/// Harus identik dengan training: resize bilinear TANPA crop (gambar dipepatkan
/// ke size x size), nilai piksel 0–255, tanpa normalisasi (preprocessing sudah
/// ada di dalam model).
Float32List _preprocess(_PreArgs a) {
  final bytes = File(a.path).readAsBytesSync();
  var image = img.decodeImage(bytes);
  if (image == null) throw Exception('Gambar tidak dapat dibaca');
  image = img.bakeOrientation(image);

  final resized = img.copyResize(
    image,
    width: a.size,
    height: a.size,
    interpolation: img.Interpolation.linear,
  );

  final out = Float32List(a.size * a.size * 3);
  var k = 0;
  for (var y = 0; y < a.size; y++) {
    for (var x = 0; x < a.size; x++) {
      final p = resized.getPixel(x, y);
      out[k++] = p.r.toDouble();
      out[k++] = p.g.toDouble();
      out[k++] = p.b.toDouble();
    }
  }
  return out;
}

class TfliteService {
  TfliteService._();
  static final TfliteService instance = TfliteService._();

  // Pastikan path ini sama dengan lokasi file di project dan terdaftar di
  // pubspec.yaml (flutter: assets: - assets/models/)
  static const _modelAsset = 'assets/models/sansevieria_model.tflite';
  static const _metaAsset = 'assets/models/meta.json';

  Interpreter? _interpreter;
  late List<String> _classes;
  late int _size;
  String? _negClass;
  double _threshold = 0.0;
  Future<void>? _loading;

  /// Aman dipanggil berkali-kali; model hanya dimuat sekali.
  Future<void> load() => _loading ??= _loadOnce();

  Future<void> _loadOnce() async {
    try {
      final meta = jsonDecode(await rootBundle.loadString(_metaAsset))
          as Map<String, dynamic>;
      _classes = List<String>.from(meta['class_names'] as List);
      _size = (meta['img_size'] as num).toInt();
      _negClass = meta['neg_class'] as String?; // opsional
      _threshold = (meta['conf_threshold'] as num?)?.toDouble() ?? 0.0; // opsional

      final interpreter = await Interpreter.fromAsset(_modelAsset);

      // Cek dini: model dan meta.json harus cocok.
      final inShape = interpreter.getInputTensor(0).shape; // [1, size, size, 3]
      final outShape = interpreter.getOutputTensor(0).shape; // [1, jumlahKelas]
      if (inShape.length != 4 || inShape[1] != _size || inShape[2] != _size) {
        throw Exception('Ukuran input model $inShape tidak cocok dengan meta.json ($_size).');
      }
      if (outShape.last != _classes.length) {
        throw Exception(
            'Jumlah keluaran model ($outShape) tidak cocok dengan ${_classes.length} kelas di meta.json.');
      }

      _interpreter = interpreter;
      debugPrint('[TFLite] Model dimuat: $_classes | input $inShape | output $outShape '
          '| neg=$_negClass | ambang=$_threshold');
    } catch (e) {
      _loading = null; // izinkan percobaan ulang
      rethrow;
    }
  }

  /// Klasifikasi satu foto. Selalu mengembalikan probabilitas semua kelas.
  Future<DiseaseResult> classify(File file) async {
    await load();
    final interpreter = _interpreter!;

    final input = await compute(_preprocess, _PreArgs(file.path, _size));

    final n = _classes.length;
    final output = List.filled(n, 0.0).reshape([1, n]);
    interpreter.run(input.reshape([1, _size, _size, 3]), output);

    final probs =
        (output[0] as List).map((e) => (e as num).toDouble()).toList();
    return _toResult(probs);
  }

  DiseaseResult _toResult(List<double> probs) {
    final scores = <ClassScore>[
      for (var i = 0; i < probs.length; i++)
        ClassScore(DiseaseResult.labelFromString(_classes[i]), probs[i]),
    ]..sort((a, b) => b.probability.compareTo(a.probability));

    var top = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[top]) top = i;
    }
    final topName = _classes[top];
    final conf = probs[top];

    var label = DiseaseResult.labelFromString(topName);
    var uncertain = false;
    if (_negClass != null && topName == _negClass) {
      label = DiseaseLabel.notSansevieria; // model sendiri memilih "bukan daun"
    } else if (conf < _threshold) {
      label = DiseaseLabel.notSansevieria; // keyakinan di bawah ambang
      uncertain = true;
    }

    final negIdx = _negClass == null ? -1 : _classes.indexOf(_negClass!);
    return DiseaseResult(
      label: label,
      confidence: conf,
      uncertain: uncertain,
      pNeg: negIdx >= 0 ? probs[negIdx] : null,
      scores: scores,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loading = null;
  }
}
