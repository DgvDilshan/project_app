import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class GatekeeperService {
  static Interpreter? _interpreter;
  static bool _isInitializing = false;

  /// Initializes the custom Gatekeeper TFLite model.
  static Future<void> _initModel() async {
    if (_interpreter != null) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/models/gatekeeper_model.tflite',
        options: options,
      );
      debugPrint('GatekeeperService: Custom model loaded successfully.');
    } catch (e) {
      debugPrint('Error loading Gatekeeper model: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Validates whether the given image bytes represent a tea leaf using the custom TFLite model.
  static Future<bool> isLikelyPlantOrLeaf(Uint8List bytes) async {
    await _initModel();

    if (_interpreter == null) {
      debugPrint('GatekeeperService: Interpreter not initialized. Failing open.');
      return true; // Fallback to allow inference if model fails to load
    }

    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('GatekeeperService: Failed to decode image.');
        return false;
      }

      // MobileNetV2 requires 224x224 input
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Preprocess input: MobileNetV2 expects values in range [-1, 1]
      var inputBuffer = List.generate(
        1,
        (i) => List.generate(
          224,
          (y) => List.generate(224, (x) {
            var pixel = resizedImage.getPixel(x, y);
            double r = (pixel.r.toDouble() / 127.5) - 1.0;
            double g = (pixel.g.toDouble() / 127.5) - 1.0;
            double b = (pixel.b.toDouble() / 127.5) - 1.0;
            return [r, g, b];
          }),
        ),
      );

      var outputBuffer = List.generate(1, (_) => List<double>.filled(1, 0.0));

      _interpreter!.run(inputBuffer, outputBuffer);

      double teaLeafProbability = outputBuffer[0][0];
      debugPrint('GatekeeperService: Tea Leaf Probability = $teaLeafProbability');

      // Class 0: not_tea_leaf
      // Class 1: tea_leaf
      // Using a highly strict threshold (0.92) because the TFLite model tends to output
      // high probabilities (0.7-0.9) for very green objects like mango leaves or mantises.
      if (teaLeafProbability >= 0.92) {
        return true; // Confidently a tea leaf!
      } else {
        return false; // Reject: likely mango leaf, insect, person, or generic leaf
      }
    } catch (e) {
      debugPrint('Error during Gatekeeper inference: $e');
      return true; // Fallback
    }
  }
}
