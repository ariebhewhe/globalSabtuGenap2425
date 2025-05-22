import 'package:jamal/data/models/user_model.dart';

class UserState {
  final bool isLoading;
  final UserModel? user;
  final String? successMessage;
  final String? errorMessage;

  UserState({
    this.isLoading = false,
    this.user,
    this.successMessage,
    this.errorMessage,
  });

  UserState copyWith({
    bool? isLoading,
    UserModel? user,
    String? successMessage,
    String? errorMessage,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
