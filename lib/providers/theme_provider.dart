import 'package:flutter/material.dart';
// import 'package:shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String key = "theme_mode";
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final isDark = _prefs?.getBool(key) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await _initPrefs();
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _prefs?.setBool(key, _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}