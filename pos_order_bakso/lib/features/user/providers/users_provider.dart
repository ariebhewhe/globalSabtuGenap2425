import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/user_repo.dart';
import 'package:jamal/features/user/providers/users_state.dart';

class UsersNotifier extends StateNotifier<UsersState> {
  final UserRepo _userRepo;
  static const int _defaultLimit = 10;

  UsersNotifier(this._userRepo) : super(UsersState()) {
    loadUsers();
  }

  Future<void> loadUsers({int limit = _defaultLimit}) async {
    state = state.copyWith(isLoading: true);

    final result = await _userRepo.getPaginatedUsers(limit: limit);

    result.match(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(
            users: success.data.items,
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoading: false,
          ),
    );
  }

  Future<void> loadMoreUsers({int limit = 10}) async {
    // * Jika sedang loading atau tidak ada lagi data, return
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _userRepo.getPaginatedUsers(
      limit: limit,
      startAfter: state.lastDocument,
    );

    result.match(
      (error) =>
          state = state.copyWith(
            isLoadingMore: false,
            errorMessage: error.message,
          ),
      (success) =>
          state = state.copyWith(
            users: [...state.users, ...success.data.items],
            hasMore: success.data.hasMore,
            lastDocument: success.data.lastDocument,
            isLoadingMore: false,
          ),
    );
  }

  Future<void> refreshUsers({int limit = 10}) async {
    state = state.copyWith(users: [], lastDocument: null);
    await loadUsers(limit: limit);
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final UserRepo userRepo = ref.watch(userRepoProvider);
  return UsersNotifier(userRepo);
});
