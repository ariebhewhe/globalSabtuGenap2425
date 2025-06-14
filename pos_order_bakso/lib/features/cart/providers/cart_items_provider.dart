import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/cart_item_repo.dart';
import 'package:jamal/features/cart/providers/cart_items_state.dart';

class CartItemsNotifier extends StateNotifier<CartItemsState> {
  final CartItemRepo _cartItemRepo;
  static const int _defaultLimit = 10;

  CartItemsNotifier(this._cartItemRepo) : super(CartItemsState()) {
    loadCartItems();
  }

  Future<void> loadCartItems({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _cartItemRepo.getPaginatedCartItems(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            cartItems: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreCartItems({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _cartItemRepo.getPaginatedCartItems(
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
            cartItems: [...state.cartItems, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshCartItems({int limit = 10}) async {
    state = state.copyWith(cartItems: [], lastDocument: null);
    await loadCartItems(limit: limit);
  }
}

final cartItemsProvider =
    StateNotifierProvider<CartItemsNotifier, CartItemsState>((ref) {
      final CartItemRepo cartItemRepo = ref.watch(cartItemRepoProvider);
      return CartItemsNotifier(cartItemRepo);
    });
