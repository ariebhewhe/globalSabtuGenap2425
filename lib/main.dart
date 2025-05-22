import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jamal/core/constants/local_storage_keys.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/firebase_options.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/providers/theme_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

final logger = AppLogger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    const secureStorage = FlutterSecureStorage();

    final preferencesWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          LocalStorageKeys.currentUser,
          LocalStorageKeys.currentUserProfile,
        },
      ),
    );

    final preferences = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          firebaseAppProvider.overrideWithValue(firebaseApp),
          secureStorageProvider.overrideWithValue(secureStorage),
          sharedPreferencesWithCacheProvider.overrideWithValue(
            preferencesWithCache,
          ),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    logger.e("Error during initialization: $e");

    runApp(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: Text('Error initializing app'))),
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
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Jamal",
      theme: themeMode.getThemeData(context),
      routerConfig: appRouter.config(),
    );
  }
}
