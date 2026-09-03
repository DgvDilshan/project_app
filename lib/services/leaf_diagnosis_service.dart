import 'dart:math';

import '../models/diagnosis_result.dart';
import '../models/picked_image.dart';
import 'ml_service.dart';
import 'gatekeeper_service.dart';

abstract class LeafDiagnosisService {
  Future<DiagnosisResult> diagnose(PickedImage image);
}

class NotTeaLeafException implements Exception {
  final String message;
  NotTeaLeafException(this.message);
}

class RealLeafDiagnosisService implements LeafDiagnosisService {
  final MLService _mlService = MLService();
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      await _mlService.initialize();
      _initialized = true;
    }
  }

  @override
  Future<DiagnosisResult> diagnose(PickedImage image) async {
    await init();

    // Use GatekeeperService to filter out insects, animals, etc.
    final isLikelyLeaf = await GatekeeperService.isLikelyPlantOrLeaf(image.bytes);
    if (!isLikelyLeaf) {
      throw NotTeaLeafException(
        'Not a valid tea leaf. Please upload a clear picture of a tea leaf.',
      );
    }

    // final isTeaLeaf = await _mlService.isTeaLeaf(image.bytes);
    // if (!isTeaLeaf) {
    //   throw NotTeaLeafException(
    //     'Not a valid tea leaf. Please upload a clear picture of a tea leaf.',
    //   );
    // }

    final result = await _mlService.predictDisease(image.bytes);
    if (result == null) {
      throw Exception('Failed to predict disease.');
    }

    if (result['isLeaf'] == false) {
      throw NotTeaLeafException('NON-LEAF OBJECT DETECTED\n\nImage lacks sufficient green color.\nPlease upload a valid tea leaf.');
    }

    final diseaseName = result['disease'] as String;
    final confidence = result['confidence'] as double;

    TeaLeafDisease mappedDisease;
    if (diseaseName == 'Blister_Blight') {
      mappedDisease = TeaLeafDisease.blisterBlight;
    } else if (diseaseName == 'Healthy_leaves') {
      mappedDisease = TeaLeafDisease.healthy;
    } else {
      mappedDisease = TeaLeafDisease.unknown; // "Other disease"
    }

    if (confidence < 0.50) {
      return DiagnosisResult(
        disease: TeaLeafDisease.unknown,
        confidence: confidence,
        severity: SeverityLevel.medium,
        suggestions: [
          'UNCERTAIN PATHOLOGY: Confidence (${(confidence * 100).toStringAsFixed(1)}%) is below 50% threshold.',
          'Please take a clearer, closer photo of the leaf.'
        ],
        referenceImageUrl: null,
      );
    }

    SeverityLevel severity = mappedDisease == TeaLeafDisease.healthy
        ? SeverityLevel.low
        : mappedDisease == TeaLeafDisease.blisterBlight
        ? SeverityLevel.high
        : SeverityLevel.medium;

    return DiagnosisResult(
      disease: mappedDisease,
      confidence: confidence,
      severity: severity,
      suggestions: _suggestionsFor(mappedDisease, severity),
      referenceImageUrl: null,
    );
  }

  List<String> _suggestionsFor(TeaLeafDisease disease, SeverityLevel severity) {
    final base = <String>[
      'Remove and dispose infected leaves (do not compost).',
      'Improve airflow: prune lightly and avoid overcrowding.',
      'Avoid wetting leaves late evening; water early morning.',
      'Monitor the same area again in 3–5 days.',
    ];

    return switch (disease) {
      TeaLeafDisease.healthy => <String>[
        'Leaf looks healthy — keep regular field monitoring.',
        'Maintain balanced nutrition and avoid water stress.',
        'If symptoms appear, scan again with a closer photo.',
      ],
      TeaLeafDisease.blisterBlight => <String>[
        'Blister blight suspected — isolate the affected section.',
        'Apply copper-based fungicides immediately.',
        'Remove heavily infected shoots and leaves.',
        'Keep plucking rounds timely to reduce spread.',
        ...base,
      ],
      TeaLeafDisease.greyBlight => <String>[
        'Grey blight suspected — reduce shade if too dense.',
        'Collect and dispose fallen infected leaves.',
        ...base,
      ],
      TeaLeafDisease.redRust => <String>[
        'Red rust suspected — check for nutritional stress.',
        'Ensure adequate drainage and avoid waterlogging.',
        ...base,
      ],
      TeaLeafDisease.algalLeafSpot => <String>[
        'Algal leaf spot suspected — improve drainage and airflow.',
        'Avoid prolonged leaf wetness in the field.',
        ...base,
      ],
      TeaLeafDisease.unknown => <String>[
        'Other disease suspected — apply general broad-spectrum control.',
        'Take a sharper, closer photo for better accuracy.',
        'If severe, consult a field officer/agronomist.',
      ],
    };
  }
}
