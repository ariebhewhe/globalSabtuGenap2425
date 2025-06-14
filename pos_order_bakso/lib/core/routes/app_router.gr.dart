// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AdminCartScreen]
class AdminCartRoute extends PageRouteInfo<void> {
  const AdminCartRoute({List<PageRouteInfo>? children})
    : super(AdminCartRoute.name, initialChildren: children);

  static const String name = 'AdminCartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminCartScreen();
    },
  );
}

/// generated route for
/// [AdminCategoriesScreen]
class AdminCategoriesRoute extends PageRouteInfo<void> {
  const AdminCategoriesRoute({List<PageRouteInfo>? children})
    : super(AdminCategoriesRoute.name, initialChildren: children);

  static const String name = 'AdminCategoriesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminCategoriesScreen();
    },
  );
}

/// generated route for
/// [AdminCategoryUpsertScreen]
class AdminCategoryUpsertRoute
    extends PageRouteInfo<AdminCategoryUpsertRouteArgs> {
  AdminCategoryUpsertRoute({
    Key? key,
    CategoryModel? category,
    List<PageRouteInfo>? children,
  }) : super(
         AdminCategoryUpsertRoute.name,
         args: AdminCategoryUpsertRouteArgs(key: key, category: category),
         initialChildren: children,
       );

  static const String name = 'AdminCategoryUpsertRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminCategoryUpsertRouteArgs>(
        orElse: () => const AdminCategoryUpsertRouteArgs(),
      );
      return AdminCategoryUpsertScreen(key: args.key, category: args.category);
    },
  );
}

class AdminCategoryUpsertRouteArgs {
  const AdminCategoryUpsertRouteArgs({this.key, this.category});

  final Key? key;

  final CategoryModel? category;

  @override
  String toString() {
    return 'AdminCategoryUpsertRouteArgs{key: $key, category: $category}';
  }
}

/// generated route for
/// [AdminCreateOrderScreen]
class AdminCreateOrderRoute extends PageRouteInfo<void> {
  const AdminCreateOrderRoute({List<PageRouteInfo>? children})
    : super(AdminCreateOrderRoute.name, initialChildren: children);

  static const String name = 'AdminCreateOrderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminCreateOrderScreen();
    },
  );
}

/// generated route for
/// [AdminHomeScreen]
class AdminHomeRoute extends PageRouteInfo<void> {
  const AdminHomeRoute({List<PageRouteInfo>? children})
    : super(AdminHomeRoute.name, initialChildren: children);

  static const String name = 'AdminHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminHomeScreen();
    },
  );
}

/// generated route for
/// [AdminMenuItemDetailScreen]
class AdminMenuItemDetailRoute
    extends PageRouteInfo<AdminMenuItemDetailRouteArgs> {
  AdminMenuItemDetailRoute({
    Key? key,
    required MenuItemModel menuItem,
    List<PageRouteInfo>? children,
  }) : super(
         AdminMenuItemDetailRoute.name,
         args: AdminMenuItemDetailRouteArgs(key: key, menuItem: menuItem),
         initialChildren: children,
       );

  static const String name = 'AdminMenuItemDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminMenuItemDetailRouteArgs>();
      return AdminMenuItemDetailScreen(key: args.key, menuItem: args.menuItem);
    },
  );
}

class AdminMenuItemDetailRouteArgs {
  const AdminMenuItemDetailRouteArgs({this.key, required this.menuItem});

  final Key? key;

  final MenuItemModel menuItem;

  @override
  String toString() {
    return 'AdminMenuItemDetailRouteArgs{key: $key, menuItem: $menuItem}';
  }
}

/// generated route for
/// [AdminMenuItemUpsertScreen]
class AdminMenuItemUpsertRoute
    extends PageRouteInfo<AdminMenuItemUpsertRouteArgs> {
  AdminMenuItemUpsertRoute({
    Key? key,
    MenuItemModel? menuItem,
    List<PageRouteInfo>? children,
  }) : super(
         AdminMenuItemUpsertRoute.name,
         args: AdminMenuItemUpsertRouteArgs(key: key, menuItem: menuItem),
         initialChildren: children,
       );

  static const String name = 'AdminMenuItemUpsertRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminMenuItemUpsertRouteArgs>(
        orElse: () => const AdminMenuItemUpsertRouteArgs(),
      );
      return AdminMenuItemUpsertScreen(key: args.key, menuItem: args.menuItem);
    },
  );
}

