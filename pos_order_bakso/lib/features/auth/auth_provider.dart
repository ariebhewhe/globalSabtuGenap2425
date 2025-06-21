import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/data/repositories/auth_repo.dart';
import 'package:jamal/features/auth/providers/auth_mutation_state.dart';
import 'package:jamal/features/cart/providers/cart_item_aggregate_provider.dart';
import 'package:jamal/features/cart/providers/cart_items_provider.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_aggregate_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/features/order/providers/order_aggregate_provider.dart';
import 'package:jamal/features/order/providers/orders_provider.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_provider.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_provider.dart';
import 'package:jamal/features/table_reservation/providers/table_reservations_provider.dart';
import 'package:jamal/features/user/providers/user_aggregate_provider.dart';
import 'package:jamal/providers.dart';

class AuthMutationNotifier extends StateNotifier<AuthMutationState> {
  final AuthRepo _authRepo;
  final Ref _ref;

  AuthMutationNotifier(this._authRepo, this._ref)
    : super(AuthMutationState()) {}

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    final userModel = UserModel(
      id: '',
      username: username,
      email: email,
      password: password,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _authRepo.register(userModel, password);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) async {
        state = state.copyWith(isLoading: false, userModel: success.data);
      },
    );
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.loginWithEmail(email, password);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) async {
        state = await state.copyWith(isLoading: false, userModel: success.data);

        _ref.invalidate(currentUserProvider);

        _ref.read(cartItemsProvider.notifier).refreshCartItems();
        _ref.read(menuItemsProvider.notifier).refreshMenuItems();
        _ref.read(categoriesProvider.notifier).refreshCategories();
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
        _ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();
        _ref.read(ordersProvider.notifier).refreshOrders();
        _ref
            .read(tableReservationsProvider.notifier)
            .refreshTableReservations();
      },
    );
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.loginWithGoogle();

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) async {
        state = await state.copyWith(isLoading: false, userModel: success.data);

        _ref.invalidate(currentUserProvider);

        _ref.read(cartItemsProvider.notifier).refreshCartItems();
        _ref.read(menuItemsProvider.notifier).refreshMenuItems();
        _ref.read(categoriesProvider.notifier).refreshCategories();
        _ref.read(paymentMethodsProvider.notifier).refreshPaymentMethods();
        _ref.read(restaurantTablesProvider.notifier).refreshRestaurantTables();
        _ref.read(ordersProvider.notifier).refreshOrders();
        _ref
            .read(tableReservationsProvider.notifier)
            .refreshTableReservations();
      },
    );
  }

  Future<void> updateCurrentUser(UserModel user) async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.updateCurrentUser(user);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) async {
        _ref.invalidate(currentUserProvider);
        _ref.invalidate(authStateProvider);
        state = state.copyWith(isLoading: false, userModel: success.data);
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.logout();

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        _ref.invalidate(currentUserProvider);
        _ref.invalidate(authStateProvider);
        // Todo: Harusnya invalidate semua entah kenapa malah error

        _ref.invalidate(orderRevenueProvider);
        _ref.invalidate(totalCartQuantityProvider);
        _ref.invalidate(distinctCartItemCountProvider);
        _ref.invalidate(ordersCountProvider);
        _ref.invalidate(usersCountProvider);
        _ref.invalidate(menuItemsCountProvider);
        return state = AuthMutationState();
      },
    );
  }

  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  void resetErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

final authMutationProvider =
    StateNotifierProvider<AuthMutationNotifier, AuthMutationState>((ref) {
      final AuthRepo authRepo = ref.watch(authRepoProvider);

      return AuthMutationNotifier(authRepo, ref);
    });

final authStateProvider = StreamProvider<User?>((ref) {
  final FirebaseAuth authState = ref.watch(firebaseAuthProvider);

  return authState.authStateChanges();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final AuthRepo authRepo = ref.watch(authRepoProvider);
  final UserModel? userModel = await authRepo.getCurrentUser();

  return userModel;
});
