import 'dart:math';

import '../models/diagnosis_result.dart';
import '../models/picked_image.dart';
import '../main.dart';
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
    bool isSinhala = isSinhalaMode.value;

    final base = isSinhala ? <String>[
      'රෝගී කොළ ඉවත් කර විනාශ කරන්න (කොම්පෝස්ට් වලට දාන්න එපා).',
      'සුළං ගමනාගමනය වැඩි කරන්න: ගස් ටිකක් කප්පාදු කරන්න.',
      'සවස කොළ තෙමීමෙන් වළකින්න; උදේ වරුවේ පමණක් වතුර දමන්න.',
      'දින 3–5 කින් නැවත පරීක්ෂා කරන්න.',
    ] : <String>[
      'Remove and dispose infected leaves (do not compost).',
      'Improve airflow: prune lightly and avoid overcrowding.',
      'Avoid wetting leaves late evening; water early morning.',
      'Monitor the same area again in 3–5 days.',
    ];

    return switch (disease) {
      TeaLeafDisease.healthy => isSinhala ? <String>[
        'කොළය නිරෝගීයි — සාමාන්‍ය පරීක්ෂාවන් දිගටම කරගෙන යන්න.',
        'පොහොර නිසි පරිදි ලබා දී ජල හිඟයක් ඇතිවීම වළක්වාගන්න.',
        'යම් වෙනසක් දුටුවහොත්, වඩාත් පැහැදිලි ඡායාරූපයක් ලබාගෙන නැවත පරීක්ෂා කරන්න.',
      ] : <String>[
        'Leaf looks healthy — keep regular field monitoring.',
        'Maintain balanced nutrition and avoid water stress.',
        'If symptoms appear, scan again with a closer photo.',
      ],
      TeaLeafDisease.blisterBlight => isSinhala ? <String>[
        'බ්ලිස්ටර් බ්ලයිට් (Blister Blight) රෝගය බවට සැක කෙරේ — රෝගී කොටස් වෙන් කරන්න.',
        'රසායනික ප්‍රතිකාර හෝ දිලීර නාශක යෙදීම සඳහා කරුණාකර සුදුසුකම් ලත් කෘෂි නිලධාරියෙකුගේ (Field Officer) උපදෙස් ලබාගන්න.',
        'දරුණු ලෙස රෝගී වූ දළු සහ කොළ කඩා ඉවත් කරන්න.',
        'රෝගය පැතිරීම අවම කිරීම සඳහා නියමිත කාලයට දළු නෙළන්න.',
        ...base,
      ] : <String>[
        'Blister blight suspected — isolate the affected section.',
        'Apply copper-based fungicides immediately.',
        'Remove heavily infected shoots and leaves.',
        'Keep plucking rounds timely to reduce spread.',
        ...base,
      ],
      TeaLeafDisease.greyBlight => isSinhala ? <String>[
        'ග්‍රේ බ්ලයිට් (Grey Blight) රෝගය බවට සැක කෙරේ — සෙවණ වැඩි නම් එය අඩු කරන්න.',
        'බිමට වැටී ඇති රෝගී කොළ එකතු කර විනාශ කරන්න.',
        ...base,
      ] : <String>[
        'Grey blight suspected — reduce shade if too dense.',
        'Collect and dispose fallen infected leaves.',
        ...base,
      ],
      TeaLeafDisease.redRust => isSinhala ? <String>[
        'රෙඩ් රස්ට් (Red Rust) රෝගය බවට සැක කෙරේ — පෝෂණ ඌනතා ඇත්දැයි පරීක්ෂා කරන්න.',
        'ජලය හොඳින් බැසයාමට සලස්වන්න සහ ජලය රැඳීම වළක්වන්න.',
        ...base,
      ] : <String>[
        'Red rust suspected — check for nutritional stress.',
        'Ensure adequate drainage and avoid waterlogging.',
        ...base,
      ],
      TeaLeafDisease.algalLeafSpot => isSinhala ? <String>[
        'ඇල්ගී කොළ පුල්ලි (Algal Leaf Spot) රෝගය බවට සැක කෙරේ — ජලය බැසයාම සහ වාතාශ්‍රය වැඩි කරන්න.',
        'කොළ දිගු වේලාවක් තෙත් වී තිබීම වළක්වාගන්න.',
        ...base,
      ] : <String>[
        'Algal leaf spot suspected — improve drainage and airflow.',
        'Avoid prolonged leaf wetness in the field.',
        ...base,
      ],
      TeaLeafDisease.unknown => isSinhala ? <String>[
        'වෙනත් රෝගයක් බවට සැක කෙරේ — සාමාන්‍ය දිලීර නාශකයක් යොදන්න.',
        'වඩාත් පැහැදිලි, ළඟින් ගත් ඡායාරූපයක් භාවිතයෙන් නැවත පරීක්ෂා කරන්න.',
        'තත්ත්වය දරුණු නම්, කෘෂිකර්ම උපදේශකයෙකු හමුවන්න.',
      ] : <String>[
        'Other disease suspected — apply general broad-spectrum control.',
        'Take a sharper, closer photo for better accuracy.',
        'If severe, consult a field officer/agronomist.',
      ],
    };
  }
}