class AdminMenuItemUpsertRouteArgs {
  const AdminMenuItemUpsertRouteArgs({this.key, this.menuItem});

  final Key? key;

  final MenuItemModel? menuItem;

  @override
  String toString() {
    return 'AdminMenuItemUpsertRouteArgs{key: $key, menuItem: $menuItem}';
  }
}

/// generated route for
/// [AdminMenuItemsScreen]
class AdminMenuItemsRoute extends PageRouteInfo<void> {
  const AdminMenuItemsRoute({List<PageRouteInfo>? children})
    : super(AdminMenuItemsRoute.name, initialChildren: children);

  static const String name = 'AdminMenuItemsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminMenuItemsScreen();
    },
  );
}

/// generated route for
/// [AdminOrderDetailScreen]
class AdminOrderDetailRoute extends PageRouteInfo<AdminOrderDetailRouteArgs> {
  AdminOrderDetailRoute({
    Key? key,
    required OrderModel order,
    List<PageRouteInfo>? children,
  }) : super(
         AdminOrderDetailRoute.name,
         args: AdminOrderDetailRouteArgs(key: key, order: order),
         initialChildren: children,
       );

  static const String name = 'AdminOrderDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminOrderDetailRouteArgs>();
      return AdminOrderDetailScreen(key: args.key, order: args.order);
    },
  );
}

class AdminOrderDetailRouteArgs {
  const AdminOrderDetailRouteArgs({this.key, required this.order});

  final Key? key;

  final OrderModel order;

  @override
  String toString() {
    return 'AdminOrderDetailRouteArgs{key: $key, order: $order}';
  }
}

/// generated route for
/// [AdminOrdersScreen]
class AdminOrdersRoute extends PageRouteInfo<void> {
  const AdminOrdersRoute({List<PageRouteInfo>? children})
    : super(AdminOrdersRoute.name, initialChildren: children);

  static const String name = 'AdminOrdersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminOrdersScreen();
    },
  );
}

/// generated route for
/// [AdminPaymentMethodUpsertScreen]
class AdminPaymentMethodUpsertRoute
    extends PageRouteInfo<AdminPaymentMethodUpsertRouteArgs> {
  AdminPaymentMethodUpsertRoute({
    Key? key,
    PaymentMethodModel? paymentMethod,
    List<PageRouteInfo>? children,
  }) : super(
         AdminPaymentMethodUpsertRoute.name,
         args: AdminPaymentMethodUpsertRouteArgs(
           key: key,
           paymentMethod: paymentMethod,
         ),
         initialChildren: children,
       );

  static const String name = 'AdminPaymentMethodUpsertRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminPaymentMethodUpsertRouteArgs>(
        orElse: () => const AdminPaymentMethodUpsertRouteArgs(),
      );
      return AdminPaymentMethodUpsertScreen(
        key: args.key,
        paymentMethod: args.paymentMethod,
      );
    },
  );
}

class AdminPaymentMethodUpsertRouteArgs {
  const AdminPaymentMethodUpsertRouteArgs({this.key, this.paymentMethod});

  final Key? key;

  final PaymentMethodModel? paymentMethod;

  @override
  String toString() {
    return 'AdminPaymentMethodUpsertRouteArgs{key: $key, paymentMethod: $paymentMethod}';
  }
}

/// generated route for
/// [AdminPaymentMethodsScreen]
class AdminPaymentMethodsRoute extends PageRouteInfo<void> {
  const AdminPaymentMethodsRoute({List<PageRouteInfo>? children})
    : super(AdminPaymentMethodsRoute.name, initialChildren: children);

  static const String name = 'AdminPaymentMethodsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminPaymentMethodsScreen();
    },
  );
}

/// generated route for
/// [AdminProfileScreen]
class AdminProfileRoute extends PageRouteInfo<void> {
  const AdminProfileRoute({List<PageRouteInfo>? children})
    : super(AdminProfileRoute.name, initialChildren: children);

  static const String name = 'AdminProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminProfileScreen();
    },
  );
}

