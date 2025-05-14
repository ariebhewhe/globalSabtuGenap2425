import 'package:firebase_auth/firebase_auth.dart';

import 'package:jamal/data/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  // * Jangan lupa parse User ke user model
  final UserModel? userModel;
  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.userModel,
  });

  // * Gak perlu method lainnya setelah ini soalnya cuma auth state
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? userModel,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      userModel: userModel ?? this.userModel,
    );
  }
}
