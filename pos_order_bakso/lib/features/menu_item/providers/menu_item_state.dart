import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemState {
  final bool isLoading;
  final MenuItemModel? menuItem;
  final String? successMessage;
  final String? errorMessage;

  MenuItemState({
    this.isLoading = false,
    this.menuItem,
    this.successMessage,
    this.errorMessage,
  });

  MenuItemState copyWith({
    bool? isLoading,
    MenuItemModel? menuItem,
    String? successMessage,
    String? errorMessage,
  }) {
    return MenuItemState(
      isLoading: isLoading ?? this.isLoading,
      menuItem: menuItem ?? this.menuItem,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
