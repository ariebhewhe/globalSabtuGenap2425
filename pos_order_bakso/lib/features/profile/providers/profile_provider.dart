import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/user_repo.dart';
import 'package:jamal/features/profile/providers/profile_state.dart';

class ProfileMutationNotifier extends StateNotifier<ProfileState> {
  final UserRepo _userRepo;

  ProfileMutationNotifier(this._userRepo) : super(ProfileState()) {}
}

final userMutationProvider =
    StateNotifierProvider<ProfileMutationNotifier, ProfileState>((ref) {
      final UserRepo userRepo = ref.watch(userRepoProvider);

      return ProfileMutationNotifier(userRepo);
    });
