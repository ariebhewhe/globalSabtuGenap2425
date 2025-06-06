import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/features/category/providers/category_mutation_state.dart';
import 'package:jamal/features/category/providers/category_provider.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';

class CategoryMutationNotifier extends StateNotifier<CategoryMutationState> {
  final CategoryRepo _categoryRepo;
  final Ref _ref;

  CategoryMutationNotifier(this._categoryRepo, this._ref)
    : super(CategoryMutationState());

  Future<void> addCategory(CreateCategoryDto newCategory) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepo.addCategory(newCategory);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.invalidate(categoriesProvider);
        _ref.invalidate(menuItemsProvider);
      },
    );
  }

  Future<void> updateCategory(
    String id,
    UpdateCategoryDto updatedCategory, {
    bool deleteExistingImage = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepo.updateCategory(
      id,
      updatedCategory,
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
        _ref.invalidate(categoriesProvider);
        _ref.invalidate(menuItemsProvider);

        final activeId = _ref.read(activeCategoryIdProvider);
        if (activeId == id) {
          _ref.read(activeCategoryProvider.notifier).refreshCategory();
        }
      },
    );
  }

  Future<void> deleteCategory(String id, {bool deleteImage = true}) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepo.deleteCategory(
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
        _ref.invalidate(categoriesProvider);
        _ref.invalidate(menuItemsProvider);

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeCategoryIdProvider);
        if (activeId == id) {
          _ref.read(activeCategoryIdProvider.notifier).state = null;
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

final categoryMutationProvider =
    StateNotifierProvider<CategoryMutationNotifier, CategoryMutationState>((
      ref,
    ) {
      final CategoryRepo categoryRepo = ref.watch(categoryRepoProvider);
      return CategoryMutationNotifier(categoryRepo, ref);
    });
