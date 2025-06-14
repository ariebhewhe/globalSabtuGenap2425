import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/shared/services/theme_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final ThemeService _themeService;

  ThemeNotifier(this._themeService) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeMode = await _themeService.getTheme();

    state = themeMode;
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _themeService.saveTheme(mode);

    state = mode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final themeService = ref.watch(storedThemeProvider);
  return ThemeNotifier(themeService);
});
