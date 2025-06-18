import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const themeKey = 'isDarkMode';

  ThemeMode _themeMode = ThemeMode.system;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(themeKey, isOn);
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(themeKey);
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}
