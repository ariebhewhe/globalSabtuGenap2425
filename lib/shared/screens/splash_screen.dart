import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final logger = AppLogger();
  // * Tambahkan variabel untuk mengontrol minimal durasi splash screen
  bool _minimumSplashTimeElapsed = false;
  bool _authCheckCompleted = false;
  Role? _userRole;

  @override
  void initState() {
    super.initState();

    // * Atur timer untuk minimal durasi splash screen (3 detik)
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _minimumSplashTimeElapsed = true;
      });
      _navigateIfReady();
    });

    // * * Periksa autentikasi secara terpisah
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  // * Metode baru untuk memeriksa status autentikasi
  Future<void> _checkAuthStatus() async {
    try {
      final authState = ref.read(authStateProvider);

      if (authState.hasError) {
        logger.e("Error pada authState: ${authState.error}");
        setState(() {
          _authCheckCompleted = true;
          _userRole = null; // * Arahkan ke login
        });
        _navigateIfReady();
        return;
      }

      if (authState.isLoading) {
        // * * Tunggu hingga auth state selesai loading
        ref.listenManual(authStateProvider, (previous, next) {
          if (!next.isLoading) {
            _processAuthState(next);
          }
        });
      } else {
        _processAuthState(authState);
      }
    } catch (e) {
      logger.e("Error pada _checkAuthStatus: $e");
      setState(() {
        _authCheckCompleted = true;
        _userRole = null; // * Arahkan ke login
      });
      _navigateIfReady();
    }
  }

  void _processAuthState(AsyncValue<User?> authState) async {
    try {
      final user = authState.value;

      if (user == null) {
        logger.i("User tidak terautentikasi, navigasi ke login");
        setState(() {
          _authCheckCompleted = true;
          _userRole = null; // * Arahkan ke login
        });
        _navigateIfReady();
        return;
      }

      logger.i("User terotentikasi dengan uid: ${user.uid}");
      final userStorage = ref.read(currentUserStorageServiceProvider);
      final userModel = await userStorage.getCurrentUser();

      if (userModel == null) {
        logger.w("User model tidak ditemukan, navigasi ke login");
        setState(() {
          _authCheckCompleted = true;
          _userRole = null; // * Arahkan ke login
        });
        _navigateIfReady();
        return;
      }

      setState(() {
        _authCheckCompleted = true;
        _userRole = userModel.role;
      });
      _navigateIfReady();
    } catch (e) {
      logger.e("Error pada _processAuthState: $e");
      setState(() {
        _authCheckCompleted = true;
        _userRole = null; // * Arahkan ke login
      });
      _navigateIfReady();
    }
  }

  // * Navigasi hanya jika kedua kondisi terpenuhi
  void _navigateIfReady() {
    if (_minimumSplashTimeElapsed && _authCheckCompleted) {
      if (_userRole == null) {
        _navigateToLogin();
      } else if (_userRole == Role.admin) {
        _navigateToAdminTab();
      } else {
        _navigateToUserTab();
      }
    }
  }

  void _navigateToLogin() {
    context.router.replace(const LoginRoute());
  }

  void _navigateToUserTab() {
    context.router.replace(const UserTabRoute());
  }

  void _navigateToAdminTab() {
    context.router.replace(const AdminTabRoute());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Image(
          image: AssetImage("assets/images/splash-3.png"),
          width: 240,
          height: 240,
        ),
      ),
    );
  }
}
