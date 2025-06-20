import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/menu_item/providers/menu_items_state.dart';

class SearchMenuItemsNotifier extends StateNotifier<MenuItemsState> {
  final MenuItemRepo _menuItemRepo;
  static const int _defaultLimit = 10;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  String _currentSearchQuery = '';
  String _currentSearchBy = 'name';

  SearchMenuItemsNotifier(this._menuItemRepo) : super(MenuItemsState()) {}

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // * Search kategori dengan debounce
  void searchMenuItems({
    required String query,
    String searchBy = 'name',
    int limit = _defaultLimit,
  }) {
    _currentSearchQuery = query.trim();
    _currentSearchBy = searchBy;

    // * Cancel timer sebelumnya jika ada
    _debounceTimer?.cancel();

    // * Jika query kosong, load semua kategori
    if (_currentSearchQuery.isEmpty) {
      return;
    }

    // * Set debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(limit: limit);
    });
  }

  // * Perform actual search operation
  Future<void> _performSearch({int limit = _defaultLimit}) async {
    if (_currentSearchQuery.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _menuItemRepo.searchMenuItems(
      searchBy: _currentSearchBy,
      searchQuery: _currentSearchQuery,
      limit: limit,
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

  // * Load more results (untuk pagination)
  Future<void> loadMoreMenuItems({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    late final result;

    // * Jika ada query search, gunakan search method
    if (_currentSearchQuery.isNotEmpty) {
      result = await _menuItemRepo.searchMenuItems(
        searchBy: _currentSearchBy,
        searchQuery: _currentSearchQuery,
        limit: limit,
        startAfter: state.lastDocument,
      );
    } else {
      // * Jika tidak ada query, gunakan paginated method
      result = await _menuItemRepo.getPaginatedMenuItems(
        limit: limit,
        startAfter: state.lastDocument,
      );
    }

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

  // * Refresh menuItems
  Future<void> refreshMenuItems({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(menuItems: [], lastDocument: null, hasMore: true);

    // * Jika ada query search aktif, lakukan search ulang
    if (_currentSearchQuery.isNotEmpty) {
      await _performSearch(limit: limit);
    }
  }

  // * Clear search and show all menuItems
  Future<void> clearSearch({int limit = _defaultLimit}) async {
    _currentSearchQuery = '';
    _currentSearchBy = 'name';
    _debounceTimer?.cancel();

    // * Reset state dan load semua kategori
    state = state.copyWith(menuItems: [], lastDocument: null, hasMore: true);
  }

  // * Get current search query
  String get currentSearchQuery => _currentSearchQuery;

  // * Get current search field
  String get currentSearchBy => _currentSearchBy;
}

final searchMenuItemsProvider =
    StateNotifierProvider<SearchMenuItemsNotifier, MenuItemsState>((ref) {
      final MenuItemRepo menuItemRepo = ref.watch(menuItemRepoProvider);
      return SearchMenuItemsNotifier(menuItemRepo);
    });
