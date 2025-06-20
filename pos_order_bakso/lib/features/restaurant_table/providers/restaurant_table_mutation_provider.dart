import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/data/repositories/restaurant_table_repo.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_table_mutation_state.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_table_provider.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_provider.dart';

class RestaurantTableMutationNotifier
    extends StateNotifier<RestaurantTableMutationState> {
  final RestaurantTableRepo _restaurantTableRepo;
  final Ref _ref;

  RestaurantTableMutationNotifier(this._restaurantTableRepo, this._ref)
    : super(RestaurantTableMutationState());

  Future<void> addRestaurantTable(
    CreateRestaurantTableDto newRestaurantTable,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _restaurantTableRepo.addRestaurantTable(
      newRestaurantTable,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();
      },
    );
  }

  Future<void> updateRestaurantTable(
    String id,
    UpdateRestaurantTableDto updatedRestaurantTable,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _restaurantTableRepo.updateRestaurantTable(
      id,
      updatedRestaurantTable,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();

        final activeId = _ref.read(activeRestaurantTableIdProvider);
        if (activeId == id) {
          _ref
              .read(activeRestaurantTableProvider.notifier)
              .refreshRestaurantTable();
        }
      },
    );
  }

  Future<void> deleteRestaurantTable(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _restaurantTableRepo.deleteRestaurantTable(id);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeRestaurantTableIdProvider);
        if (activeId == id) {
          _ref.read(activeRestaurantTableIdProvider.notifier).state = null;
        }
      },
    );
  }

  Future<void> batchDeleteRestaurantTables(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _restaurantTableRepo.batchDeleteRestaurantTables(ids);
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(restaurantTablesProvider);

        final activeId = _ref.read(activeRestaurantTableIdProvider);
        if (activeId != null && ids.contains(activeId)) {
          _ref.read(activeRestaurantTableIdProvider.notifier).state = null;
        }
      },
    );
  }

  Future<void> deleteAllRestaurantTables() async {
    state = state.copyWith(isLoading: true);
    final result = await _restaurantTableRepo.deleteAllRestaurantTables();
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(restaurantTablesProvider);
        _ref.read(activeRestaurantTableIdProvider.notifier).state = null;
      },
    );
  }

  // * Reset pesan sukses - gunakan untuk menghindari snackbar muncul berulang
  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  // * Reset pesan error - gunakan untuk menghindari snackbar muncul berulang
  void resetErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

final restaurantTableMutationProvider = StateNotifierProvider<
  RestaurantTableMutationNotifier,
  RestaurantTableMutationState
>((ref) {
  final RestaurantTableRepo restaurantTableRepo = ref.watch(
    restaurantTableRepoProvider,
  );
  return RestaurantTableMutationNotifier(restaurantTableRepo, ref);
});
