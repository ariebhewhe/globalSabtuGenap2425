import 'package:jamal/data/models/order_model.dart';

class OrderState {
  final bool isLoading;
  final OrderModel? order;
  final String? successMessage;
  final String? errorMessage;

  OrderState({
    this.isLoading = false,
    this.order,
    this.successMessage,
    this.errorMessage,
  });

  OrderState copyWith({
    bool? isLoading,
    OrderModel? order,
    String? successMessage,
    String? errorMessage,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      order: order ?? this.order,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
