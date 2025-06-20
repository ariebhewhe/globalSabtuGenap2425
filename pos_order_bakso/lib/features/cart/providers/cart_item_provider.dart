import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/cart_item_repo.dart';
import 'package:jamal/features/cart/providers/cart_item_state.dart';

class CartItemNotifier extends StateNotifier<CartItemState> {
  final CartItemRepo _cartItemRepo;
  final String _id;

  CartItemNotifier(this._cartItemRepo, this._id) : super(CartItemState()) {
    if (_id.isNotEmpty) {
      getCartItemById(_id);
    }
  }

  Future<void> getCartItemById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _cartItemRepo.getCartItemById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, cartItem: success.data),
    );
  }

  Future<void> refreshCartItem() async {
    if (_id.isNotEmpty) {
      await getCartItemById(_id);
    }
  }
}

final cartItemProvider =
    StateNotifierProvider.family<CartItemNotifier, CartItemState, String>((
      ref,
      id,
    ) {
      final CartItemRepo cartItemRepo = ref.watch(cartItemRepoProvider);
      return CartItemNotifier(cartItemRepo, id);
    });

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeCartItemIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeCartItemProvider =
    StateNotifierProvider<CartItemNotifier, CartItemState>((ref) {
      final CartItemRepo cartItemRepo = ref.watch(cartItemRepoProvider);
      final id = ref.watch(activeCartItemIdProvider);

      return CartItemNotifier(cartItemRepo, id ?? '');
    });
