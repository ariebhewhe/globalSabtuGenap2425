import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../model/user_model.dart';
import '../../history/data/history_repository.dart';
import '../../history/model/history_model.dart';

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Current user data provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(authRepositoryProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return await repository.getUserData(user.uid);
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth controller for login, register, etc.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final HistoryRepository _historyRepository = HistoryRepository();

  AuthController(this._repository) : super(const AsyncValue.data(null));
// Properti untuk menyimpan route selanjutnya
  String _nextRoute = '/home';

// Getter untuk mendapatkan route setelah login
  String get nextRouteAfterLogin => _nextRoute;
  
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Proses login
      final userCredential =
          await _repository.signInWithEmailAndPassword(email, password);

      // Get user role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] as String? ?? 'user';

        // Setel route untuk navigasi setelah login
        if (role == 'admin' || role == 'librarian') {
          _nextRoute = '/admin';
        } else {
          _nextRoute = '/home';
        }
      }

      // Catat aktivitas dalam try-catch terpisah
      try {
        await _historyRepository.addActivity(
          activityType: ActivityType.login,
          description: 'Login berhasil dengan email $email',
        );
      } catch (historyError) {
        // Log error tapi jangan gagalkan proses login
        debugPrint('Error saat mencatat history: $historyError');
      }

      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      // Perbaikan pesan error yang lebih user-friendly
      String errorMessage = _getUserFriendlyAuthError(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(
          'Terjadi kesalahan: ${e.toString()}', StackTrace.current);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Proses registrasi
      await _repository.registerWithEmailAndPassword(name, email, password);

      // Catat aktivitas dalam try-catch terpisah
      try {
        await _historyRepository.addActivity(
          activityType: ActivityType.register,
          description: 'Pendaftaran akun baru dengan email $email',
          metadata: {
            'name': name,
            'email': email,
          },
        );
      } catch (historyError) {
        // Log error tapi jangan gagalkan proses register
        debugPrint('Error saat mencatat history: $historyError');
      }

      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      // Perbaikan pesan error yang lebih user-friendly
      String errorMessage = _getUserFriendlyAuthError(e);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(
          'Terjadi kesalahan: ${e.toString()}', StackTrace.current);
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Staff login
  Future<bool> staffLogin(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Proses login staff
      await _repository.signInWithEmailAndPassword(email, password);

      // Catat aktivitas dalam try-catch terpisah
      try {
        await _historyRepository.addActivity(
          activityType: ActivityType.login,
          description: 'Staff login berhasil dengan email $email',
        );
      } catch (historyError) {
        // Log error tapi jangan gagalkan proses login
        debugPrint('Error saat mencatat history: $historyError');
      }

      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  // Helper method untuk menerjemahkan pesan error Firebase menjadi user friendly
  String _getUserFriendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silahkan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan. Hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      case 'invalid-credential':
        return 'Kredensial tidak valid. Periksa kembali email dan password Anda.';
      case 'account-exists-with-different-credential':
        return 'Akun sudah ada dengan metode login yang berbeda.';
      case 'user-disabled':
        return 'Akun Anda telah dinonaktifkan. Hubungi administrator.';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});