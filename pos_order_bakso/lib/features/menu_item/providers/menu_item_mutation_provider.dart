import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/data/repositories/menu_item_repo.dart';
import 'package:jamal/features/cart/providers/cart_items_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_state.dart';
import 'package:jamal/features/menu_item/providers/menu_item_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';

class MenuItemMutationNotifier extends StateNotifier<MenuItemMutationState> {
  final MenuItemRepo _menuItemRepo;
  final Ref _ref;

  MenuItemMutationNotifier(this._menuItemRepo, this._ref)
    : super(MenuItemMutationState());

  Future<void> addMenuItem(CreateMenuItemDto newMenuItem) async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.addMenuItem(newMenuItem);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.invalidate(menuItemsProvider);
      },
    );
  }

  Future<void> updateMenuItem(
    String id,
    UpdateMenuItemDto updatedMenuItem, {
    bool deleteExistingImage = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.updateMenuItem(
      id,
      updatedMenuItem,
      deleteExistingImage: deleteExistingImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.invalidate(menuItemsProvider);

        final activeId = _ref.read(activeMenuItemIdProvider);
        if (activeId == id) {
          _ref.read(activeMenuItemProvider.notifier).refreshMenuItem();
        }
      },
    );
  }

  Future<void> deleteMenuItem(String id, {bool deleteImage = true}) async {
    state = state.copyWith(isLoading: true);

    final result = await _menuItemRepo.deleteMenuItem(
      id,
      deleteImage: deleteImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.invalidate(menuItemsProvider);
        _ref.invalidate(cartItemsProvider);

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeMenuItemIdProvider);
        if (activeId == id) {
          _ref.read(activeMenuItemIdProvider.notifier).state = null;
        }
      },
    );
  }

  Future<void> batchAddMenuItems(List<CreateMenuItemDto> dtos) async {
    state = state.copyWith(isLoading: true);
    final result = await _menuItemRepo.batchAddMenuItems(dtos);
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(menuItemsProvider);
      },
    );
  }

  Future<void> batchDeleteMenuItems(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _menuItemRepo.batchDeleteMenuItems(
      ids,
      deleteImages: deleteImages,
    );
    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
        _ref.invalidate(menuItemsProvider);
        _ref.invalidate(cartItemsProvider);

        final activeId = _ref.read(activeMenuItemIdProvider);
        if (activeId != null && ids.contains(activeId)) {
          _ref.read(activeMenuItemIdProvider.notifier).state = null;
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

final menuItemMutationProvider =
    StateNotifierProvider<MenuItemMutationNotifier, MenuItemMutationState>((
      ref,
    ) {
      final MenuItemRepo menuItemRepo = ref.watch(menuItemRepoProvider);
      return MenuItemMutationNotifier(menuItemRepo, ref);
    });
