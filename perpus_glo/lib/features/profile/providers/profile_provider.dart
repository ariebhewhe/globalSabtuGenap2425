import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../model/user_profile_model.dart';
import '../../history/data/history_repository.dart';
import '../../history/model/history_model.dart';

// Provider for current user profile
final userProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentUserProfile();
});

// Provider for profile loading state
final profileLoadingProvider = StateProvider<bool>((ref) => false);

// Controller for profile actions
class ProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final HistoryRepository _historyRepository;

  ProfileController(this._repository, this._historyRepository) 
      : super(const AsyncValue.data(null));

  Future<void> updateProfile(UserProfileModel profile) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveUserProfile(profile);
      
      // Record activity
      await _historyRepository.addActivity(
        activityType: ActivityType.updateProfile,
        description: 'Profil berhasil diperbarui',
        metadata: {
          'name': profile.name,
          'email': profile.email,
        },
      );
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Future<void> updateProfilePicture(File imageFile) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     final photoUrl = await _repository.updateProfilePicture(imageFile);
      
  //     // Record activity
  //     await _historyRepository.addActivity(
  //       activityType: ActivityType.updateProfile,
  //       description: 'Foto profil berhasil diperbarui',
  //     );
      
  //     state = const AsyncValue.data(null);
  //   } catch (e, stack) {
  //     state = AsyncValue.error(e, stack);
  //   }
  // }

  Future<void> updateEmail(String newEmail, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateEmail(newEmail, password);
      
      // Record activity
      await _historyRepository.addActivity(
        activityType: ActivityType.updateProfile,
        description: 'Email berhasil diperbarui ke $newEmail',
      );
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePassword(currentPassword, newPassword);
      
      // Record activity
      await _historyRepository.addActivity(
        activityType: ActivityType.updateProfile,
        description: 'Password berhasil diperbarui',
      );
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAccount(String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAccount(password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for ProfileController
final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  final historyRepository = ref.watch(historyRepositoryProvider);
  return ProfileController(repository, historyRepository);
});