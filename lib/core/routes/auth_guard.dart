import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/features/auth/auth_provider.dart';

class AuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          // * Pengguna sudah login, lanjutkan navigasi
          resolver.next();
        } else {
          // * Pengguna belum login, redirect ke halaman login
          router.push(const LoginRoute());
        }
      },
      loading: () {
        // * Ketika masih memuat status auth, tunda navigasi
        // * Opsional: bisa menampilkan loading screen sementara
        Future.delayed(const Duration(milliseconds: 500), () {
          onNavigation(resolver, router);
        });
      },
      error: (_, __) {
        // * Ada kesalahan saat memeriksa status auth, redirect ke login
        router.push(const LoginRoute());
      },
    );
  }
}
