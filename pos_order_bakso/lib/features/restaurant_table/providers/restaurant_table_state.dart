import 'package:jamal/data/models/restaurant_table_model.dart';

class RestaurantTableState {
  final bool isLoading;
  final RestaurantTableModel? restaurantTable;
  final String? successMessage;
  final String? errorMessage;

  RestaurantTableState({
    this.isLoading = false,
    this.restaurantTable,
    this.successMessage,
    this.errorMessage,
  });

  RestaurantTableState copyWith({
    bool? isLoading,
    RestaurantTableModel? restaurantTable,
    String? successMessage,
    String? errorMessage,
  }) {
    return RestaurantTableState(
      isLoading: isLoading ?? this.isLoading,
      restaurantTable: restaurantTable ?? this.restaurantTable,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
