import 'package:flutter/material.dart';
import 'package:warkop_bunny/services/auth_gate.dart';
import 'package:warkop_bunny/themes/light_mode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warkop Bunny',
      theme: lightMode,
      home: AuthGate(),
      // home: LoginPage(),
    );
  }
}
