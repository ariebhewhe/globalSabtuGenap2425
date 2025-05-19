import 'package:jamal/data/models/restaurant_table_model.dart';

class RestaurantTableMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final RestaurantTableModel? restaurantTableModel;

  RestaurantTableMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.restaurantTableModel,
  });

  RestaurantTableMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    RestaurantTableModel? restaurantTableModel,
  }) {
    return RestaurantTableMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      restaurantTableModel: restaurantTableModel,
    );
  }
}
