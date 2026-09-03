import '../main.dart';
import '../localization/app_translations.dart';

enum TeaLeafDisease {
  healthy,
  blisterBlight,
  greyBlight,
  redRust,
  algalLeafSpot,
  unknown,
}

enum SeverityLevel { low, medium, high }

class DiagnosisResult {
  DiagnosisResult({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.suggestions,
    this.referenceImageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final TeaLeafDisease disease;
  final double confidence; // 0..1
  final SeverityLevel severity;
  final List<String> suggestions;

  // Optional URL to a reference image. Keep it user-provided/licensed.
  final String? referenceImageUrl;

  final DateTime createdAt;
}

extension TeaLeafDiseaseUi on TeaLeafDisease {
  String get label {
    bool isSinhala = isSinhalaMode.value;
    return switch (this) {
      TeaLeafDisease.healthy => AppTranslations.get('healthy', isSinhala),
      TeaLeafDisease.blisterBlight => AppTranslations.get('blister_blight', isSinhala),
      TeaLeafDisease.greyBlight => AppTranslations.get('grey_blight', isSinhala),
      TeaLeafDisease.redRust => AppTranslations.get('red_rust', isSinhala),
      TeaLeafDisease.algalLeafSpot => AppTranslations.get('algal_leaf', isSinhala),
      TeaLeafDisease.unknown => AppTranslations.get('unknown', isSinhala),
    };
  }
}

extension SeverityLevelUi on SeverityLevel {
  String get label {
    bool isSinhala = isSinhalaMode.value;
    return switch (this) {
      SeverityLevel.low => AppTranslations.get('low', isSinhala),
      SeverityLevel.medium => AppTranslations.get('medium', isSinhala),
      SeverityLevel.high => AppTranslations.get('high', isSinhala),
    };
  }
}
