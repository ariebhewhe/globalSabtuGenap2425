import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart';

class SelectedCartItemsNotifier extends StateNotifier<List<CartItemModel>> {
  SelectedCartItemsNotifier() : super([]);

  void addCartItem(CartItemModel cartItem) {
    final existingIndex = state.indexWhere((item) => item.id == cartItem.id);

    if (existingIndex >= 0) {
      return;
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

  void toggleSelection(CartItemModel cartItem) {
    final isSelected = state.any((item) => item.id == cartItem.id);

    if (isSelected) {
      deleteCartItem(cartItem);
    } else {
      addCartItem(cartItem);
    }
  }

  bool isSelected(CartItemModel cartItem) {
    return state.any((item) => item.id == cartItem.id);
  }

  int get selectedCount => state.length;
}

final selectedCartItemsProvider =
    StateNotifierProvider<SelectedCartItemsNotifier, List<CartItemModel>>((
      ref,
    ) {
      return SelectedCartItemsNotifier();
    });

final isCartItemSelectedProvider = Provider.family<bool, String>((ref, itemId) {
  final selectedItems = ref.watch(selectedCartItemsProvider);
  return selectedItems.any((item) => item.id == itemId);
});
