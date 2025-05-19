import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

class AuthRouteObserver extends NavigatorObserver {
  final WidgetRef ref;
  bool isHandlingAuth = false;

  AuthRouteObserver(this.ref) {
    // Inisialisasi listener auth state saat observer dibuat
    _setupAuthListener();
  }

  void _setupAuthListener() {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, current) async {
      if (isHandlingAuth || current.isLoading) return;

      try {
        isHandlingAuth = true;
        final logger = AppLogger();

        if (current.hasError) {
          logger.e("Auth error: ${current.error}");
          _navigateToLogin();
          isHandlingAuth = false;
          return;
        }

        final user = current.value;
        if (user == null) {
          logger.i("User logged out, navigating to login");
          _navigateToLogin();
        } else {
          logger.i("User logged in (${user.uid}), determining role");
          final currentUserStorage = ref.read(
            currentUserStorageServiceProvider,
          );
          final userModel = await currentUserStorage.getCurrentUser();

          if (userModel?.role == Role.admin) {
            logger.i("Admin user detected, navigating to admin tab");
            _navigateToAdminTab();
          } else {
            logger.i("Regular user detected, navigating to user tab");
            _navigateToUserTab();
          }
        }
      } finally {
        isHandlingAuth = false;
      }
    });
  }

  void _navigateToLogin() {
    if (navigator == null) return;

    // Pembersihan stack dan navigasi ke login
    navigator!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder:
            (context, _, __) =>
                AutoRouter.declarative(routes: (_) => [LoginRoute()]),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  void _navigateToUserTab() {
    if (navigator == null) return;

    // Pembersihan stack dan navigasi ke tab user
    navigator!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder:
            (context, _, __) =>
                AutoRouter.declarative(routes: (_) => [UserTabRoute()]),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  void _navigateToAdminTab() {
    if (navigator == null) return;

    // Pembersihan stack dan navigasi ke tab admin
    navigator!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder:
            (context, _, __) =>
                AutoRouter.declarative(routes: (_) => [AdminTabRoute()]),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Tambahan logging untuk debug jika diperlukan
  }
}
