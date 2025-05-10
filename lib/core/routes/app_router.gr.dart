// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i6;
import 'package:jamal/data/models/menu_item_model.dart' as _i7;
import 'package:jamal/features/user/home/presentation/screens/home_screen.dart'
    as _i1;
import 'package:jamal/features/user/menu_item/presentation/screens/menu_item_detail_screen.dart'
    as _i2;
import 'package:jamal/features/user/menu_item/presentation/screens/menu_item_upsert_screen.dart'
    as _i3;
import 'package:jamal/features/user/menu_item/presentation/screens/menu_items_screen.dart'
    as _i4;

/// generated route for
/// [_i1.HomeScreen]
class HomeRoute extends _i5.PageRouteInfo<void> {
  const HomeRoute({List<_i5.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i1.HomeScreen();
    },
  );
}

/// generated route for
/// [_i2.MenuItemDetailScreen]
class MenuItemDetailRoute extends _i5.PageRouteInfo<MenuItemDetailRouteArgs> {
  MenuItemDetailRoute({
    _i6.Key? key,
    required _i7.MenuItemModel menuItem,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         MenuItemDetailRoute.name,
         args: MenuItemDetailRouteArgs(key: key, menuItem: menuItem),
         initialChildren: children,
       );

  static const String name = 'MenuItemDetailRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MenuItemDetailRouteArgs>();
      return _i2.MenuItemDetailScreen(key: args.key, menuItem: args.menuItem);
    },
  );
}

class MenuItemDetailRouteArgs {
  const MenuItemDetailRouteArgs({this.key, required this.menuItem});

  final _i6.Key? key;

  final _i7.MenuItemModel menuItem;

  @override
  String toString() {
    return 'MenuItemDetailRouteArgs{key: $key, menuItem: $menuItem}';
  }
}

/// generated route for
/// [_i3.MenuItemUpsertScreen]
class MenuItemUpsertRoute extends _i5.PageRouteInfo<MenuItemUpsertRouteArgs> {
  MenuItemUpsertRoute({
    _i6.Key? key,
    _i7.MenuItemModel? menuItemModel,
    List<_i5.PageRouteInfo>? children,
  }) : super(
         MenuItemUpsertRoute.name,
         args: MenuItemUpsertRouteArgs(key: key, menuItemModel: menuItemModel),
         initialChildren: children,
       );

  static const String name = 'MenuItemUpsertRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MenuItemUpsertRouteArgs>(
        orElse: () => const MenuItemUpsertRouteArgs(),
      );
      return _i3.MenuItemUpsertScreen(
        key: args.key,
        menuItemModel: args.menuItemModel,
      );
    },
  );
}

class MenuItemUpsertRouteArgs {
  const MenuItemUpsertRouteArgs({this.key, this.menuItemModel});

  final _i6.Key? key;

  final _i7.MenuItemModel? menuItemModel;

  @override
  String toString() {
    return 'MenuItemUpsertRouteArgs{key: $key, menuItemModel: $menuItemModel}';
  }
}

/// generated route for
/// [_i4.MenuItemsScreen]
class MenuItemsRoute extends _i5.PageRouteInfo<void> {
  const MenuItemsRoute({List<_i5.PageRouteInfo>? children})
    : super(MenuItemsRoute.name, initialChildren: children);

  static const String name = 'MenuItemsRoute';

  static _i5.PageInfo page = _i5.PageInfo(
    name,
    builder: (data) {
      return const _i4.MenuItemsScreen();
    },
  );
}
