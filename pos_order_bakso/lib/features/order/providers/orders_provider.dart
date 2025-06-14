import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/order_repo.dart';
import 'package:jamal/features/order/providers/orders_state.dart';

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepo _orderRepo;
  static const int _defaultLimit = 10;

  OrdersNotifier(this._orderRepo) : super(OrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _orderRepo.getPaginatedOrders(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            orders: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreOrders({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _orderRepo.getPaginatedOrders(
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
            orders: [...state.orders, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshOrders({int limit = 10}) async {
    state = state.copyWith(orders: [], lastDocument: null);
    await loadOrders(limit: limit);
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  final OrderRepo orderRepo = ref.watch(orderRepoProvider);
  return OrdersNotifier(orderRepo);
});
