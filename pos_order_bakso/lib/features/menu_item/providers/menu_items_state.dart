import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemsState {
  final List<MenuItemModel> menuItems;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  MenuItemsState({
    this.menuItems = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  MenuItemsState copyWith({
    List<MenuItemModel>? menuItems,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return MenuItemsState(
      menuItems: menuItems ?? this.menuItems,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
