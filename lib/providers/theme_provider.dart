import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_themes.dart'; // <<< Import AppThemes

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'app_theme'; // Use a single key for the theme

  // Default to system preference initially, map to light/dark later
  AppTheme _currentTheme = AppTheme.light; // Default to light if system isn't explicitly handled

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeData get themeData {
    // Determine initial theme based on system brightness if necessary
    // This check might be better placed elsewhere depending on logic
    // if (_currentTheme == AppTheme.system) { ... }
    return AppThemes.getThemeData(_currentTheme);
  }

  AppTheme get currentTheme => _currentTheme;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
    } else {
      // If no preference, you could check system brightness here
      // Or just default to light
      // final Brightness platformBrightness = WidgetsBinding.instance.window.platformBrightness;
      // _currentTheme = platformBrightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
      _currentTheme = AppTheme.light; // Defaulting to light
    }

    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, theme.index);

    notifyListeners();
  }

  // --- Keep Seed Color Logic (Optional) ---
  // If you want themes based on seed color PLUS named themes,
  // you'll need more complex logic. For now, we'll prioritize named themes.
  /*
  static const String _seedColorPrefKey = 'seed_color';
  Color _seedColor = Colors.deepPurple; // Default seed color

  Color get seedColor => _seedColor;

  Future<void> loadSeedColor() async { // Renamed from _loadPreferences part
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_seedColorPrefKey) ?? Colors.deepPurple.value;
    _seedColor = Color(colorValue);
    // Optionally notifyListeners() here if seedColor changes affect the theme immediately
  }

  Future<void> setSeedColor(Color color) async {
     if (_seedColor == color) return;
     _seedColor = color;
     final prefs = await SharedPreferences.getInstance();
     await prefs.setInt(_seedColorPrefKey, color.value);
     // Decide if changing seed color should change the current theme or just be stored
     // Maybe add a AppTheme.seedColor theme?
     notifyListeners();
  }
  */

  // Remove old ThemeMode logic
  // ThemeMode _themeMode = ThemeMode.system;
  // ThemeMode get themeMode => _themeMode;
  // Future<void> setThemeMode(ThemeMode mode) async { ... }
} 