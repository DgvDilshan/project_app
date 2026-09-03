class AppTranslations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'app_title': 'Tea Leaf Disease Detection',
      'welcome_title': 'AgroVision',
      'welcome_subtitle': 'Detect tea leaf diseases instantly using AI.',
      'take_photo': 'Take a Photo',
      'pick_gallery': 'Choose from Gallery',
      'analyzing': 'Analyzing image...',
      'cancel': 'Cancel',
      'review_title': 'Review Image',
      'proceed_button': 'Diagnose Disease',
      'result_title': 'Diagnosis Result',
      'disease_detected': 'Disease Detected',
      'healthy_leaf': 'Healthy Leaf',
      'severity': 'Severity',
      'confidence': 'Confidence',
      'recommendations': 'Recommendations',
      'back_home': 'Back to Home',
      
      // Error messages
      'not_tea_leaf': 'Not a tea leaf',
      'not_tea_leaf_desc': 'The image does not appear to be a tea leaf or contains very little green color. Please capture a clear image of a tea leaf.',
      'uncertain': 'UNCERTAIN PATHOLOGY',
      'uncertain_desc': 'Confidence is below 50% threshold.',
      'processing_error': 'Error analyzing image. Please try again.',
      
      // Diseases
      'healthy': 'Healthy',
      'algal_leaf': 'Algal Leaf Spot',
      'anthracnose': 'Anthracnose',
      'bird_eye_spot': 'Bird Eye Spot',
      'brown_blight': 'Brown Blight',
      'blister_blight': 'Blister Blight',
      'grey_blight': 'Grey Blight',
      'red_rust': 'Red Rust',
      'unknown': 'Unknown',
      
      // Severity Levels
      'high': 'High',
      'medium': 'Medium',
      'low': 'Low',
      'none': 'None',
    },
    'si': {
      'app_title': 'තේ කොළ රෝග හඳුනාගැනීම',
      'welcome_title': 'AgroVision',
      'welcome_subtitle': 'කෘත්‍රිම බුද්ධිය (AI) මගින් තේ කොළ රෝග ක්ෂණිකව හඳුනාගන්න.',
      'take_photo': 'ඡායාරූපයක් ගන්න',
      'pick_gallery': 'ගැලරියෙන් තෝරන්න',
      'analyzing': 'ඡායාරූපය පරීක්ෂා කරමින්...',
      'cancel': 'අවලංගු කරන්න',
      'review_title': 'ඡායාරූපය පරීක්ෂා කිරීම',
      'proceed_button': 'රෝගය හඳුනාගන්න',
      'result_title': 'ප්‍රතිඵලය',
      'disease_detected': 'රෝගය හඳුනාගන්නා ලදී',
      'healthy_leaf': 'නිරෝගී තේ දල්ලකි',
      'severity': 'අවදානම',
      'confidence': 'විශ්වාසනීයත්වය',
      'recommendations': 'නිර්දේශ',
      'back_home': 'ආපසු මුල් පිටුවට',
      
      // Error messages
      'not_tea_leaf': 'තේ කොළයක් නොවේ',
      'not_tea_leaf_desc': 'මෙය තේ කොළයක් ලෙස හඳුනාගත නොහැක (ප්‍රමාණවත් තරම් කොළ පැහැයක් නොමැත). කරුණාකර තේ කොළයක පැහැදිලි ඡායාරූපයක් ගන්න.',
      'uncertain': 'අවිනිශ්චිත රෝග ලක්ෂණ',
      'uncertain_desc': 'හඳුනාගැනීමේ විශ්වාසනීයත්වය 50% ට වඩා අඩුය.',
      'processing_error': 'දෝෂයකි. කරුණාකර නැවත උත්සාහ කරන්න.',
      
      // Diseases
      'healthy': 'නිරෝගී',
      'algal_leaf': 'ඇල්ගල් ලීෆ් ස්පොට් (Algal Leaf Spot)',
      'anthracnose': 'ඇන්ත්‍රැක්නෝස් (Anthracnose)',
      'bird_eye_spot': 'බර්ඩ් අයි ස්පොට් (Bird Eye Spot)',
      'brown_blight': 'බ්‍රවුන් බ්ලයිට් (Brown Blight)',
      'blister_blight': 'බ්ලිස්ටර් බ්ලයිට් (Blister Blight)',
      'grey_blight': 'ග්‍රේ බ්ලයිට් (Grey Blight)',
      'red_rust': 'රෙඩ් රස්ට් (Red Rust)',
      'unknown': 'හඳුනාගත නොහැක',
      
      // Severity Levels
      'high': 'වැඩි අවදානම් (High)',
      'medium': 'මධ්‍යම (Medium)',
      'low': 'අඩු (Low)',
      'none': 'නැත',
    }
  };

  static String get(String key, bool isSinhala) {
    String lang = isSinhala ? 'si' : 'en';
    return translations[lang]?[key] ?? key;
  }
}
