import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/data/repositories/cart_item_repo.dart';
import 'package:jamal/features/cart/providers/cart_item_aggregate_provider.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_state.dart';
import 'package:jamal/features/cart/providers/cart_item_provider.dart';
import 'package:jamal/features/cart/providers/cart_items_provider.dart';
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';

class CartItemMutationNotifier extends StateNotifier<CartItemMutationState> {
  final CartItemRepo _cartItemRepo;
  final Ref _ref;

  CartItemMutationNotifier(this._cartItemRepo, this._ref)
    : super(CartItemMutationState());

  Future<void> addCartItem(CreateCartItemDto newCartItem) async {
    state = state.copyWith(isLoading: true);

    final result = await _cartItemRepo.addCartItem(newCartItem);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.invalidate(cartItemsProvider);
        _ref.invalidate(selectedCartItemsProvider);
        _ref.invalidate(totalCartQuantityProvider);
        _ref.invalidate(distinctCartItemCountProvider);
      },
    );
  }

  Future<void> updateCartItem(
    String id,
    UpdateCartItemDto updatedCartItem,
  ) async {
    state = state.copyWith(isLoading: true);

    final result = await _cartItemRepo.updateCartItem(id, updatedCartItem);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.invalidate(cartItemsProvider);
        _ref.invalidate(selectedCartItemsProvider);
        _ref.invalidate(totalCartQuantityProvider);
        _ref.invalidate(distinctCartItemCountProvider);

        final activeId = _ref.read(activeCartItemIdProvider);
        if (activeId == id) {
          _ref.read(activeCartItemProvider.notifier).refreshCartItem();
        }
      },
    );
  }

  Future<void> deleteCartItem(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _cartItemRepo.deleteCartItem(id);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.invalidate(cartItemsProvider);
        _ref.invalidate(selectedCartItemsProvider);
        _ref.invalidate(totalCartQuantityProvider);
        _ref.invalidate(distinctCartItemCountProvider);

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeCartItemIdProvider);
        if (activeId == id) {
          _ref.read(activeCartItemIdProvider.notifier).state = null;
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

final cartItemMutationProvider =
    StateNotifierProvider<CartItemMutationNotifier, CartItemMutationState>((
      ref,
    ) {
      final CartItemRepo cartItemRepo = ref.watch(cartItemRepoProvider);
      return CartItemMutationNotifier(cartItemRepo, ref);
    });
