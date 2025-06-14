import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/order_repo.dart';
import 'package:jamal/features/order/providers/order_state.dart';

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepo _orderRepo;
  final String _id;

  OrderNotifier(this._orderRepo, this._id) : super(OrderState()) {
    if (_id.isNotEmpty) {
      getOrderById(_id);
    }
  }

  Future<void> getOrderById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _orderRepo.getOrderById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, order: success.data),
    );
  }

  Future<void> refreshOrder() async {
    if (_id.isNotEmpty) {
      await getOrderById(_id);
    }
  }
}

final orderProvider =
    StateNotifierProvider.family<OrderNotifier, OrderState, String>((ref, id) {
      final OrderRepo orderRepo = ref.watch(orderRepoProvider);
      return OrderNotifier(orderRepo, id);
    });

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeOrderIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeOrderProvider = StateNotifierProvider<OrderNotifier, OrderState>((
  ref,
) {
  final OrderRepo orderRepo = ref.watch(orderRepoProvider);
  final id = ref.watch(activeOrderIdProvider);

  return OrderNotifier(orderRepo, id ?? '');
});
