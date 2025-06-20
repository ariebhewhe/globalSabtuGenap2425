import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// * Yang harus di init di main
final firebaseAppProvider = Provider<FirebaseApp>((ref) {
  throw UnimplementedError('firebaseAppProvider not initialized');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('secureStorageProvider not initialized');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not initialized');
});

final sharedPreferencesWithCacheProvider = Provider<SharedPreferencesWithCache>(
  (ref) {
    throw UnimplementedError(
      'sharedPreferencesWithCacheProvider not initialized',
    );
  },
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  ref.watch(firebaseAppProvider);
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  ref.watch(firebaseAppProvider);
  return FirebaseFirestore.instance;
});
