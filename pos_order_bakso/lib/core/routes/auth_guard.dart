import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final authGuardProvider = Provider<AuthGuard>((ref) {
  return AuthGuard(ref.watch(currentUserStorageServiceProvider));
});

class AuthGuard extends AutoRouteGuard {
  final CurrentUserStorageService _currentUserStorageService;
  final AppLogger logger = AppLogger();

  AuthGuard(this._currentUserStorageService);

  static const List<String> _adminOnlyRoutes = [
    AdminTabRoute.name,
    AdminMenuItemsRoute.name,
    AdminMenuItemUpsertRoute.name,
    AdminPaymentMethodUpsertRoute.name,
    AdminCategoriesRoute.name,
    AdminCategoryUpsertRoute.name,
    AdminRestaurantTableUpsertRoute.name,
    AdminOrdersRoute.name,
  ];

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final UserModel? userModel =
        await _currentUserStorageService.getCurrentUser();
    final bool isAuthenticated = userModel != null;
    final String targetRouteName = resolver.route.name;

    logger.i(
      "AuthGuard: Navigasi ke '$targetRouteName'. Terautentikasi: $isAuthenticated. Peran Pengguna: ${userModel?.role}",
    );

    if (isAuthenticated) {
      final Role userRole = userModel.role;

      if (targetRouteName == LoginRoute.name) {
        logger.w(
          "AuthGuard: Pengguna terautentikasi (peran: $userRole) mencoba ke LoginRoute. Mengarahkan ke halaman utama masing-masing.",
        );
        resolver.next(false); // Hentikan navigasi saat ini
        if (userRole == Role.admin) {
          router.replace(const AdminTabRoute());
        } else {
          router.replace(const UserTabRoute());
        }
        return;
      }

      if (userRole == Role.admin) {
        logger.i("AuthGuard: Akses admin ke '$targetRouteName' diizinkan.");
        resolver.next(true);
      } else if (userRole == Role.user) {
        if (_adminOnlyRoutes.contains(targetRouteName)) {
          logger.w(
            "AuthGuard: Pengguna (peran: $userRole) mencoba akses route admin '$targetRouteName'. Mengarahkan ke UserTabRoute.",
          );
          resolver.next(false); // Hentikan navigasi saat ini
          router.replace(const UserTabRoute());
          return;
        }
        logger.i("AuthGuard: Akses user ke '$targetRouteName' diizinkan.");
        resolver.next(true);
      } else {
        logger.e(
          "AuthGuard: Pengguna dengan peran tidak diketahui '$userRole' mencoba akses '$targetRouteName'. Logout dan arahkan ke Login.",
        );
        await _currentUserStorageService.deleteCurrentUser();
        resolver.next(false); // Hentikan navigasi saat ini
        router.replace(const LoginRoute());
        return;
      }
    } else {
      if (targetRouteName == SplashRoute.name ||
          targetRouteName == LoginRoute.name) {
        logger.i(
          "AuthGuard: Akses tidak terautentikasi ke route publik '$targetRouteName' diizinkan.",
        );
        resolver.next();
      } else {
        logger.i(
          "AuthGuard: Pengguna tidak terautentikasi mencoba akses route terlindungi '$targetRouteName'. Mengarahkan ke LoginRoute.",
        );
        resolver.next(false); // Hentikan navigasi saat ini
        router.replace(const LoginRoute());
        return;
      }
    }
  }
}
