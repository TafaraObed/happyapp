import 'package:flutter/material.dart';

// Enum to represent the available themes
enum AppTheme {
  light,
  dark,
  solarizedLight,
  solarizedDark,
  everforest,
  zenburn,
  palenight,
  nord,
  dracula,
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
      surfaceContainerHighest: const Color(0xFF2A2A2A), // Slightly lighter grey
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
      onErrorContainer: _solarizedRed, // Main text
      surface: _solarizedBase3, // Surface (cards, dialogs) - same as background
      onSurface: _solarizedBase00, // Text on surface
      surfaceContainerHighest: _solarizedBase2, // Contrasting surface variant
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
      onErrorContainer: _solarizedRed, // Main text
      surface: _solarizedBase03, // Surface (cards, dialogs) - same as background
      onSurface: _solarizedBase0, // Text on surface
      surfaceContainerHighest: _solarizedBase02, // Contrasting surface variant
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

  // --- New Theme Colors ---
  
  // Everforest theme
  static const _everforestBackground = Color(0xFF2D353B);
  static const _everforestForeground = Color(0xFFD3C6AA);
  static const _everforestPrimary = Color(0xFFA7C080);
  static const _everforestSecondary = Color(0xFF7FBBB3);
  static const _everforestSurface = Color(0xFF343F44);
  static const _everforestError = Color(0xFFE67E80);
  
  // Zenburn theme
  static const _zenburnBackground = Color(0xFF3F3F3F);
  static const _zenburnForeground = Color(0xFFDCDCCC);
  static const _zenburnPrimary = Color(0xFF7F9F7F);
  static const _zenburnSecondary = Color(0xFFDFAF8F);
  static const _zenburnSurface = Color(0xFF4F4F4F);
  static const _zenburnError = Color(0xFFCC9393);
  
  // Palenight theme
  static const _palenightBackground = Color(0xFF292D3E);
  static const _palenightForeground = Color(0xFFA6ACCD);
  static const _palenightPrimary = Color(0xFF82AAFF);
  static const _palenightSecondary = Color(0xFFC792EA);
  static const _palenightSurface = Color(0xFF34324A);
  static const _palenightError = Color(0xFFFF5370);
  
  // Nord theme
  static const _nordBackground = Color(0xFF2E3440);
  static const _nordForeground = Color(0xFFD8DEE9);
  static const _nordPrimary = Color(0xFF88C0D0);
  static const _nordSecondary = Color(0xFF81A1C1);
  static const _nordSurface = Color(0xFF3B4252);
  static const _nordError = Color(0xFFBF616A);
  
  // Dracula theme
  static const _draculaBackground = Color(0xFF282A36);
  static const _draculaForeground = Color(0xFFF8F8F2);
  static const _draculaPrimary = Color(0xFFBD93F9);
  static const _draculaSecondary = Color(0xFF6272A4);
  static const _draculaSurface = Color(0xFF343746);
  static const _draculaError = Color(0xFFFF5555);

