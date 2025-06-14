import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/features/category/providers/categories_state.dart';

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryRepo _categoryRepo;
  static const int _defaultLimit = 10;

  // * Current filter settings
  String _currentOrderBy = 'createdAt';
  bool _currentDescending = true;

  CategoriesNotifier(this._categoryRepo) : super(CategoriesState()) {
    loadCategories();
  }

  // * Load categories with current filter settings
  Future<void> loadCategories({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _categoryRepo.getPaginatedCategories(
      limit: limit,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            categories: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load categories with specific filter
  Future<void> loadCategoriesWithFilter({
    String orderBy = 'createdAt',
    bool descending = true,
    int limit = _defaultLimit,
  }) async {
    // * Update current filter settings
    _currentOrderBy = orderBy;
    _currentDescending = descending;

    // * Reset state and load with new filter
    state = state.copyWith(
      categories: [],
      lastDocument: null,
      hasMore: true,
      isLoading: true,
      errorMessage: null,
    );

    final result = await _categoryRepo.getPaginatedCategories(
      limit: limit,
      orderBy: orderBy,
      descending: descending,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            categories: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load more categories with current filter
  Future<void> loadMoreCategories({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _categoryRepo.getPaginatedCategories(
      limit: limit,
      startAfter: state.lastDocument,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
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
            errorMessage: null,
          ),
    );
  }

  // * Refresh categories with current filter
  Future<void> refreshCategories({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(categories: [], lastDocument: null, hasMore: true);

    await loadCategories(limit: limit);
  }

  // * Reset filter to default and reload
  Future<void> resetFilter({int limit = _defaultLimit}) async {
    _currentOrderBy = 'createdAt';
    _currentDescending = true;

    // * Reset state
    state = state.copyWith(categories: [], lastDocument: null, hasMore: true);

    await loadCategories(limit: limit);
  }

  // * Get current filter settings
  String get currentOrderBy => _currentOrderBy;
  bool get currentDescending => _currentDescending;

  // * Check if using default filter
  bool get isUsingDefaultFilter =>
      _currentOrderBy == 'createdAt' && _currentDescending == true;
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
      final categoryRepo = ref.watch(categoryRepoProvider);
      return CategoriesNotifier(categoryRepo);
    });