/// generated route for
/// [AdminRestaurantTableUpsertScreen]
class AdminRestaurantTableUpsertRoute
    extends PageRouteInfo<AdminRestaurantTableUpsertRouteArgs> {
  AdminRestaurantTableUpsertRoute({
    Key? key,
    RestaurantTableModel? restaurantTable,
    List<PageRouteInfo>? children,
  }) : super(
         AdminRestaurantTableUpsertRoute.name,
         args: AdminRestaurantTableUpsertRouteArgs(
           key: key,
           restaurantTable: restaurantTable,
         ),
         initialChildren: children,
       );

  static const String name = 'AdminRestaurantTableUpsertRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminRestaurantTableUpsertRouteArgs>(
        orElse: () => const AdminRestaurantTableUpsertRouteArgs(),
      );
      return AdminRestaurantTableUpsertScreen(
        key: args.key,
        restaurantTable: args.restaurantTable,
      );
    },
  );
}

class AdminRestaurantTableUpsertRouteArgs {
  const AdminRestaurantTableUpsertRouteArgs({this.key, this.restaurantTable});

  final Key? key;

  final RestaurantTableModel? restaurantTable;

  @override
  String toString() {
    return 'AdminRestaurantTableUpsertRouteArgs{key: $key, restaurantTable: $restaurantTable}';
  }
}

/// generated route for
/// [AdminRestaurantTablesScreen]
class AdminRestaurantTablesRoute extends PageRouteInfo<void> {
  const AdminRestaurantTablesRoute({List<PageRouteInfo>? children})
    : super(AdminRestaurantTablesRoute.name, initialChildren: children);

  static const String name = 'AdminRestaurantTablesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminRestaurantTablesScreen();
    },
  );
}

/// generated route for
/// [AdminTabScreen]
class AdminTabRoute extends PageRouteInfo<void> {
  const AdminTabRoute({List<PageRouteInfo>? children})
    : super(AdminTabRoute.name, initialChildren: children);

  static const String name = 'AdminTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminTabScreen();
    },
  );
}

/// generated route for
/// [AdminTableReservationDetailScreen]
class AdminTableReservationDetailRoute
    extends PageRouteInfo<AdminTableReservationDetailRouteArgs> {
  AdminTableReservationDetailRoute({
    Key? key,
    required TableReservationModel reservation,
    List<PageRouteInfo>? children,
  }) : super(
         AdminTableReservationDetailRoute.name,
         args: AdminTableReservationDetailRouteArgs(
           key: key,
           reservation: reservation,
         ),
         initialChildren: children,
       );

  static const String name = 'AdminTableReservationDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminTableReservationDetailRouteArgs>();
      return AdminTableReservationDetailScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class AdminTableReservationDetailRouteArgs {
  const AdminTableReservationDetailRouteArgs({
    this.key,
    required this.reservation,
  });

  final Key? key;

  final TableReservationModel reservation;

  @override
  String toString() {
    return 'AdminTableReservationDetailRouteArgs{key: $key, reservation: $reservation}';
  }
}

/// generated route for
/// [AdminTableReservationsScreen]
class AdminTableReservationsRoute extends PageRouteInfo<void> {
  const AdminTableReservationsRoute({List<PageRouteInfo>? children})
    : super(AdminTableReservationsRoute.name, initialChildren: children);

  static const String name = 'AdminTableReservationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminTableReservationsScreen();
    },
  );
}

/// generated route for
/// [AdminUpdateOrderScreen]
class AdminUpdateOrderRoute extends PageRouteInfo<AdminUpdateOrderRouteArgs> {
  AdminUpdateOrderRoute({
    Key? key,
    OrderModel? order,
    List<PageRouteInfo>? children,
  }) : super(
         AdminUpdateOrderRoute.name,
         args: AdminUpdateOrderRouteArgs(key: key, order: order),
         initialChildren: children,
       );

  static const String name = 'AdminUpdateOrderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminUpdateOrderRouteArgs>(
        orElse: () => const AdminUpdateOrderRouteArgs(),
      );
      return AdminUpdateOrderScreen(key: args.key, order: args.order);
    },
  );
}

class AdminUpdateOrderRouteArgs {
  const AdminUpdateOrderRouteArgs({this.key, this.order});

  final Key? key;

  final OrderModel? order;

  @override
  String toString() {
    return 'AdminUpdateOrderRouteArgs{key: $key, order: $order}';
  }
}

