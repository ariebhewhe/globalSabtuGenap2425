import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/shared/services/current_user_storage.dart';

final authGuardProvider = Provider<AuthGuard>((ref) {
  return AuthGuard(ref.watch(currentUserStorageServiceProvider));
});

class AuthGuard extends AutoRouteGuard {
  final CurrentUserStorageService _currentUserStorageService;
  final AppLogger logger = AppLogger();

  AuthGuard(this._currentUserStorageService);

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final userModel = await _currentUserStorageService.getCurrentUser();
    final isAuthenticated = userModel != null;
    final targetRouteName = resolver.route.name;

    logger.i(
      "AuthGuard: Checking navigation. Target: '$targetRouteName'. Authenticated: $isAuthenticated. User role: ${userModel?.role}",
    );

    if (isAuthenticated) {
      if (targetRouteName == LoginRoute.name) {
        logger.w(
          "AuthGuard: Authenticated user attempting to navigate to LoginRoute. Listener should have handled this. Redirecting defensively.",
        );
        if (userModel.role == Role.admin) {
          router.replaceAll([const ProfileRoute()]);
        } else {
          router.replaceAll([const MainTabRoute()]);
        }
        resolver.next(false); // Hentikan navigasi ke LoginRoute
        return;
      }
      resolver.next();
    } else {
      if (targetRouteName != LoginRoute.name) {
        logger.i(
          "AuthGuard: Unauthenticated user trying to access '$targetRouteName'. Redirecting to LoginRoute.",
        );
        router.replaceAll([const LoginRoute()]);
        resolver.next(false);
        return;
      }
      resolver.next(true);
    }
  }
}
