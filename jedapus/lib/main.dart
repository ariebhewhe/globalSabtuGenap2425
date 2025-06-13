import 'package:flutter/material.dart';
import 'package:jedapus/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kqgdbpiaeweqfrdoixzr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxZ2RicGlhZXdlcWZyZG9peHpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1MTk4MTAsImV4cCI6MjA2NDA5NTgxMH0.AJPrUk3LxYAcRR1ORbvMHs6gXbEWOK7sbS6T2ko3bzg',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Cuti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFDD835)),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => SplashScreen(),
        // Tambahkan route lain jika perlu, misal profil:
        // '/profil': (context) => ProfilPage(idUser: someId),
      },
    );
  }
}
