import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/payment_method_repo.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_state.dart';

class PaymentMethodsNotifier extends StateNotifier<PaymentMethodsState> {
  final PaymentMethodRepo _paymentMethodRepo;
  static const int _defaultLimit = 10;

  // * Current filter settings
  String _currentOrderBy = 'createdAt';
  bool _currentDescending = true;

  PaymentMethodsNotifier(this._paymentMethodRepo)
    : super(PaymentMethodsState()) {
    loadPaymentMethods();
  }

  // * Load paymentMethods with current filter settings
  Future<void> loadPaymentMethods({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _paymentMethodRepo.getPaginatedPaymentMethods(
      limit: limit,
      orderBy: _currentOrderBy,
      descending: _currentDescending,
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

  // * Load paymentMethods with specific filter
  Future<void> loadPaymentMethodsWithFilter({
    String orderBy = 'createdAt',
    bool descending = true,
    int limit = _defaultLimit,
  }) async {
    // * Update current filter settings
    _currentOrderBy = orderBy;
    _currentDescending = descending;

    // * Reset state and load with new filter
    state = state.copyWith(
      paymentMethods: [],
      lastDocument: null,
      hasMore: true,
      isLoading: true,
      errorMessage: null,
    );

    final result = await _paymentMethodRepo.getPaginatedPaymentMethods(
      limit: limit,
      orderBy: orderBy,
      descending: descending,
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

  // * Load more paymentMethods with current filter
  Future<void> loadMorePaymentMethods({int limit = _defaultLimit}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _paymentMethodRepo.getPaginatedPaymentMethods(
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
            paymentMethods: [...state.paymentMethods, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
            errorMessage: null,
          ),
    );
  }

  // * Refresh paymentMethods with current filter
  Future<void> refreshPaymentMethods({int limit = _defaultLimit}) async {
    // * Reset state
    state = state.copyWith(
      paymentMethods: [],
      lastDocument: null,
      hasMore: true,
    );

    await loadPaymentMethods(limit: limit);
  }

  // * Reset filter to default and reload
  Future<void> resetFilter({int limit = _defaultLimit}) async {
    _currentOrderBy = 'createdAt';
    _currentDescending = true;

    // * Reset state
    state = state.copyWith(
      paymentMethods: [],
      lastDocument: null,
      hasMore: true,
    );

    await loadPaymentMethods(limit: limit);
  }

  // * Get current filter settings
  String get currentOrderBy => _currentOrderBy;
  bool get currentDescending => _currentDescending;

  // * Check if using default filter
  bool get isUsingDefaultFilter =>
      _currentOrderBy == 'createdAt' && _currentDescending == true;
}

final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, PaymentMethodsState>((ref) {
      final paymentMethodRepo = ref.watch(paymentMethodRepoProvider);
      return PaymentMethodsNotifier(paymentMethodRepo);
    });
