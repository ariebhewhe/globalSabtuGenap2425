import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/menu_item/providers/menu_items_state.dart';

class MenuItemsNotifier extends StateNotifier<MenuItemsState> {
  final MenuItemRepo _menuItemRepo;
  static const int _defaultLimit = 10;

  // * Current filter settings
  String _currentOrderBy = 'createdAt';
  bool _currentDescending = true;

  MenuItemsNotifier(this._menuItemRepo) : super(MenuItemsState()) {
    loadMenuItems();
  }

  // * Load menuItems with current filter settings
  Future<void> loadMenuItems({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _menuItemRepo.getPaginatedMenuItems(
      limit: limit,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            menuItems: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load menuItems with specific filter
  Future<void> loadMenuItemsWithFilter({
    String orderBy = 'createdAt',
    bool descending = true,
    int limit = _defaultLimit,
  }) async {
    // * Update current filter settings
    _currentOrderBy = orderBy;
    _currentDescending = descending;

    // * Reset state and load with new filter
    state = state.copyWith(
      menuItems: [],
      lastDocument: null,
      hasMore: true,
      isLoading: true,
      errorMessage: null,
    );

    final result = await _menuItemRepo.getPaginatedMenuItems(
      limit: limit,
      orderBy: orderBy,
      descending: descending,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            menuItems: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load more menuItems with current filter
  Future<void> loadMoreMenuItems({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _menuItemRepo.getPaginatedMenuItems(
      limit: limit,
      startAfter: state.lastDocument,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
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
            errorMessage: null,
          ),
    );
  }

  // * Refresh menuItems with current filter
  Future<void> refreshMenuItems({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(menuItems: [], lastDocument: null, hasMore: true);

    await loadMenuItems(limit: limit);
  }

  // * Reset filter to default and reload
  Future<void> resetFilter({int limit = _defaultLimit}) async {
    _currentOrderBy = 'createdAt';
    _currentDescending = true;

    // * Reset state
    state = state.copyWith(menuItems: [], lastDocument: null, hasMore: true);

    await loadMenuItems(limit: limit);
  }

  // * Get current filter settings
  String get currentOrderBy => _currentOrderBy;
  bool get currentDescending => _currentDescending;

  // * Check if using default filter
  bool get isUsingDefaultFilter =>
      _currentOrderBy == 'createdAt' && _currentDescending == true;
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, MenuItemsState>((ref) {
      final menuItemRepo = ref.watch(menuItemRepoProvider);
      return MenuItemsNotifier(menuItemRepo);
    });
