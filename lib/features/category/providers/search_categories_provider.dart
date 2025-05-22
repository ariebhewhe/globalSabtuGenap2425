import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/features/category/providers/categories_state.dart';

class SearchCategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryRepo _categoryRepo;
  static const int _defaultLimit = 10;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  String _currentSearchQuery = '';
  String _currentSearchBy = 'name';

  SearchCategoriesNotifier(this._categoryRepo) : super(CategoriesState()) {}

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // * Search kategori dengan debounce
  void searchCategories({
    required String query,
    String searchBy = 'name',
    int limit = _defaultLimit,
  }) {
    _currentSearchQuery = query.trim();
    _currentSearchBy = searchBy;

    // * Cancel timer sebelumnya jika ada
    _debounceTimer?.cancel();

    // * Jika query kosong, load semua kategori
    if (_currentSearchQuery.isEmpty) {
      return;
    }

    // * Set debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(limit: limit);
    });
  }

  // * Perform actual search operation
  Future<void> _performSearch({int limit = _defaultLimit}) async {
    if (_currentSearchQuery.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _categoryRepo.searchCategories(
      searchBy: _currentSearchBy,
      searchQuery: _currentSearchQuery,
      limit: limit,
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

  // * Load more results (untuk pagination)
  Future<void> loadMoreCategories({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    late final result;

    // * Jika ada query search, gunakan search method
    if (_currentSearchQuery.isNotEmpty) {
      result = await _categoryRepo.searchCategories(
        searchBy: _currentSearchBy,
        searchQuery: _currentSearchQuery,
        limit: limit,
        startAfter: state.lastDocument,
      );
    } else {
      // * Jika tidak ada query, gunakan paginated method
      result = await _categoryRepo.getPaginatedCategories(
        limit: limit,
        startAfter: state.lastDocument,
      );
    }

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

  // * Refresh categories
  Future<void> refreshCategories({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(categories: [], lastDocument: null, hasMore: true);

    // * Jika ada query search aktif, lakukan search ulang
    if (_currentSearchQuery.isNotEmpty) {
      await _performSearch(limit: limit);
    }
  }

  // * Clear search and show all categories
  Future<void> clearSearch({int limit = _defaultLimit}) async {
    _currentSearchQuery = '';
    _currentSearchBy = 'name';
    _debounceTimer?.cancel();

    // * Reset state dan load semua kategori
    state = state.copyWith(categories: [], lastDocument: null, hasMore: true);
  }

  // * Get current search query
  String get currentSearchQuery => _currentSearchQuery;

  // * Get current search field
  String get currentSearchBy => _currentSearchBy;
}

final searchCategoriesProvider =
    StateNotifierProvider<SearchCategoriesNotifier, CategoriesState>((ref) {
      final CategoryRepo categoryRepo = ref.watch(categoryRepoProvider);
      return SearchCategoriesNotifier(categoryRepo);
    });
