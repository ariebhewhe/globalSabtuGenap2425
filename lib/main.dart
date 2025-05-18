import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:jamal/shared/services/current_user_storage_service.dart';

import 'package:jamal/features/auth/auth_provider.dart';
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

    runApp(
      ProviderScope(
        overrides: [
          firebaseAppProvider.overrideWithValue(firebaseApp),
          secureStorageProvider.overrideWithValue(secureStorage),
          sharedPreferencesWithCacheProvider.overrideWithValue(
            preferencesWithCache,
          ),
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final appRouter = ref.watch(appRouterProvider);

    // Todo: Fix ketika user login google atau register untuk pertama kali gak redirect
    ref.listen<AsyncValue<User?>>(authStateProvider, (
      previousAsyncState,
      currentAsyncState,
    ) async {
      logger.i(
        "MyApp Listener: Auth AsyncValue changed. Current: ${currentAsyncState.toString()}. Previous: ${previousAsyncState?.toString()}",
      );

      final currentRouteName = appRouter.current.name;

      if (currentAsyncState.isLoading) {
        logger.i("MyApp Listener: Auth state is loading. No action.");
        return;
      }

      if (currentAsyncState.hasError) {
        logger.e(
          "MyApp Listener: Error in authStateProvider: ${currentAsyncState.error}, Stack: ${currentAsyncState.stackTrace}",
        );

        if (currentRouteName != LoginRoute.name) {
          appRouter.replaceAll([const LoginRoute()]);
          logger.w(
            "MyApp Listener: Redirecting to LoginRoute due to auth stream error.",
          );
        }
        return;
      }

      final firebaseUser = currentAsyncState.value;

      if (firebaseUser != null) {
        logger.i(
          "MyApp Listener: Firebase User is not null (UID: ${firebaseUser.uid}). Current route: $currentRouteName",
        );

        final currentUserStorage = ref.read(currentUserStorageServiceProvider);
        final userModel = await currentUserStorage.getCurrentUser();

        if (userModel != null && userModel.role == Role.admin) {
          if (currentRouteName != AdminTabRoute.name) {
            appRouter.replaceAll([const AdminTabRoute()]);
            logger.i(
              "MyApp Listener: Redirecting admin to MenuItemUpsertRoute.",
            );
          }
        } else {
          if (currentRouteName != UserTabRoute.name) {
            appRouter.replaceAll([const UserTabRoute()]);
            logger.i("MyApp Listener: Redirecting user to UserTabRoute.");
          }
        }
      } else {
        logger.i(
          "MyApp Listener: Firebase user is null (logged out or no session). Current route: $currentRouteName",
        );
        if (currentRouteName != LoginRoute.name) {
          appRouter.replaceAll([const LoginRoute()]);
          logger.i("MyApp Listener: Redirecting to LoginRoute.");
        }
      }
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Jamal",
      routerConfig: appRouter.config(),
    );
  }
}
