import 'package:flutter/material.dart';

import 'localization/app_translations.dart';
import 'screens/scan_home_screen.dart';

// Global state for language (true = Sinhala, false = English)
final ValueNotifier<bool> isSinhalaMode = ValueNotifier<bool>(true);

void main() {
  runApp(const TeaDiseaseApp());
}

class TeaDiseaseApp extends StatelessWidget {
  const TeaDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSinhalaMode,
      builder: (context, isSinhala, child) {
        return MaterialApp(
          title: AppTranslations.get('app_title', isSinhala),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          ),
          home: const ScanHomeScreen(),
        );
      },
    );
  }
}

