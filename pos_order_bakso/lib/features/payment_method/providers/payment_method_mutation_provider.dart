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
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
      },
    );
  }

  Future<void> updatePaymentMethod(
    String id,
    UpdatePaymentMethodDto updatedPaymentMethod, {
    bool deleteExistingLogo = false,
    bool deleteExistingQrCode = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.updatePaymentMethod(
      id,
      updatedPaymentMethod,
      deleteExistingLogo: deleteExistingLogo,
      deleteExistingQrCode: deleteExistingQrCode,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
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

  Future<void> deletePaymentMethod(
    String id, {
    bool deleteImages = true,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _paymentMethodRepo.deletePaymentMethod(
      id,
      deleteImages: deleteImages,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
        final activeId = _ref.read(activePaymentMethodIdProvider);
        if (activeId == id) {
          _ref.read(activePaymentMethodIdProvider.notifier).state = null;
        }
      },
    );
  }

  Future<void> batchAddPaymentMethods(List<CreatePaymentMethodDto> dtos) async {
    state = state.copyWith(isLoading: true);
    final result = await _paymentMethodRepo.batchAddPaymentMethods(dtos);
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(paymentMethodsProvider);
      },
    );
  }

  Future<void> batchDeletePaymentMethods(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _paymentMethodRepo.batchDeletePaymentMethods(
      ids,
      deleteImages: deleteImages,
    );
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(paymentMethodsProvider);

        final activeId = _ref.read(activePaymentMethodIdProvider);
        if (activeId != null && ids.contains(activeId)) {
          _ref.read(activePaymentMethodIdProvider.notifier).state = null;
        }
      },
    );
  }

  Future<void> deleteAllPaymentMethods() async {
    state = state.copyWith(isLoading: true);
    final result = await _paymentMethodRepo.deleteAllPaymentMethods();
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(paymentMethodsProvider);
        _ref.read(activePaymentMethodIdProvider.notifier).state = null;
      },
    );
  }

  Future<void> seedPaymentMethods() async {
    state = state.copyWith(isLoading: true);
    final result = await _paymentMethodRepo.seedPaymentMethods();
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // Invalidate list provider dan reset ID aktif
        // karena semua data lama telah dihapus.
        _ref.invalidate(paymentMethodsProvider);
        _ref.read(activePaymentMethodIdProvider.notifier).state = null;
      },
    );
  }

  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

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
