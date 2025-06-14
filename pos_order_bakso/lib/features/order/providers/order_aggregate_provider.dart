import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/order_repo.dart';

final ordersCountProvider = FutureProvider.autoDispose<OrdersCountAggregate>((
  ref,
) async {
  final orderRepo = ref.watch(orderRepoProvider);
  final result = await orderRepo.getOrdersCount();

  return result.fold((error) {
    return OrdersCountAggregate(
      totalOrders: 0,
      statusCounts: {},
      typeCounts: {},
    );
  }, (success) => success.data);
});

final orderRevenueProvider = FutureProvider.autoDispose<OrdersRevenueAggregate>(
  (ref) async {
    final orderRepo = ref.watch(orderRepoProvider);
    final result = await orderRepo.getOrderRevenue();

    return result.fold((error) {
      return OrdersRevenueAggregate(
        totalRevenueAllTime: 0.0,
        totalRevenueToday: 0.0,
        totalRevenueThisMonth: 0.0,
        totalRevenueThisYear: 0.0,
      );
    }, (success) => success.data);
  },
);
