import 'package:jamal/data/models/user_model.dart';

class AuthMutationState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? userModel;

  AuthMutationState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.userModel,
  });

  // * Gak perlu method lainnya setelah ini soalnya cuma auth state
  AuthMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? userModel,
  }) {
    return AuthMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      userModel: userModel ?? this.userModel,
    );
  }
}
