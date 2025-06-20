import 'package:jamal/data/models/table_reservation_model.dart';

class TableReservationState {
  final bool isLoading;
  final TableReservationModel? tableReservation;
  final String? successMessage;
  final String? errorMessage;

  TableReservationState({
    this.isLoading = false,
    this.tableReservation,
    this.successMessage,
    this.errorMessage,
  });

  TableReservationState copyWith({
    bool? isLoading,
    TableReservationModel? tableReservation,
    String? successMessage,
    String? errorMessage,
  }) {
    return TableReservationState(
      isLoading: isLoading ?? this.isLoading,
      tableReservation: tableReservation ?? this.tableReservation,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
