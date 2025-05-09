import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/user/menu_item/providers/menu_item_state.dart';
import 'package:jamal/service_locator.dart';

class MenuItemNotifier extends StateNotifier<MenuItemState> {
  final MenuItemRepo _menuItemRepo;
  final String _id;

  MenuItemNotifier(this._menuItemRepo, this._id) : super(MenuItemState()) {
    if (_id.isNotEmpty) {
      getMenuItemById(_id);
    }
  }

  Future<void> getMenuItemById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.getMenuItemById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, menuItem: success.data),
    );
  }

  Future<void> refreshMenuItem() async {
    if (_id.isNotEmpty) {
      await getMenuItemById(_id);
    }
  }
}

final menuItemProvider =
    StateNotifierProvider.family<MenuItemNotifier, MenuItemState, String>((
      ref,
      id,
    ) {
      final MenuItemRepo menuItemRepo = serviceLocator<MenuItemRepo>();
      return MenuItemNotifier(menuItemRepo, id);
    });

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeMenuItemIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeMenuItemProvider =
    StateNotifierProvider<MenuItemNotifier, MenuItemState>((ref) {
      final MenuItemRepo menuItemRepo = serviceLocator<MenuItemRepo>();
      final id = ref.watch(activeMenuItemIdProvider);

      return MenuItemNotifier(menuItemRepo, id ?? '');
    });
