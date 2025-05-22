import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/data/repositories/table_reservation_repo.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_state.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_provider.dart';
import 'package:jamal/features/table_reservation/providers/user_table_reservations_provider.dart';

class TableReservationMutationNotifier
    extends StateNotifier<TableReservationMutationState> {
  final TableReservationRepo _tableReservationRepo;
  final Ref _ref;

  TableReservationMutationNotifier(this._tableReservationRepo, this._ref)
    : super(TableReservationMutationState());

  Future<void> updateTableReservation(
    String id,
    UpdateTableReservationDto updatedTableReservation,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _tableReservationRepo.updateTableReservation(
      id,
      updatedTableReservation,
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
        _ref
            .read(userTableReservationsProvider.notifier)
            .refreshTableReservations();

        final activeId = _ref.read(activeTableReservationIdProvider);
        if (activeId == id) {
          _ref
              .read(activeTableReservationProvider.notifier)
              .refreshTableReservation();
        }
      },
    );
  }

  Future<void> deleteTableReservation(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _tableReservationRepo.deleteTableReservation(id);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref
            .read(userTableReservationsProvider.notifier)
            .refreshTableReservations();

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeTableReservationIdProvider);
        if (activeId == id) {
          _ref.read(activeTableReservationIdProvider.notifier).state = null;
        }
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

final tableReservationMutationProvider = StateNotifierProvider<
  TableReservationMutationNotifier,
  TableReservationMutationState
>((ref) {
  final TableReservationRepo tableReservationRepo = ref.watch(
    tableReservationRepoProvider,
  );
  return TableReservationMutationNotifier(tableReservationRepo, ref);
});
