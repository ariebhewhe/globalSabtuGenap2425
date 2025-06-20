import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart'; // Pastikan path model Anda benar

class SelectedCartItemsNotifier extends StateNotifier<List<CartItemModel>> {
  SelectedCartItemsNotifier() : super([]);

  void initializeSelection(List<CartItemModel> items) {
    state = List.from(items);
  }

  void toggleSelection(CartItemModel cartItem) {
    if (state.any((item) => item.id == cartItem.id)) {
      state = state.where((item) => item.id != cartItem.id).toList();
    } else {
      state = [...state, cartItem];
    }
  }

  void deleteCartItem(CartItemModel cartItem) {
    state = state.where((item) => item.id != cartItem.id).toList();
  }

  void clearSelectedItems() {
    state = [];
  }

  bool isSelected(CartItemModel cartItem) {
    return state.any((item) => item.id == cartItem.id);
  }
}

final selectedCartItemsProvider =
    StateNotifierProvider<SelectedCartItemsNotifier, List<CartItemModel>>(
      (ref) => SelectedCartItemsNotifier(),
    );
