import 'package:jamal/data/models/cart_item_model.dart';

class CartItemState {
  final bool isLoading;
  final CartItemModel? cartItem;
  final String? successMessage;
  final String? errorMessage;

  CartItemState({
    this.isLoading = false,
    this.cartItem,
    this.successMessage,
    this.errorMessage,
  });

  CartItemState copyWith({
    bool? isLoading,
    CartItemModel? cartItem,
    String? successMessage,
    String? errorMessage,
  }) {
    return CartItemState(
      isLoading: isLoading ?? this.isLoading,
      cartItem: cartItem ?? this.cartItem,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
