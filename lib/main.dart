import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'localization/app_translations.dart';
import 'screens/auth_gate.dart';
import 'services/sync_manager.dart';

// Global state for language (true = Sinhala, false = English)
final ValueNotifier<bool> isSinhalaMode = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yqaqsrlmkedinqmbapqu.supabase.co',
    anonKey: 'sb_publishable_OXUq1ezIwJgJQAeARdVY1g_5W9l7FZI',
  );

  // Start listening to connectivity for background syncs
  SyncManager.instance.startListening();

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
          home: const AuthGate(),
        );
      },
    );
  }
}

