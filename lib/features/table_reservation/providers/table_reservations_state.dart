import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/table_reservation_model.dart';

class TableReservationsState {
  final List<TableReservationModel> tableReservations;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  TableReservationsState({
    this.tableReservations = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  TableReservationsState copyWith({
    List<TableReservationModel>? tableReservations,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return TableReservationsState(
      tableReservations: tableReservations ?? this.tableReservations,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
