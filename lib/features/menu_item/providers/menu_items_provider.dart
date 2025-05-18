import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/menu_item/providers/menu_items_state.dart';

class MenuItemsNotifier extends StateNotifier<MenuItemsState> {
  final MenuItemRepo _menuItemRepo;
  static const int _defaultLimit = 10;

  MenuItemsNotifier(this._menuItemRepo) : super(MenuItemsState()) {
    loadMenuItems();
  }

  Future<void> loadMenuItems({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.getPaginatedMenuItems(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            menuItems: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreMenuItems({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _menuItemRepo.getPaginatedMenuItems(
      limit: limit,
      startAfter: state.lastDocument,
    );

    result.match(
      (error) =>
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: error.message,
          ),
      (success) =>
          state = state.copyWith(
            menuItems: [...state.menuItems, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshMenuItems({int limit = 10}) async {
    state = state.copyWith(menuItems: [], lastDocument: null);
    await loadMenuItems(limit: limit);
  }
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, MenuItemsState>((ref) {
      final MenuItemRepo menuItemRepo = ref.watch(menuItemRepoProvider);
      return MenuItemsNotifier(menuItemRepo);
    });
