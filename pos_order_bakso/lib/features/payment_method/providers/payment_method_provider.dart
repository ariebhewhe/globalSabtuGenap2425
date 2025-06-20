import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/payment_method_repo.dart';
import 'package:jamal/features/payment_method/providers/payment_method_state.dart';

class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  final PaymentMethodRepo _paymentMethodRepo;
  final String _id;

  PaymentMethodNotifier(this._paymentMethodRepo, this._id)
    : super(PaymentMethodState()) {
    if (_id.isNotEmpty) {
      getPaymentMethodById(_id);
    }
  }

  Future<void> getPaymentMethodById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.getPaymentMethodById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, paymentMethod: success.data),
    );
  }

  Future<void> refreshPaymentMethod() async {
    if (_id.isNotEmpty) {
      await getPaymentMethodById(_id);
    }
  }
}

final paymentMethodProvider = StateNotifierProvider.family<
  PaymentMethodNotifier,
  PaymentMethodState,
  String
>((ref, id) {
  final PaymentMethodRepo paymentMethodRepo = ref.watch(
    paymentMethodRepoProvider,
  );
  return PaymentMethodNotifier(paymentMethodRepo, id);
});

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activePaymentMethodIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activePaymentMethodProvider =
    StateNotifierProvider<PaymentMethodNotifier, PaymentMethodState>((ref) {
      final PaymentMethodRepo paymentMethodRepo = ref.watch(
        paymentMethodRepoProvider,
      );
      final id = ref.watch(activePaymentMethodIdProvider);

      return PaymentMethodNotifier(paymentMethodRepo, id ?? '');
    });
