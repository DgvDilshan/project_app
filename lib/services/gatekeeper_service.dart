import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class GatekeeperService {
  /// Validates whether the given image bytes represent a plant or leaf.
  static Future<bool> isLikelyPlantOrLeaf(Uint8List bytes) async {
    // 1. Write bytes to a temporary file for ML Kit
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp_gatekeeper_image.jpg');
    await file.writeAsBytes(bytes);

    // 2. Prepare the ML Kit Image Labeler
    final inputImage = InputImage.fromFile(file);
    final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.25);
    final imageLabeler = ImageLabeler(options: options);

    try {
      // 3. Process the image
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
      
      bool isNature = false;

      for (ImageLabel label in labels) {
        final text = label.label.toLowerCase();
        
        // Whitelist: If it definitely sees nature/plant/agriculture, accept it.
        if (text.contains('plant') || 
            text.contains('leaf') || 
            text.contains('tree') || 
            text.contains('flower') || 
            text.contains('flora') ||
            text.contains('nature') ||
            text.contains('soil') ||
            text.contains('grass') ||
            text.contains('agriculture') ||
            text.contains('crop') ||
            text.contains('garden') ||
            text.contains('produce') ||
            text.contains('vegetation') ||
            text.contains('foliage') ||
            text.contains('organism') ||
            text.contains('botany')) {
          isNature = true;
          break; // Found a valid nature label, we can accept
        }
      }

      // 4. Cleanup and return
      imageLabeler.close();
      if (await file.exists()) {
        await file.delete();
      }

      return isNature; // Accept only if a nature-related label was found
    } catch (e) {
      debugPrint('Error in GatekeeperService: $e');
      imageLabeler.close();
      return true; // Accept: Fallback if ML kit fails
    }
  }
}
