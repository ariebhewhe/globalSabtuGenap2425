import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/features/category/providers/categories_state.dart';

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryRepo _categoryRepo;
  static const int _defaultLimit = 10;

  CategoriesNotifier(this._categoryRepo) : super(CategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepo.getPaginatedCategories(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            categories: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreCategories({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _categoryRepo.getPaginatedCategories(
      limit: limit,
      startAfter: state.lastDocument,
    );

    result.match(
      (error) =>
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: error.message,
          ),
      (success) =>
          state = state.copyWith(
            categories: [...state.categories, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshCategories({int limit = 10}) async {
    state = state.copyWith(categories: [], lastDocument: null);
    await loadCategories(limit: limit);
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
      final CategoryRepo categoryRepo = ref.watch(categoryRepoProvider);
      return CategoriesNotifier(categoryRepo);
    });
