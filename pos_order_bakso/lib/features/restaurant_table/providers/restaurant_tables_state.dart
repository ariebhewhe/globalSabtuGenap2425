import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';

class RestaurantTablesState {
  final List<RestaurantTableModel> restaurantTables;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  RestaurantTablesState({
    this.restaurantTables = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  RestaurantTablesState copyWith({
    List<RestaurantTableModel>? restaurantTables,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return RestaurantTablesState(
      restaurantTables: restaurantTables ?? this.restaurantTables,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
