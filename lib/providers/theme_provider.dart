import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._prefs) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final savedTheme = _prefs.getString(_themeModeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedTheme,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setString(_themeModeKey, mode.name);
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : _themeMode == ThemeMode.dark
            ? ThemeMode.system
            : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
