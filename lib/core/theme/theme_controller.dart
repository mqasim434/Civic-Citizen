import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Manages theme mode (light/dark/system) with persistence.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _mode = _loadMode();
  }

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeMode _loadMode() {
    final v = _prefs.getString(AppConstants.keyThemeMode);
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(AppConstants.keyThemeMode, v);
    notifyListeners();
  }

  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;
  bool get isSystem => _mode == ThemeMode.system;
}
