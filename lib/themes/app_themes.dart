import 'package:flutter/material.dart';

// Enum to represent the available themes
enum AppTheme {
  light,
  dark,
  solarizedLight,
  solarizedDark,
}

// Helper class to manage theme data
class AppThemes {
  // Consistent Input Decoration for all themes
  static const _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
      // Keep borderSide none for focus as well, relying on fill contrast
      borderSide: BorderSide.none,
    ),
    // Consider adding fill colors explicitly if needed per theme
    // Example: fillColor: Colors.grey[200] for light themes
  );

  // Consistent Page Transitions
  static final _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      // Apply fade transition to all platforms for consistency
      for (var platform in TargetPlatform.values) platform: _FadeTransitionBuilder(),
    },
  );

  // --- Theme Data Definitions ---

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, // Default seed
      brightness: Brightness.light,
    ).copyWith(
      // Optional: Refine light theme colors further if needed
      // surfaceVariant: Colors.grey.shade200,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      // Example: Explicit fill color for light theme inputs
      // fillColor: Colors.black.withOpacity(0.06),
    ),
    // Optional: Add specific component themes like AppBarTheme, CardTheme
    cardTheme: const CardTheme(
      elevation: 0.5, // Consistent low elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    ),
    // Add other common theme properties
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, // Default seed
      brightness: Brightness.dark,
    ).copyWith(
      // Refine dark theme colors
      surface: const Color(0xFF1F1F1F), // Dark grey surface
      surfaceVariant: const Color(0xFF2A2A2A), // Slightly lighter grey
      onSurface: Colors.white.withOpacity(0.87),
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      // Example: Explicit fill color for dark theme inputs
      // fillColor: Colors.white.withOpacity(0.08),
    ),
    cardTheme: const CardTheme(
      elevation: 0.5, // Consistent low elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
       // Optional: Define card color explicitly if needed for dark theme
       // color: Color(0xFF2A2A2A), // Match surfaceVariant
    ),
    // Add other common theme properties
  );

  // --- Solarized Themes ---
  // Based on https://ethanschoonover.com/solarized/

  // Solarized Base Colors
  static const _solarizedBase03 = Color(0xFF002b36); // Dark Background
  static const _solarizedBase02 = Color(0xFF073642); // Dark Secondary Background
  static const _solarizedBase01 = Color(0xFF586e75); // Dark Content Secondary
  static const _solarizedBase00 = Color(0xFF657b83); // Dark Content Primary / Light Content Secondary
  static const _solarizedBase0 = Color(0xFF839496);  // Dark Content Primary / Light Content Secondary
  static const _solarizedBase1 = Color(0xFF93a1a1);  // Light Content Primary
  static const _solarizedBase2 = Color(0xFFeee8d5);  // Light Secondary Background
  static const _solarizedBase3 = Color(0xFFfdf6e3);  // Light Background

  // Solarized Accent Colors (using blue as primary)
  static const _solarizedBlue = Color(0xFF268bd2);
  static const _solarizedCyan = Color(0xFF2aa198);
  static const _solarizedGreen = Color(0xFF859900);
  static const _solarizedRed = Color(0xFFdc322f);
  static const _solarizedOrange = Color(0xFFcb4b16);


  static final ThemeData solarizedLightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: _solarizedBlue,
      onPrimary: _solarizedBase3, // Text on primary
      primaryContainer: _solarizedBase2,
      onPrimaryContainer: _solarizedBase01,
      secondary: _solarizedCyan,
      onSecondary: _solarizedBase3, // Text on secondary
      secondaryContainer: _solarizedBase2,
      onSecondaryContainer: _solarizedBase01,
      tertiary: _solarizedGreen,
      onTertiary: _solarizedBase3,
      tertiaryContainer: _solarizedBase2,
      onTertiaryContainer: _solarizedBase01,
      error: _solarizedRed,
      onError: _solarizedBase3, // Text on error
      errorContainer: _solarizedBase2,
      onErrorContainer: _solarizedRed,
      background: _solarizedBase3, // Main background
      onBackground: _solarizedBase00, // Main text
      surface: _solarizedBase3, // Surface (cards, dialogs) - same as background
      onSurface: _solarizedBase00, // Text on surface
      surfaceVariant: _solarizedBase2, // Contrasting surface variant
      onSurfaceVariant: _solarizedBase01, // Text on surface variant
      outline: _solarizedBase1,
      shadow: _solarizedBase03, // Use dark for shadow
      inverseSurface: _solarizedBase02,
      onInverseSurface: _solarizedBase2,
      inversePrimary: _solarizedBlue, // Keep primary same for inverse
      surfaceTint: _solarizedBlue, // Tint color for elevation overlays
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _solarizedBase2, // Use light secondary background for input fill
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _solarizedBase3, // Explicitly set card background
      surfaceTintColor: Colors.transparent, // Prevent M3 tinting on cards
    ),
    // Add other common theme properties
  );

  static final ThemeData solarizedDarkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _solarizedBlue,
      onPrimary: _solarizedBase03, // Text on primary
      primaryContainer: _solarizedBase02,
      onPrimaryContainer: _solarizedBase1,
      secondary: _solarizedCyan,
      onSecondary: _solarizedBase03, // Text on secondary
      secondaryContainer: _solarizedBase02,
      onSecondaryContainer: _solarizedBase1,
      tertiary: _solarizedGreen,
      onTertiary: _solarizedBase03,
      tertiaryContainer: _solarizedBase02,
      onTertiaryContainer: _solarizedBase1,
      error: _solarizedRed,
      onError: _solarizedBase03, // Text on error
      errorContainer: _solarizedBase02,
      onErrorContainer: _solarizedRed,
      background: _solarizedBase03, // Main background
      onBackground: _solarizedBase0, // Main text
      surface: _solarizedBase03, // Surface (cards, dialogs) - same as background
      onSurface: _solarizedBase0, // Text on surface
      surfaceVariant: _solarizedBase02, // Contrasting surface variant
      onSurfaceVariant: _solarizedBase1, // Text on surface variant
      outline: _solarizedBase00,
      shadow: _solarizedBase3, // Use light for shadow
      inverseSurface: _solarizedBase2,
      onInverseSurface: _solarizedBase02,
      inversePrimary: _solarizedBlue, // Keep primary same for inverse
      surfaceTint: _solarizedBlue, // Tint color for elevation overlays
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _solarizedBase02, // Use dark secondary background for input fill
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _solarizedBase02, // Explicitly set card background (slightly lighter)
      surfaceTintColor: Colors.transparent, // Prevent M3 tinting on cards
    ),
    // Add other common theme properties
  );

  // Method to get ThemeData from AppTheme enum
  static ThemeData getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.solarizedLight:
        return solarizedLightTheme;
      case AppTheme.solarizedDark:
        return solarizedDarkTheme;
    }
  }
}

// --- Custom Fade Transition Builder (Internal) ---
class _FadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Apply fade transition for all routes
    return FadeTransition(opacity: animation, child: child);
  }
} 