  // --- Everforest Theme ---
  static final ThemeData everforestTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _everforestPrimary,
      onPrimary: _everforestBackground,
      primaryContainer: _everforestBackground,
      onPrimaryContainer: _everforestPrimary,
      secondary: _everforestSecondary,
      onSecondary: _everforestBackground,
      secondaryContainer: _everforestBackground,
      onSecondaryContainer: _everforestSecondary,
      tertiary: Color(0xFFE69875),  // Orange accent
      onTertiary: _everforestBackground,
      tertiaryContainer: _everforestBackground,
      onTertiaryContainer: Color(0xFFE69875),
      error: _everforestError,
      onError: _everforestBackground,
      errorContainer: _everforestBackground,
      onErrorContainer: _everforestError,
      surface: _everforestSurface,
      onSurface: _everforestForeground,
      surfaceContainerHighest: _everforestSurface,
      onSurfaceVariant: _everforestForeground,
      outline: Color(0xFF859289),
      shadow: Color(0xFF232A2E),
      inverseSurface: _everforestForeground,
      onInverseSurface: _everforestBackground,
      inversePrimary: _everforestPrimary,
      surfaceTint: _everforestPrimary,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _everforestSurface,
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _everforestSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // --- Zenburn Theme ---
  static final ThemeData zenburnTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _zenburnPrimary,
      onPrimary: _zenburnBackground,
      primaryContainer: _zenburnBackground,
      onPrimaryContainer: _zenburnPrimary,
      secondary: _zenburnSecondary,
      onSecondary: _zenburnBackground,
      secondaryContainer: _zenburnBackground,
      onSecondaryContainer: _zenburnSecondary,
      tertiary: Color(0xFF8CD0D3),  // Cyan accent
      onTertiary: _zenburnBackground,
      tertiaryContainer: _zenburnBackground,
      onTertiaryContainer: Color(0xFF8CD0D3),
      error: _zenburnError,
      onError: _zenburnBackground,
      errorContainer: _zenburnBackground,
      onErrorContainer: _zenburnError,
      surface: _zenburnSurface,
      onSurface: _zenburnForeground,
      surfaceContainerHighest: _zenburnSurface,
      onSurfaceVariant: _zenburnForeground,
      outline: Color(0xFF6F6F6F),
      shadow: Color(0xFF2F2F2F),
      inverseSurface: _zenburnForeground,
      onInverseSurface: _zenburnBackground,
      inversePrimary: _zenburnPrimary,
      surfaceTint: _zenburnPrimary,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _zenburnSurface,
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _zenburnSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // --- Palenight Theme ---
  static final ThemeData palenightTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _palenightPrimary,
      onPrimary: _palenightBackground,
      primaryContainer: _palenightBackground,
      onPrimaryContainer: _palenightPrimary,
      secondary: _palenightSecondary,
      onSecondary: _palenightBackground,
      secondaryContainer: _palenightBackground,
      onSecondaryContainer: _palenightSecondary,
      tertiary: Color(0xFFC3E88D),  // Green accent
      onTertiary: _palenightBackground,
      tertiaryContainer: _palenightBackground,
      onTertiaryContainer: Color(0xFFC3E88D),
      error: _palenightError,
      onError: _palenightBackground,
      errorContainer: _palenightBackground,
      onErrorContainer: _palenightError,
      surface: _palenightSurface,
      onSurface: _palenightForeground,
      surfaceContainerHighest: _palenightSurface,
      onSurfaceVariant: _palenightForeground,
      outline: Color(0xFF676E95),
      shadow: Color(0xFF1A1C2B),
      inverseSurface: _palenightForeground,
      onInverseSurface: _palenightBackground,
      inversePrimary: _palenightPrimary,
      surfaceTint: _palenightPrimary,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _palenightSurface,
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _palenightSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // --- Nord Theme ---
  static final ThemeData nordTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _nordPrimary,
      onPrimary: _nordBackground,
      primaryContainer: _nordBackground,
      onPrimaryContainer: _nordPrimary,
      secondary: _nordSecondary,
      onSecondary: _nordBackground,
      secondaryContainer: _nordBackground,
      onSecondaryContainer: _nordSecondary,
      tertiary: Color(0xFFA3BE8C),  // Green accent
      onTertiary: _nordBackground,
      tertiaryContainer: _nordBackground,
      onTertiaryContainer: Color(0xFFA3BE8C),
      error: _nordError,
      onError: _nordBackground,
      errorContainer: _nordBackground,
      onErrorContainer: _nordError,
      surface: _nordSurface,
      onSurface: _nordForeground,
      surfaceContainerHighest: _nordSurface,
      onSurfaceVariant: _nordForeground,
      outline: Color(0xFF4C566A),
      shadow: Color(0xFF1E2229),
      inverseSurface: _nordForeground,
      onInverseSurface: _nordBackground,
      inversePrimary: _nordPrimary,
      surfaceTint: _nordPrimary,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _nordSurface,
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _nordSurface,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // --- Dracula Theme ---
  static final ThemeData draculaTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: _draculaPrimary,
      onPrimary: _draculaBackground,
      primaryContainer: _draculaBackground,
      onPrimaryContainer: _draculaPrimary,
      secondary: _draculaSecondary,
      onSecondary: _draculaBackground,
      secondaryContainer: _draculaBackground,
      onSecondaryContainer: _draculaSecondary,
      tertiary: Color(0xFF8BE9FD),  // Cyan accent
      onTertiary: _draculaBackground,
      tertiaryContainer: _draculaBackground,
      onTertiaryContainer: Color(0xFF8BE9FD),
      error: _draculaError,
      onError: _draculaBackground,
      errorContainer: _draculaBackground,
      onErrorContainer: _draculaError,
      surface: _draculaSurface,
      onSurface: _draculaForeground,
      surfaceContainerHighest: _draculaSurface,
      onSurfaceVariant: _draculaForeground,
      outline: Color(0xFF44475A),
      shadow: Color(0xFF191A21),
      inverseSurface: _draculaForeground,
      onInverseSurface: _draculaBackground,
      inversePrimary: _draculaPrimary,
      surfaceTint: _draculaPrimary,
    ),
    useMaterial3: true,
    pageTransitionsTheme: _pageTransitionsTheme,
    inputDecorationTheme: _inputDecorationTheme.copyWith(
      fillColor: _draculaSurface,
    ),
    cardTheme: CardTheme(
      elevation: 0.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      color: _draculaSurface,
      surfaceTintColor: Colors.transparent,
    ),
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
      case AppTheme.everforest:
        return everforestTheme;
      case AppTheme.zenburn:
        return zenburnTheme;
      case AppTheme.palenight:
        return palenightTheme;
      case AppTheme.nord:
        return nordTheme;
      case AppTheme.dracula:
        return draculaTheme;
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