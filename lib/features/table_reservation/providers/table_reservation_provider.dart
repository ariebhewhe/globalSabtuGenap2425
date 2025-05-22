import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/table_reservation_repo.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_state.dart';

class TableReservationNotifier extends StateNotifier<TableReservationState> {
  final TableReservationRepo _tableReservationRepo;
  final String _id;

  TableReservationNotifier(this._tableReservationRepo, this._id)
    : super(TableReservationState()) {
    if (_id.isNotEmpty) {
      getTableReservationById(_id);
    }
  }

  Future<void> getTableReservationById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _tableReservationRepo.getTableReservationById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            isLoading: false,
            tableReservation: success.data,
          ),
    );
  }

  Future<void> refreshTableReservation() async {
    if (_id.isNotEmpty) {
      await getTableReservationById(_id);
    }
  }
}

final tableReservationProvider = StateNotifierProvider.family<
  TableReservationNotifier,
  TableReservationState,
  String
>((ref, id) {
  final TableReservationRepo tableReservationRepo = ref.watch(
    tableReservationRepoProvider,
  );
  return TableReservationNotifier(tableReservationRepo, id);
});

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeTableReservationIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeTableReservationProvider =
    StateNotifierProvider<TableReservationNotifier, TableReservationState>((
      ref,
    ) {
      final TableReservationRepo tableReservationRepo = ref.watch(
        tableReservationRepoProvider,
      );
      final id = ref.watch(activeTableReservationIdProvider);

      return TableReservationNotifier(tableReservationRepo, id ?? '');
    });