/// generated route for
/// [AdminUpdateTableReservationScreen]
class AdminUpdateTableReservationRoute
    extends PageRouteInfo<AdminUpdateTableReservationRouteArgs> {
  AdminUpdateTableReservationRoute({
    Key? key,
    TableReservationModel? tableReservation,
    List<PageRouteInfo>? children,
  }) : super(
         AdminUpdateTableReservationRoute.name,
         args: AdminUpdateTableReservationRouteArgs(
           key: key,
           tableReservation: tableReservation,
         ),
         initialChildren: children,
       );

  static const String name = 'AdminUpdateTableReservationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminUpdateTableReservationRouteArgs>(
        orElse: () => const AdminUpdateTableReservationRouteArgs(),
      );
      return AdminUpdateTableReservationScreen(
        key: args.key,
        tableReservation: args.tableReservation,
      );
    },
  );
}

class AdminUpdateTableReservationRouteArgs {
  const AdminUpdateTableReservationRouteArgs({this.key, this.tableReservation});

  final Key? key;

  final TableReservationModel? tableReservation;

  @override
  String toString() {
    return 'AdminUpdateTableReservationRouteArgs{key: $key, tableReservation: $tableReservation}';
  }
}

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
/// [CreateOrderScreen]
class CreateOrderRoute extends PageRouteInfo<void> {
  const CreateOrderRoute({List<PageRouteInfo>? children})
    : super(CreateOrderRoute.name, initialChildren: children);

  static const String name = 'CreateOrderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateOrderScreen();
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
/// [OrderDetailScreen]
class OrderDetailRoute extends PageRouteInfo<OrderDetailRouteArgs> {
  OrderDetailRoute({
    Key? key,
    required OrderModel order,
    List<PageRouteInfo>? children,
  }) : super(
         OrderDetailRoute.name,
         args: OrderDetailRouteArgs(key: key, order: order),
         initialChildren: children,
       );

  static const String name = 'OrderDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OrderDetailRouteArgs>();
      return OrderDetailScreen(key: args.key, order: args.order);
    },
  );
}

class OrderDetailRouteArgs {
  const OrderDetailRouteArgs({this.key, required this.order});

  final Key? key;

  final OrderModel order;

  @override
  String toString() {
    return 'OrderDetailRouteArgs{key: $key, order: $order}';
  }
}

/// generated route for
/// [OrdersScreen]
class OrdersRoute extends PageRouteInfo<void> {
  const OrdersRoute({List<PageRouteInfo>? children})
    : super(OrdersRoute.name, initialChildren: children);

  static const String name = 'OrdersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OrdersScreen();
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
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterScreen();
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

/// generated route for
/// [TableReservationDetailScreen]
class TableReservationDetailRoute
    extends PageRouteInfo<TableReservationDetailRouteArgs> {
  TableReservationDetailRoute({
    Key? key,
    required TableReservationModel reservation,
    List<PageRouteInfo>? children,
  }) : super(
         TableReservationDetailRoute.name,
         args: TableReservationDetailRouteArgs(
           key: key,
           reservation: reservation,
         ),
         initialChildren: children,
       );

  static const String name = 'TableReservationDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TableReservationDetailRouteArgs>();
      return TableReservationDetailScreen(
        key: args.key,
        reservation: args.reservation,
      );
    },
  );
}

class TableReservationDetailRouteArgs {
  const TableReservationDetailRouteArgs({this.key, required this.reservation});

  final Key? key;

  final TableReservationModel reservation;

  @override
  String toString() {
    return 'TableReservationDetailRouteArgs{key: $key, reservation: $reservation}';
  }
}

/// generated route for
/// [TableReservationsScreen]
class TableReservationsRoute extends PageRouteInfo<void> {
  const TableReservationsRoute({List<PageRouteInfo>? children})
    : super(TableReservationsRoute.name, initialChildren: children);

  static const String name = 'TableReservationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TableReservationsScreen();
    },
  );
}

/// generated route for
/// [UserTabScreen]
class UserTabRoute extends PageRouteInfo<void> {
  const UserTabRoute({List<PageRouteInfo>? children})
    : super(UserTabRoute.name, initialChildren: children);

  static const String name = 'UserTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UserTabScreen();
    },
  );
}
