import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/data/repositories/payment_method_repo.dart';
import 'package:jamal/features/payment_method/providers/payment_method_mutation_state.dart';
import 'package:jamal/features/payment_method/providers/payment_method_provider.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_provider.dart';

class PaymentMethodMutationNotifier
    extends StateNotifier<PaymentMethodMutationState> {
  final PaymentMethodRepo _paymentMethodRepo;
  final Ref _ref;

  PaymentMethodMutationNotifier(this._paymentMethodRepo, this._ref)
    : super(PaymentMethodMutationState());

  Future<void> addPaymentMethod(CreatePaymentMethodDto newPaymentMethod) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.addPaymentMethod(newPaymentMethod);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
      },
    );
  }

  Future<void> updatePaymentMethod(
    String id,
    UpdatePaymentMethodDto updatedPaymentMethod, {
    bool deleteExistingImage = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.updatePaymentMethod(
      id,
      updatedPaymentMethod,
      deleteExistingImage: deleteExistingImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();

        final activeId = _ref.read(activePaymentMethodIdProvider);
        if (activeId == id) {
          _ref
              .read(activePaymentMethodProvider.notifier)
              .refreshPaymentMethod();
        }
      },
    );
  }

  Future<void> deletePaymentMethod(String id, {bool deleteImage = true}) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.deletePaymentMethod(
      id,
      deleteImage: deleteImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();

        // * Kalo delete clear active item id
        final activeId = _ref.read(activePaymentMethodIdProvider);
        if (activeId == id) {
          _ref.read(activePaymentMethodIdProvider.notifier).state = null;
        }
      },
    );
  }

  // * Reset pesan sukses - gunakan untuk menghindari snackbar muncul berulang
  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  // * Reset pesan error - gunakan untuk menghindari snackbar muncul berulang
  void resetErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

final paymentMethodMutationProvider = StateNotifierProvider<
  PaymentMethodMutationNotifier,
  PaymentMethodMutationState
>((ref) {
  final PaymentMethodRepo paymentMethodRepo = ref.watch(
    paymentMethodRepoProvider,
  );
  return PaymentMethodMutationNotifier(paymentMethodRepo, ref);
});
