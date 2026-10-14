import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/name/name_screen.dart';

export 'core/config/app_config.dart' show demoMode;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: WizardApp(),
    ),
  );
}

class WizardApp extends StatelessWidget {
  const WizardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wizard Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const NameScreen(),
    );
  }
}
