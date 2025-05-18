import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/data/repositories/order_repo.dart';
import 'package:jamal/features/order/providers/order_mutation_state.dart';
import 'package:jamal/features/order/providers/order_provider.dart';
import 'package:jamal/features/order/providers/orders_provider.dart';

class OrderMutationNotifier extends StateNotifier<OrderMutationState> {
  final OrderRepo _orderRepo;
  final Ref _ref;

  OrderMutationNotifier(this._orderRepo, this._ref)
    : super(OrderMutationState());

  Future<void> addOrder(CreateOrderDto newOrder) async {
    state = state.copyWith(isLoading: true);

    final result = await _orderRepo.addOrder(newOrder);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.read(ordersProvider.notifier).refreshOrders();
      },
    );
  }

  Future<void> updateOrder(String id, UpdateOrderDto updatedOrder) async {
    state = state.copyWith(isLoading: true);

    final result = await _orderRepo.updateOrder(id, updatedOrder);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.read(ordersProvider.notifier).refreshOrders();

        final activeId = _ref.read(activeOrderIdProvider);
        if (activeId == id) {
          _ref.read(activeOrderProvider.notifier).refreshOrder();
        }
      },
    );
  }

  Future<void> deleteOrder(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _orderRepo.deleteOrder(id);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.read(ordersProvider.notifier).refreshOrders();

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeOrderIdProvider);
        if (activeId == id) {
          _ref.read(activeOrderIdProvider.notifier).state = null;
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

final orderMutationProvider =
    StateNotifierProvider<OrderMutationNotifier, OrderMutationState>((ref) {
      final OrderRepo orderRepo = ref.watch(orderRepoProvider);
      return OrderMutationNotifier(orderRepo, ref);
    });
