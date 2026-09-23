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
      // 2. Prepare input tensor (1, 224, 224, 3) Float32
      // The MobileNetV2 model expects pixels to be in the range [-1, 1]
      const int inputSize = 224;
      var input = List.generate(1, (i) => List.generate(inputSize, (y) => List.generate(inputSize, (x) => List.filled(3, 0.0))));

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          // Normalize to [-1, 1]
          input[0][y][x][0] = (pixel.r / 127.5) - 1.0;
          input[0][y][x][1] = (pixel.g / 127.5) - 1.0;
          input[0][y][x][2] = (pixel.b / 127.5) - 1.0;
        }
      }

      // 3. Prepare output tensor (1, 1)
      var output = List.generate(1, (i) => List.filled(1, 0.0));

      // 4. Run inference
      _interpreter!.run(input, output);

      // 5. Interpret output
      // Class 0: not_tea_leaf, Class 1: tea_leaf (Sigmoid output)
      double teaLeafProbability = output[0][0];
      debugPrint('Gatekeeper: Tea leaf probability = $teaLeafProbability');

      // Use a balanced threshold (0.5). If we make it too high, diseased tea leaves might be rejected.
      return teaLeafProbability > 0.5;

    } catch (e) {
      debugPrint('Error running gatekeeper model: $e');
      return true; // Fallback
    }
  }
}
