import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/data/repositories/auth_repo.dart';
import 'package:jamal/features/auth/providers/auth_mutation_state.dart';
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
        state = state.copyWith(isLoading: false, userModel: success.data);
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
        state = state.copyWith(isLoading: false, userModel: success.data);
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
