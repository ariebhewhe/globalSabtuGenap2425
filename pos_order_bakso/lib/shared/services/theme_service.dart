import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/constants/theme_keys.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storedThemeProvider = Provider<ThemeService>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return ThemeService(preferences);
});

class ThemeService {
  final SharedPreferences _preferences;

  ThemeService(this._preferences);

  Future<void> saveTheme(ThemeMode mode) async {
    await _preferences.setString(ThemeKeys.themePreferenceKey, mode.toString());
  }

  ThemeMode getTheme() {
    final currentTheme = _preferences.getString(ThemeKeys.themePreferenceKey);

    if (currentTheme == null) {
      return ThemeMode.system;
    }

    return ThemeModeExtension.fromMap(currentTheme);
  }
}
