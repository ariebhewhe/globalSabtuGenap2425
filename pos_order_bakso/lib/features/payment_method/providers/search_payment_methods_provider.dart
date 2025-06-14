import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/payment_method_repo.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_state.dart';

class SearchPaymentMethodsNotifier extends StateNotifier<PaymentMethodsState> {
  final PaymentMethodRepo _paymentMethodRepo;
  static const int _defaultLimit = 10;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounceTimer;
  String _currentSearchQuery = '';
  String _currentSearchBy = 'name';

  SearchPaymentMethodsNotifier(this._paymentMethodRepo)
    : super(PaymentMethodsState()) {}

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // * Search kategori dengan debounce
  void searchPaymentMethods({
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

    final result = await _paymentMethodRepo.searchPaymentMethods(
      searchBy: _currentSearchBy,
      searchQuery: _currentSearchQuery,
      limit: limit,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            paymentMethods: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
            errorMessage: null,
          ),
    );
  }

  // * Load more results (untuk pagination)
  Future<void> loadMorePaymentMethods({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    late final result;

    // * Jika ada query search, gunakan search method
    if (_currentSearchQuery.isNotEmpty) {
      result = await _paymentMethodRepo.searchPaymentMethods(
        searchBy: _currentSearchBy,
        searchQuery: _currentSearchQuery,
        limit: limit,
        startAfter: state.lastDocument,
      );
    } else {
      // * Jika tidak ada query, gunakan paginated method
      result = await _paymentMethodRepo.getPaginatedPaymentMethods(
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
            paymentMethods: [...state.paymentMethods, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
            errorMessage: null,
          ),
    );
  }

  // * Refresh paymentMethods
  Future<void> refreshPaymentMethods({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(
      paymentMethods: [],
      lastDocument: null,
      hasMore: true,
    );

    // * Jika ada query search aktif, lakukan search ulang
    if (_currentSearchQuery.isNotEmpty) {
      await _performSearch(limit: limit);
    }
  }

  // * Clear search and show all paymentMethods
  Future<void> clearSearch({int limit = _defaultLimit}) async {
    _currentSearchQuery = '';
    _currentSearchBy = 'name';
    _debounceTimer?.cancel();

    // * Reset state dan load semua kategori
    state = state.copyWith(
      paymentMethods: [],
      lastDocument: null,
      hasMore: true,
    );
  }

  // * Get current search query
  String get currentSearchQuery => _currentSearchQuery;

  // * Get current search field
  String get currentSearchBy => _currentSearchBy;
}

final searchPaymentMethodsProvider =
    StateNotifierProvider<SearchPaymentMethodsNotifier, PaymentMethodsState>((
      ref,
    ) {
      final PaymentMethodRepo paymentMethodRepo = ref.watch(
        paymentMethodRepoProvider,
      );
      return SearchPaymentMethodsNotifier(paymentMethodRepo);
    });
