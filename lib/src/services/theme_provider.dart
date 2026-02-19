import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load theme from shared preferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeIndex];

      // Determine if dark mode is active based on system or manual setting
      if (_themeMode == ThemeMode.system) {
        // For system mode, we'll determine this in the UI
        _isDarkMode = false;
      } else {
        _isDarkMode = _themeMode == ThemeMode.dark;
      }

      notifyListeners();
    } catch (e) {
      // If there's an error, use default theme
      _themeMode = ThemeMode.system;
      _isDarkMode = false;
      notifyListeners();
    }
  }

  // Save theme to shared preferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Handle error silently
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      _isDarkMode = true;
    } else {
      _themeMode = ThemeMode.light;
      _isDarkMode = false;
    }

    await _saveThemeToPrefs();
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    if (mode == ThemeMode.system) {
      // For system mode, we'll determine this in the UI
      _isDarkMode = false;
    } else {
      _isDarkMode = mode == ThemeMode.dark;
    }

    await _saveThemeToPrefs();
    notifyListeners();
  }

  // Update dark mode status (called when system theme changes)
  void updateDarkModeStatus(bool isDark) {
    if (_themeMode == ThemeMode.system) {
      _isDarkMode = isDark;
      notifyListeners();
    }
  }
}
