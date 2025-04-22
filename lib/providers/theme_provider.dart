import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModePrefKey = 'theme_mode';
  static const String _seedColorPrefKey = 'seed_color'; // Key for saving color
  
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.blueAccent; // Default seed color

  ThemeProvider() {
    _loadPreferences(); // Load both theme mode and color
  }

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor; // Getter for seed color

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Load Theme Mode
    final themeIndex = prefs.getInt(_themeModePrefKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    // Load Seed Color
    final colorValue = prefs.getInt(_seedColorPrefKey) ?? Colors.blueAccent.value;
    _seedColor = Color(colorValue);

    notifyListeners(); // Notify after loading both
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; 
    _themeMode = mode;
     // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModePrefKey, mode.index);
    notifyListeners(); 
  }

  Future<void> setSeedColor(Color color) async {
     if (_seedColor == color) return;
     _seedColor = color;
     // Save preference
     final prefs = await SharedPreferences.getInstance();
     await prefs.setInt(_seedColorPrefKey, color.value);
     notifyListeners(); // Notify UI of color change
  }
} 