import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/constants/local_storage_keys.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currentUserStorageServiceProvider = Provider<CurrentUserStorageService>((
  ref,
) {
  final preferencesWithCache = ref.watch(sharedPreferencesWithCacheProvider);
  return CurrentUserStorageService(preferencesWithCache);
});

class CurrentUserStorageService {
  final SharedPreferencesWithCache _preferencesWithCache;
  final logger = AppLogger();

  CurrentUserStorageService(this._preferencesWithCache);

  Future<void> saveCurrentUser(UserModel currentUser) async {
    final currentUserString = jsonEncode(currentUser);
    await _preferencesWithCache.setString(
      LocalStorageKeys.currentUser,
      currentUserString,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final currentUserString = await _preferencesWithCache.getString(
      LocalStorageKeys.currentUser,
    );

    if (currentUserString == null) return null;

    try {
      final userMap = jsonDecode(currentUserString);
      return UserModel.fromJson(userMap);
    } catch (e) {
      logger.e('Error parsing current user', e);
      return null;
    }
  }

  Future<void> deleteCurrentUser() async {
    await _preferencesWithCache.remove(LocalStorageKeys.currentUser);
  }
}
