import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/restaurant_table_repo.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_state.dart';

class SearchRestaurantTablesNotifier
    extends StateNotifier<RestaurantTablesState> {
  final RestaurantTableRepo _restaurantTableRepo;
  static const int _defaultLimit = 10;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  String _currentSearchQuery = '';
  String _currentSearchBy = 'tableNumber';

  SearchRestaurantTablesNotifier(this._restaurantTableRepo)
    : super(RestaurantTablesState()) {}

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // * Search kategori dengan debounce
  void searchRestaurantTables({
    required String query,
    String searchBy = 'tableNumber',
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

    final result = await _restaurantTableRepo.searchRestaurantTables(
      searchBy: _currentSearchBy,
      searchQuery: _currentSearchQuery,
      limit: limit,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            restaurantTables: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load more results (untuk pagination)
  Future<void> loadMoreRestaurantTables({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    late final result;

    // * Jika ada query search, gunakan search method
    if (_currentSearchQuery.isNotEmpty) {
      result = await _restaurantTableRepo.searchRestaurantTables(
        searchBy: _currentSearchBy,
        searchQuery: _currentSearchQuery,
        limit: limit,
        startAfter: state.lastDocument,
      );
    } else {
      // * Jika tidak ada query, gunakan paginated method
      result = await _restaurantTableRepo.getPaginatedRestaurantTables(
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
            restaurantTables: [
              ...state.restaurantTables,
              ...success.data.items,
            ],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
            errorMessage: null,
          ),
    );
  }

  // * Refresh restaurantTables
  Future<void> refreshRestaurantTables({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(
      restaurantTables: [],
      lastDocument: null,
      hasMore: true,
    );

    // * Jika ada query search aktif, lakukan search ulang
    if (_currentSearchQuery.isNotEmpty) {
      await _performSearch(limit: limit);
    }
  }

  // * Clear search and show all restaurantTables
  Future<void> clearSearch({int limit = _defaultLimit}) async {
    _currentSearchQuery = '';
    _currentSearchBy = 'tableNumber';
    _debounceTimer?.cancel();

    // * Reset state dan load semua kategori
    state = state.copyWith(
      restaurantTables: [],
      lastDocument: null,
      hasMore: true,
    );
  }

  // * Get current search query
  String get currentSearchQuery => _currentSearchQuery;

  // * Get current search field
  String get currentSearchBy => _currentSearchBy;
}

final searchRestaurantTablesProvider = StateNotifierProvider<
  SearchRestaurantTablesNotifier,
  RestaurantTablesState
>((ref) {
  final RestaurantTableRepo restaurantTableRepo = ref.watch(
    restaurantTableRepoProvider,
  );
  return SearchRestaurantTablesNotifier(restaurantTableRepo);
});
