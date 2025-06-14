import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/data/repositories/user_repo.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/features/user/providers/user_mutation_state.dart';
import 'package:jamal/features/user/providers/user_provider.dart';
import 'package:jamal/features/user/providers/users_provider.dart';

class UserMutationNotifier extends StateNotifier<UserMutationState> {
  final UserRepo _userRepo;
  final Ref _ref;

  UserMutationNotifier(this._userRepo, this._ref) : super(UserMutationState());

  Future<void> addUser(UserModel newUser, {File? imageFile}) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.addUser(newUser, imageFile: imageFile);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items list
        _ref.read(usersProvider.notifier).refreshUsers();
      },
    );
  }

  Future<void> updateUser(
    String id,
    UserModel updatedUser, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.updateUser(
      id,
      updatedUser,
      imageFile: imageFile,
      deleteExistingImage: deleteExistingImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items dan menu items
        _ref.read(usersProvider.notifier).refreshUsers();

        final activeId = _ref.read(activeUserIdProvider);
        if (activeId == id) {
          _ref.read(activeUserProvider.notifier).refreshUser();
        }
      },
    );
  }

  Future<void> updateCurrentUser(
    UserModel updatedUser, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.updateCurrentUser(
      updatedUser,
      imageFile: imageFile,
      deleteExistingImage: deleteExistingImage,
    );

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        _ref.invalidate(currentUserProvider);
        _ref.invalidate(authStateProvider);
      },
    );
  }

  Future<void> updateUserPassword(String newPassword) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.updateUserPassword(newPassword);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );
      },
    );
  }

  Future<void> deleteUser(String id, {bool deleteImage = true}) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.deleteUser(id, deleteImage: deleteImage);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: success.message,
        );

        // * Refresh menu items
        _ref.read(usersProvider.notifier).refreshUsers();

        // * Kalo delete clear active item id
        final activeId = _ref.read(activeUserIdProvider);
        if (activeId == id) {
          _ref.read(activeUserIdProvider.notifier).state = null;
        }
      },
    );
  }

  // * Reset pesan sukses - gunakan untuk menghindari snackbar muncul berulang
  void resetSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  // * Reset pesan error - gunakan untuk menghindari snackbar muncul berulang
  void resetErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}

final userMutationProvider =
    StateNotifierProvider<UserMutationNotifier, UserMutationState>((ref) {
      final UserRepo userRepo = ref.watch(userRepoProvider);
      return UserMutationNotifier(userRepo, ref);
    });
