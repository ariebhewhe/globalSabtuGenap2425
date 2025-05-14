// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jamal/core/constants/local_storage_keys.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/firebase_options.dart';
import 'package:jamal/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final logger = AppLogger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // * Inisialisasi service yang diperlukan sebelum menjalankan app
    final firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const secureStorage = FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();
    final preferencesWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          LocalStorageKeys.currentUser,
          LocalStorageKeys.currentUserProfile,
        },
      ),
    );

    runApp(
      ProviderScope(
        overrides: [
          // Override providers dengan instance yang sudah diinisialisasi
          firebaseAppProvider.overrideWithValue(firebaseApp),
          secureStorageProvider.overrideWithValue(secureStorage),
          sharedPreferencesProvider.overrideWithValue(preferences),
          sharedPreferencesWithCacheProvider.overrideWithValue(
            preferencesWithCache,
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    logger.e("Error during initialization: $e");
    // Masih jalankan app, tapi dengan state error
    runApp(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Error initializing app: $e')),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Jamal",
      routerConfig: appRouter.config(),
    );
  }
}
