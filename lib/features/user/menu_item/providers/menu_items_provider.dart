import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/user/menu_item/providers/menu_items_state.dart';
import 'package:jamal/providers.dart';

class MenuItemsNotifier extends StateNotifier<MenuItemsState> {
  final MenuItemRepo _menuItemRepo;

  MenuItemsNotifier(this._menuItemRepo) : super(MenuItemsState()) {
    getAllMenuItems();
  }

  Future<void> getAllMenuItems() async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.getAllMenuItem();

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, menuItems: success.data),
    );
  }

  Future<void> refreshMenuItems() async {
    getAllMenuItems();
  }
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, MenuItemsState>((ref) {
      final MenuItemRepo menuItemRepo = ref.watch(menuItemRepoProvider);
      return MenuItemsNotifier(menuItemRepo);
    });
