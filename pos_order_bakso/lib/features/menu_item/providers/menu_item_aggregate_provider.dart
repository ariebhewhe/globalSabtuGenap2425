import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';

final menuItemsCountProvider = FutureProvider<MenuItemsCountAggregate>((
  ref,
) async {
  final cartRepo = ref.watch(menuItemRepoProvider);
  final result = await cartRepo.getMenuItemsCount();

  return result.fold(
    (error) => MenuItemsCountAggregate(
      allMenuItemCount: 0,
      activeMenuItemCount: 0,
      nonActiveMenuItemCount: 0,
    ),
    (success) => success.data,
  );
});
