import 'package:jamal/data/models/table_reservation_model.dart';

class TableReservationMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final TableReservationModel? tableReservationModel;

  TableReservationMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.tableReservationModel,
  });

  TableReservationMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    TableReservationModel? tableReservationModel,
  }) {
    return TableReservationMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      tableReservationModel: tableReservationModel,
    );
  }
}
