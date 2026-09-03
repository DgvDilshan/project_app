import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class MLService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> initialize() async {
    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/hybrid_agrovision_model.tflite',
      );

      // Load labels
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      debugPrint(
        'MLService initialized successfully with ${_labels.length} labels.',
      );
    } catch (e) {
      debugPrint('Error initializing MLService: $e');
    }
  }

  double _calculateGreenRatio(img.Image image) {
    int totalPixels = image.width * image.height;
    int greenPixels = 0;

    for (var p in image) {
      num r = p.r;
      num g = p.g;
      num b = p.b;

      num maxC = [r, g, b].reduce((curr, next) => curr > next ? curr : next);
      num minC = [r, g, b].reduce((curr, next) => curr < next ? curr : next);
      num delta = maxC - minC;

      num h = 0;
      if (delta == 0) {
        h = 0;
      } else if (maxC == r) {
        h = 60 * (((g - b) / delta) % 6);
      } else if (maxC == g) {
        h = 60 * (((b - r) / delta) + 2);
      } else if (maxC == b) {
        h = 60 * (((r - g) / delta) + 4);
      }

      num s = maxC == 0 ? 0 : delta / maxC;
      num v = maxC;

      // Convert to OpenCV HSV ranges (H: 0-179, S: 0-255, V: 0-255)
      h = h / 2;
      s = s * 255;

      if (h >= 35 && h <= 85 && s >= 30 && v >= 30) {
        greenPixels++;
      }
    }

    return greenPixels / totalPixels;
  }

  Future<bool> isTeaLeaf(Uint8List bytes) async {
    return true; // Unused, we check in predictDisease
  }

  Future<Map<String, dynamic>?> predictDisease(Uint8List bytes) async {
    if (_interpreter == null) {
      debugPrint('Interpreter not initialized');
      return null;
    }

    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Get input tensor shape dynamically (e.g. [1, 224, 224, 3])
      var inputTensor = _interpreter!.getInputTensor(0);
      var inputShape = inputTensor.shape;
      var inputType = inputTensor.type;

      debugPrint('MLService Input Tensor: shape=$inputShape, type=$inputType');

      int height = inputShape.length > 1 ? inputShape[1] : 224;
      int width = inputShape.length > 2 ? inputShape[2] : 224;

      final resizedImage = img.copyResize(image, width: width, height: height);

      // --- NEW: Green Ratio Check ---
      double greenRatio = _calculateGreenRatio(resizedImage);
      debugPrint('MLService: Green ratio = $greenRatio');
      if (greenRatio < 0.05) {
        return {
          'disease': 'Not a tea leaf',
          'confidence': 0.0,
          'isLeaf': false,
        };
      }

      // Prepare input buffer dynamically based on tensor type
      var inputBuffer = _imageToBuffer(resizedImage, inputType);

      // Output tensor shape (e.g. [1, 3])
      var outputTensor = _interpreter!.getOutputTensor(0);
      var outputShape = outputTensor.shape;
      var outputType = outputTensor.type;

      debugPrint(
        'MLService Output Tensor: shape=$outputShape, type=$outputType',
      );

      // Run inference
      if (outputType == TensorType.uint8) {
        var outputBuffer = List.generate(
          outputShape[0],
          (_) => List<int>.filled(outputShape[1], 0),
        );
        _interpreter!.run(inputBuffer, outputBuffer);
        debugPrint('MLService Raw Output (Uint8): ${outputBuffer[0]}');
        return _processOutputUint8(outputBuffer[0]);
      } else {
        var outputBuffer = List.generate(
          outputShape[0],
          (_) => List<double>.filled(outputShape[1], 0.0),
        );
        _interpreter!.run(inputBuffer, outputBuffer);
        debugPrint('MLService Raw Output (Float32): ${outputBuffer[0]}');
        return _processOutputFloat32(outputBuffer[0]);
      }
    } catch (e) {
      debugPrint('Error during inference: $e');
      return null;
    }
  }

  Object _imageToBuffer(img.Image image, TensorType type) {
    if (type == TensorType.float32) {
      // Float32 buffer
      return List.generate(
        1,
        (i) => List.generate(
          image.height,
          (y) => List.generate(image.width, (x) {
            var pixel = image.getPixel(x, y);
            // PyTorch standard preprocessing: RGB, scale to [0,1], then normalize
            double r = pixel.r.toDouble() / 255.0;
            double g = pixel.g.toDouble() / 255.0;
            double b = pixel.b.toDouble() / 255.0;
            
            return [
              (r - 0.485) / 0.229,
              (g - 0.456) / 0.224,
              (b - 0.406) / 0.225,
            ];
          }),
        ),
      );
    } else {
      // Uint8 buffer
      return List.generate(
        1,
        (i) => List.generate(
          image.height,
          (y) => List.generate(image.width, (x) {
            var pixel = image.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          }),
        ),
      );
    }
  }

  Map<String, dynamic> _processOutputUint8(List<int> output) {
    int maxIndex = 0;
    int maxScore = 0;
    for (int i = 0; i < output.length; i++) {
      if (output[i] > maxScore) {
        maxScore = output[i];
        maxIndex = i;
      }
    }
    double confidence = maxScore / 255.0;
    return {
      'disease': _labels.length > maxIndex ? _labels[maxIndex] : 'Unknown',
      'confidence': confidence,
    };
  }

  Map<String, dynamic> _processOutputFloat32(List<double> output) {
    // 1. Calculate Softmax
    double maxLogit = output.reduce((a, b) => a > b ? a : b);
    double sum = 0.0;
    List<double> probs = [];
    for (double logit in output) {
      double p = exp(logit - maxLogit);
      probs.add(p);
      sum += p;
    }
    for (int i = 0; i < probs.length; i++) {
      probs[i] /= sum;
    }

    // 2. Find max probability
    int maxIndex = 0;
    double maxScore = 0.0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxScore) {
        maxScore = probs[i];
        maxIndex = i;
      }
    }
    
    return {
      'disease': _labels.length > maxIndex ? _labels[maxIndex] : 'Unknown',
      'confidence': maxScore,
    };
  }
}
