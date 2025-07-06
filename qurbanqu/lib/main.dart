import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/firebase_options.dart';
import 'package:qurbanqu/presentation/admin/pages/admin_dashboard_screen.dart';
import 'package:qurbanqu/presentation/auth/pages/splash_screen.dart';
import 'package:qurbanqu/presentation/home/pages/home_screen.dart';

import 'package:qurbanqu/service/auth_service.dart';
import 'package:qurbanqu/service/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sf;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await sf.Supabase.initialize(
    url: 'https://mgvrwnntorhutegpvvmn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ndnJ3bm50b3JodXRlZ3B2dm1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDkyNjk3NzIsImV4cCI6MjAyNDg0NTc3Mn0.-12Xqh04vFPHPPmvVbaQolhmF-wLtD8tp3jJWmsjUhs',
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final supabase = sf.Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ProductService>(create: (_) => ProductService()),
      ],
      child: MaterialApp(
        title: 'QurbanQu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            return const SplashScreen();
          }

          return FutureBuilder<bool>(
            future: authService.isUserAdmin(user.uid),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (adminSnapshot.data == true) {
                return AdminDashboardScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
