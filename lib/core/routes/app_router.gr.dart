// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CartScreen]
class CartRoute extends PageRouteInfo<void> {
  const CartRoute({List<PageRouteInfo>? children})
    : super(CartRoute.name, initialChildren: children);

  static const String name = 'CartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CartScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [MainTabScreen]
class MainTabRoute extends PageRouteInfo<void> {
  const MainTabRoute({List<PageRouteInfo>? children})
    : super(MainTabRoute.name, initialChildren: children);

  static const String name = 'MainTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainTabScreen();
    },
  );
}

/// generated route for
/// [MenuItemDetailScreen]
class MenuItemDetailRoute extends PageRouteInfo<MenuItemDetailRouteArgs> {
  MenuItemDetailRoute({
    Key? key,
    required MenuItemModel menuItem,
    List<PageRouteInfo>? children,
  }) : super(
         MenuItemDetailRoute.name,
         args: MenuItemDetailRouteArgs(key: key, menuItem: menuItem),
         initialChildren: children,
       );

  static const String name = 'MenuItemDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MenuItemDetailRouteArgs>();
      return MenuItemDetailScreen(key: args.key, menuItem: args.menuItem);
    },
  );
}

class MenuItemDetailRouteArgs {
  const MenuItemDetailRouteArgs({this.key, required this.menuItem});

  final Key? key;

  final MenuItemModel menuItem;

  @override
  String toString() {
    return 'MenuItemDetailRouteArgs{key: $key, menuItem: $menuItem}';
  }
}

/// generated route for
/// [MenuItemUpsertScreen]
class MenuItemUpsertRoute extends PageRouteInfo<MenuItemUpsertRouteArgs> {
  MenuItemUpsertRoute({
    Key? key,
    MenuItemModel? menuItemModel,
    List<PageRouteInfo>? children,
  }) : super(
         MenuItemUpsertRoute.name,
         args: MenuItemUpsertRouteArgs(key: key, menuItemModel: menuItemModel),
         initialChildren: children,
       );

  static const String name = 'MenuItemUpsertRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MenuItemUpsertRouteArgs>(
        orElse: () => const MenuItemUpsertRouteArgs(),
      );
      return MenuItemUpsertScreen(
        key: args.key,
        menuItemModel: args.menuItemModel,
      );
    },
  );
}

class MenuItemUpsertRouteArgs {
  const MenuItemUpsertRouteArgs({this.key, this.menuItemModel});

  final Key? key;

  final MenuItemModel? menuItemModel;

  @override
  String toString() {
    return 'MenuItemUpsertRouteArgs{key: $key, menuItemModel: $menuItemModel}';
  }
}

/// generated route for
/// [MenuItemsScreen]
class MenuItemsRoute extends PageRouteInfo<void> {
  const MenuItemsRoute({List<PageRouteInfo>? children})
    : super(MenuItemsRoute.name, initialChildren: children);

  static const String name = 'MenuItemsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MenuItemsScreen();
    },
  );
}

/// generated route for
/// [OrderScreen]
class OrderRoute extends PageRouteInfo<void> {
  const OrderRoute({List<PageRouteInfo>? children})
    : super(OrderRoute.name, initialChildren: children);

  static const String name = 'OrderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrderScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreen();
    },
  );
}
