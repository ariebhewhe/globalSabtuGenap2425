import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/auth_guard.dart';
import 'package:jamal/core/routes/duplicate_guard.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/features/auth/presentation/screens/login_screen.dart';
import 'package:jamal/features/cart/presentation/screens/cart_screen.dart';
import 'package:jamal/features/category/screens/admin_categories_screen.dart';
import 'package:jamal/features/category/screens/admin_category_upsert_screen.dart';
import 'package:jamal/features/home/presentation/screens/admin_home_screen.dart';
import 'package:jamal/features/home/presentation/screens/home_screen.dart';
import 'package:jamal/features/menu_item/presentation/screens/admin_menu_item_upsert_screen.dart';
import 'package:jamal/features/menu_item/presentation/screens/admin_menu_items_screen.dart';
import 'package:jamal/features/order/screens/admin_orders_screen.dart';
import 'package:jamal/features/order/screens/create_order_screen.dart';
import 'package:jamal/features/order/screens/orders_screen.dart';
import 'package:jamal/features/payment_method/screens/admin_payment_method_upsert_screen.dart';
import 'package:jamal/features/profile/presentation/screens/admin_profile_screen.dart';
import 'package:jamal/features/profile/presentation/screens/profile_screen.dart';
import 'package:jamal/features/menu_item/presentation/screens/menu_items_screen.dart';
import 'package:jamal/features/menu_item/presentation/screens/menu_item_detail_screen.dart';
import 'package:jamal/features/reservation/screens/reservations_screen.dart';
import 'package:jamal/features/restaurant_table/presentation/screens/admin_restaurant_table_upsert_screen.dart';
import 'package:jamal/shared/screens/splash_screen.dart';
import 'package:jamal/shared/widgets/admin_tab_screen.dart';
import 'package:jamal/shared/widgets/user_tab_screen.dart';

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
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),

    // * User
    CustomRoute(
      page: UserTabRoute.page,
      guards: [_authGuard, _duplicateGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: OrdersRoute.page),
        AutoRoute(page: ReservationsRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
    AutoRoute(page: MenuItemsRoute.page),
    AutoRoute(page: MenuItemDetailRoute.page),
    AutoRoute(
      page: CreateOrderRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),
    AutoRoute(page: CartRoute.page, guards: [_authGuard, _duplicateGuard]),

    // * Admin
    CustomRoute(
      page: AdminTabRoute.page,
      guards: [_authGuard, _duplicateGuard],
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        AutoRoute(page: AdminHomeRoute.page),
        AutoRoute(page: AdminProfileRoute.page),
      ],
    ),

    AutoRoute(
      page: AdminMenuItemsRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),

    AutoRoute(
      page: AdminMenuItemUpsertRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),

    AutoRoute(
      page: AdminPaymentMethodUpsertRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),

    AutoRoute(
      page: AdminCategoriesRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),
    AutoRoute(
      page: AdminCategoryUpsertRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),

    AutoRoute(
      page: AdminRestaurantTableUpsertRoute.page,
      guards: [_authGuard, _duplicateGuard],
    ),
  ];

  @override
  List<AutoRouteGuard> get guards => [];
}
