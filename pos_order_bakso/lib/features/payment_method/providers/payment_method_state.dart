import 'package:jamal/data/models/payment_method_model.dart';

class PaymentMethodState {
  final bool isLoading;
  final PaymentMethodModel? paymentMethod;
  final String? successMessage;
  final String? errorMessage;

  PaymentMethodState({
    this.isLoading = false,
    this.paymentMethod,
    this.successMessage,
    this.errorMessage,
  });

  PaymentMethodState copyWith({
    bool? isLoading,
    PaymentMethodModel? paymentMethod,
    String? successMessage,
    String? errorMessage,
  }) {
    return PaymentMethodState(
      isLoading: isLoading ?? this.isLoading,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
