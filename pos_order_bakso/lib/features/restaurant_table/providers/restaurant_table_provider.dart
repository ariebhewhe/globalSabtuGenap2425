import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/restaurant_table_repo.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_table_state.dart';

class RestaurantTableNotifier extends StateNotifier<RestaurantTableState> {
  final RestaurantTableRepo _restaurantTableRepo;
  final String _id;

  RestaurantTableNotifier(this._restaurantTableRepo, this._id)
    : super(RestaurantTableState()) {
    if (_id.isNotEmpty) {
      getRestaurantTableById(_id);
    }
  }

  Future<void> getRestaurantTableById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _restaurantTableRepo.getRestaurantTableById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            isLoading: false,
            restaurantTable: success.data,
          ),
    );
  }

  Future<void> refreshRestaurantTable() async {
    if (_id.isNotEmpty) {
      await getRestaurantTableById(_id);
    }
  }
}

final restaurantTableProvider = StateNotifierProvider.family<
  RestaurantTableNotifier,
  RestaurantTableState,
  String
>((ref, id) {
  final RestaurantTableRepo restaurantTableRepo = ref.watch(
    restaurantTableRepoProvider,
  );
  return RestaurantTableNotifier(restaurantTableRepo, id);
});

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeRestaurantTableIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeRestaurantTableProvider =
    StateNotifierProvider<RestaurantTableNotifier, RestaurantTableState>((ref) {
      final RestaurantTableRepo restaurantTableRepo = ref.watch(
        restaurantTableRepoProvider,
      );
      final id = ref.watch(activeRestaurantTableIdProvider);

      return RestaurantTableNotifier(restaurantTableRepo, id ?? '');
    });
