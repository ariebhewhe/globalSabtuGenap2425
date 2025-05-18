import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/payment_method_repo.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_state.dart';

class PaymentMethodsNotifier extends StateNotifier<PaymentMethodsState> {
  final PaymentMethodRepo _paymentMethodRepo;
  static const int _defaultLimit = 10;

  PaymentMethodsNotifier(this._paymentMethodRepo)
    : super(PaymentMethodsState()) {
    loadPaymentMethods();
  }

  Future<void> loadPaymentMethods({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.getPaginatedPaymentMethods(
      limit: limit,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            paymentMethods: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMorePaymentMethods({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _paymentMethodRepo.getPaginatedPaymentMethods(
      limit: limit,
      startAfter: state.lastDocument,
    );

    result.match(
      (error) =>
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: error.message,
          ),
      (success) =>
          state = state.copyWith(
            paymentMethods: [...state.paymentMethods, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshPaymentMethods({int limit = 10}) async {
    state = state.copyWith(paymentMethods: [], lastDocument: null);
    await loadPaymentMethods(limit: limit);
  }
}

final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, PaymentMethodsState>((ref) {
      final PaymentMethodRepo paymentMethodRepo = ref.watch(
        paymentMethodRepoProvider,
      );
      return PaymentMethodsNotifier(paymentMethodRepo);
    });
