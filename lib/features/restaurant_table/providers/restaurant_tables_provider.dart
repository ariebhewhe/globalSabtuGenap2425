import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/restaurant_table_repo.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_state.dart';

class RestaurantTablesNotifier extends StateNotifier<RestaurantTablesState> {
  final RestaurantTableRepo _restaurantTableRepo;
  static const int _defaultLimit = 10;

  // * Current filter settings
  String _currentOrderBy = 'createdAt';
  bool _currentDescending = true;

  RestaurantTablesNotifier(this._restaurantTableRepo)
    : super(RestaurantTablesState()) {
    loadRestaurantTables();
  }

  // * Load restaurantTables with current filter settings
  Future<void> loadRestaurantTables({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _restaurantTableRepo.getPaginatedRestaurantTables(
      limit: limit,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
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

  // * Load restaurantTables with specific filter
  Future<void> loadRestaurantTablesWithFilter({
    String orderBy = 'createdAt',
    bool descending = true,
    int limit = _defaultLimit,
  }) async {
    // * Update current filter settings
    _currentOrderBy = orderBy;
    _currentDescending = descending;

    // * Reset state and load with new filter
    state = state.copyWith(
      restaurantTables: [],
      lastDocument: null,
      hasMore: true,
      isLoading: true,
      errorMessage: null,
    );

    final result = await _restaurantTableRepo.getPaginatedRestaurantTables(
      limit: limit,
      orderBy: orderBy,
      descending: descending,
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

  // * Load more restaurantTables with current filter
  Future<void> loadMoreRestaurantTables({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _restaurantTableRepo.getPaginatedRestaurantTables(
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

  // * Refresh restaurantTables with current filter
  Future<void> refreshRestaurantTables({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(
      restaurantTables: [],
      lastDocument: null,
      hasMore: true,
    );

    await loadRestaurantTables(limit: limit);
  }

  // * Reset filter to default and reload
  Future<void> resetFilter({int limit = _defaultLimit}) async {
    _currentOrderBy = 'createdAt';
    _currentDescending = true;

    // * Reset state
    state = state.copyWith(
      restaurantTables: [],
      lastDocument: null,
      hasMore: true,
    );

    await loadRestaurantTables(limit: limit);
  }

  // * Get current filter settings
  String get currentOrderBy => _currentOrderBy;
  bool get currentDescending => _currentDescending;

  // * Check if using default filter
  bool get isUsingDefaultFilter =>
      _currentOrderBy == 'createdAt' && _currentDescending == true;
}

final restaurantTablesProvider =
    StateNotifierProvider<RestaurantTablesNotifier, RestaurantTablesState>((
      ref,
    ) {
      final restaurantTableRepo = ref.watch(restaurantTableRepoProvider);
      return RestaurantTablesNotifier(restaurantTableRepo);
    });
