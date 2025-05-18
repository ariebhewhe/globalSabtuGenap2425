import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final MenuItemModel? menuItemModel;

  MenuItemMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.menuItemModel,
  });

  MenuItemMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    MenuItemModel? menuItemModel,
  }) {
    return MenuItemMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      menuItemModel: menuItemModel,
    );
  }
}
