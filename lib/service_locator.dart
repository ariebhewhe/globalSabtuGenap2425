import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:jamal/core/constants/local_storage_keys.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

final serviceLocator = GetIt.instance;
final logger = AppLogger();

Future<void> initDependencies() async {
  try {
    final secureStorage = const FlutterSecureStorage();
    final preferences = await SharedPreferences.getInstance();
    final preferencesWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          LocalStorageKeys.currentUser,
          LocalStorageKeys.currentUserProfile,
        },
      ),
    );

    serviceLocator.registerSingleton<FlutterSecureStorage>(secureStorage);
    serviceLocator.registerSingleton<SharedPreferences>(preferences);
    serviceLocator.registerSingleton<SharedPreferencesWithCache>(
      preferencesWithCache,
    );

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    serviceLocator.registerLazySingleton(() => FirebaseAuth.instance);
    serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);

    serviceLocator.registerFactory(() => MenuItemRepo(serviceLocator()));
  } catch (e) {
    logger.e(e.toString());
  }
}
