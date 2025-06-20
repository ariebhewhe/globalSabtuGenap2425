import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/cart_item_repo.dart';

final totalCartQuantityProvider = FutureProvider<int>((ref) async {
  final cartRepo = ref.watch(cartItemRepoProvider);
  final result = await cartRepo.getTotalCartQuantity();

  return result.fold((error) => 0, (success) => success.data);
});

final distinctCartItemCountProvider = FutureProvider<int>((ref) async {
  final cartRepo = ref.watch(cartItemRepoProvider);
  final result = await cartRepo.getDistinctItemCountInCart();

  return result.fold((error) => 0, (success) => success.data);
});
