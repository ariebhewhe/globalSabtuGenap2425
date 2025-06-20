import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/user_repo.dart';
import 'package:jamal/features/user/providers/user_state.dart';

class UserNotifier extends StateNotifier<UserState> {
  final UserRepo _userRepo;
  final String _id;

  UserNotifier(this._userRepo, this._id) : super(UserState()) {
    if (_id.isNotEmpty) {
      getUserById(_id);
    }
  }

  Future<void> getUserById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.getUserById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) => state = state.copyWith(isLoading: false, user: success.data),
    );
  }

  Future<void> refreshUser() async {
    if (_id.isNotEmpty) {
      await getUserById(_id);
    }
  }
}

final userProvider =
    StateNotifierProvider.family<UserNotifier, UserState, String>((ref, id) {
      final UserRepo userRepo = ref.watch(userRepoProvider);
      return UserNotifier(userRepo, id);
    });

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeUserIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeUserProvider = StateNotifierProvider<UserNotifier, UserState>((
  ref,
) {
  final UserRepo userRepo = ref.watch(userRepoProvider);
  final id = ref.watch(activeUserIdProvider);

  return UserNotifier(userRepo, id ?? '');
});
