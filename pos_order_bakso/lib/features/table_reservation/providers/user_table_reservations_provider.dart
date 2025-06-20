import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/table_reservation_repo.dart';
import 'package:jamal/features/table_reservation/providers/table_reservations_state.dart';

class UserTableReservationsNotifier
    extends StateNotifier<TableReservationsState> {
  final TableReservationRepo _tableReservationRepo;
  static const int _defaultLimit = 10;

  UserTableReservationsNotifier(this._tableReservationRepo)
    : super(TableReservationsState()) {
    loadTableReservations();
  }

  Future<void> loadTableReservations({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _tableReservationRepo
        .getPaginatedUserTableReservations(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            tableReservations: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreTableReservations({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _tableReservationRepo
        .getPaginatedUserTableReservations(
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
            tableReservations: [
              ...state.tableReservations,
              ...success.data.items,
            ],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshTableReservations({int limit = 10}) async {
    state = state.copyWith(tableReservations: [], lastDocument: null);
    await loadTableReservations(limit: limit);
  }
}

final userTableReservationsProvider = StateNotifierProvider<
  UserTableReservationsNotifier,
  TableReservationsState
>((ref) {
  final TableReservationRepo tableReservationRepo = ref.watch(
    tableReservationRepoProvider,
  );
  return UserTableReservationsNotifier(tableReservationRepo);
});
