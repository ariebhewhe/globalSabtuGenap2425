import 'package:jamal/data/models/user_model.dart';

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final UserModel? userModel;

  ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.userModel,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    UserModel? userModel,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      userModel: userModel ?? this.userModel,
    );
  }
}
