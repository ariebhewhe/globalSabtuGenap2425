import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/auth_guard.dart';
import 'package:jamal/core/routes/duplicate_guard.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/auth/presentation/screens/login_screen.dart';
import 'package:jamal/features/user/cart/screens/cart_screen.dart';
import 'package:jamal/features/user/home/presentation/screens/home_screen.dart';
import 'package:jamal/features/user/menu_item/presentation/screens/menu_item_upsert_screen.dart';
import 'package:jamal/features/user/order/screens/order_screen.dart';
import 'package:jamal/features/user/profile/presentation/screens/profile_screen.dart';
import 'package:jamal/features/user/menu_item/presentation/screens/menu_items_screen.dart';
import 'package:jamal/features/user/menu_item/presentation/screens/menu_item_detail_screen.dart';
import 'package:jamal/shared/screens/splash_screen.dart';
import 'package:jamal/shared/widgets/main_tab_screen.dart';

part 'app_router.gr.dart';

final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter(ref.watch(authGuardProvider), DuplicateGuard());
});

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  late final AuthGuard _authGuard;
  late final DuplicateGuard _duplicateGuard;

  AppRouter(this._authGuard, this._duplicateGuard);

  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),

    CustomRoute(
      page: MainTabRoute.page,
      guards: [_authGuard, _duplicateGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
    AutoRoute(page: MenuItemsRoute.page),
    AutoRoute(page: MenuItemDetailRoute.page),
    AutoRoute(page: OrderRoute.page, guards: [_authGuard, _duplicateGuard]),
    AutoRoute(page: CartRoute.page, guards: [_authGuard, _duplicateGuard]),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}
