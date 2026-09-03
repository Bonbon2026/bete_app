import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const BeteApp());
}

class BeteApp extends StatelessWidget {
  const BeteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bete',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0E7C5A),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
