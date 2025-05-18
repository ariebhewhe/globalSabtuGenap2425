import 'package:jamal/data/models/cart_item_model.dart';

class CartItemMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final CartItemModel? cartItem;

  CartItemMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.cartItem,
  });

  CartItemMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    CartItemModel? cartItem,
  }) {
    return CartItemMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      cartItem: cartItem,
    );
  }
}
