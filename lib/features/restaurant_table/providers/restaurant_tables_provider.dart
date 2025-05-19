import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/restaurant_table_repo.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_state.dart';

class RestaurantTablesNotifier extends StateNotifier<RestaurantTablesState> {
  final RestaurantTableRepo _restaurantTableRepo;
  static const int _defaultLimit = 10;

  RestaurantTablesNotifier(this._restaurantTableRepo)
    : super(RestaurantTablesState()) {
    loadRestaurantTables();
  }

  Future<void> loadRestaurantTables({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _restaurantTableRepo.getPaginatedRestaurantTables(
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
          ),
    );
  }

  Future<void> loadMoreRestaurantTables({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _restaurantTableRepo.getPaginatedRestaurantTables(
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
            restaurantTables: [
              ...state.restaurantTables,
              ...success.data.items,
            ],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshRestaurantTables({int limit = 10}) async {
    state = state.copyWith(restaurantTables: [], lastDocument: null);
    await loadRestaurantTables(limit: limit);
  }
}

final restaurantTablesProvider =
    StateNotifierProvider<RestaurantTablesNotifier, RestaurantTablesState>((
      ref,
    ) {
      final RestaurantTableRepo restaurantTableRepo = ref.watch(
        restaurantTableRepoProvider,
      );
      return RestaurantTablesNotifier(restaurantTableRepo);
    });
