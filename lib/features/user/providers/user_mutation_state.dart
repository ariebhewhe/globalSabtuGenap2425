import 'package:jamal/data/models/user_model.dart';

class UserMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final UserModel? userModel;

  UserMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.userModel,
  });

  UserMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? userModel,
  }) {
    return UserMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      userModel: userModel,
    );
  }
}
