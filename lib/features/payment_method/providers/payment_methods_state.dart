import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/payment_method_model.dart';

class PaymentMethodsState {
  final List<PaymentMethodModel> paymentMethods;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  PaymentMethodsState({
    this.paymentMethods = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  PaymentMethodsState copyWith({
    List<PaymentMethodModel>? paymentMethods,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return PaymentMethodsState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
