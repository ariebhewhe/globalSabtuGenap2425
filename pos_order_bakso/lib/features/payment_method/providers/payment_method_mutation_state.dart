import 'package:jamal/data/models/payment_method_model.dart';

class PaymentMethodMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final PaymentMethodModel? paymentMethodModel;

  PaymentMethodMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.paymentMethodModel,
  });

  PaymentMethodMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    PaymentMethodModel? paymentMethodModel,
  }) {
    return PaymentMethodMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      paymentMethodModel: paymentMethodModel,
    );
  }
}
