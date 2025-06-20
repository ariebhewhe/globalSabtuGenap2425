import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';
import '../model/payment_model.dart';

// Provider untuk stream riwayat pembayaran user
final userPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getUserPayments();
});

// Provider untuk detail pembayaran berdasarkan ID
final paymentByIdProvider =
    FutureProvider.family<PaymentModel?, String>((ref, paymentId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentById(paymentId);
});

// Controller untuk aksi pembayaran
class PaymentController extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repository;

  PaymentController(this._repository) : super(const AsyncValue.data(null));

  Future<PaymentModel?> createPayment(String borrowId, double amount) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repository.createPayment(borrowId, amount);
      state = const AsyncValue.data(null);
      return payment;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> completePayment(String paymentId, String paymentMethod) async {
    state = const AsyncValue.loading();
    try {
      print('PaymentController: Starting payment completion for ID $paymentId');
      print('PaymentController: Using payment method $paymentMethod');

      await _repository.completePayment(paymentId, paymentMethod);

      print('PaymentController: Payment completed successfully');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      print('PaymentController: Error completing payment: $e');
      print('PaymentController: Stack trace: $stack');
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> cancelPayment(String paymentId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePaymentStatus(paymentId, PaymentStatus.cancelled);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentController(repository);
});