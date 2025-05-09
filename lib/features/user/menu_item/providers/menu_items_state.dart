import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemsState {
  final bool isLoading;
  final List<MenuItemModel> menuItems;
  final String? successMessage;
  final String? errorMessage;

  MenuItemsState({
    this.isLoading = false,
    this.menuItems = const [],
    this.successMessage,
    this.errorMessage,
  });

  MenuItemsState copyWith({
    bool? isLoading,
    List<MenuItemModel>? menuItems,
    String? successMessage,
    String? errorMessage,
  }) {
    return MenuItemsState(
      isLoading: isLoading ?? this.isLoading,
      menuItems: menuItems ?? this.menuItems,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
