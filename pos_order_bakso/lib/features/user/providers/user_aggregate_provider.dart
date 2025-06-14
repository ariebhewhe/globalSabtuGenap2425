import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/user_repo.dart';

final usersCountProvider = FutureProvider<UsersCountAggregate>((ref) async {
  final userRepo = ref.watch(userRepoProvider);
  final result = await userRepo.getUsersCount();

  return result.fold(
    (error) =>
        UsersCountAggregate(allUserCount: 0, adminCount: 0, userCount: 0),
    (success) => success.data,
  );
});
