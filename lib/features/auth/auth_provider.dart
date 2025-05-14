import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/data/repositories/auth_repo.dart';
import 'package:jamal/features/auth/providers/auth_state.dart';
import 'package:jamal/providers.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepo _authRepo;
  final Ref _ref;

  AuthNotifier(this._authRepo, this._ref) : super(AuthState());

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

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.logout();

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) => state = AuthState(),
    );
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    final result = await _authRepo.getCurrentUser();

    state = state.copyWith(userModel: result);
  }

  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  void resetErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final AuthRepo authRepo = ref.watch(authRepoProvider);

  return AuthNotifier(authRepo, ref);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final FirebaseAuth authState = ref.watch(firebaseAuthProvider);

  return authState.authStateChanges();
});
