import 'package:jamal/data/models/order_model.dart';

class OrderMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final OrderModel? order;

  OrderMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.order,
  });

  OrderMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    OrderModel? order,
  }) {
    return OrderMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      order: order,
    );
  }
}
