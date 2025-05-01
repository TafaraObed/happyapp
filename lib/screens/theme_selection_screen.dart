import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_themes.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  String _appThemeToString(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.solarizedLight:
        return 'Solarized Light';
      case AppTheme.solarizedDark:
        return 'Solarized Dark';
      case AppTheme.everforest:
        return 'Everforest';
      case AppTheme.zenburn:
        return 'Zenburn';
      case AppTheme.palenight:
        return 'Palenight';
      case AppTheme.nord:
        return 'Nord';
      case AppTheme.dracula:
        return 'Dracula';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Theme'),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // Light theme
          _buildThemeOption(context, AppTheme.light, themeProvider),
          
          // Dark theme
          _buildThemeOption(context, AppTheme.dark, themeProvider),
          
          // Solarized themes
          _buildThemeOption(context, AppTheme.solarizedLight, themeProvider),
          _buildThemeOption(context, AppTheme.solarizedDark, themeProvider),
          
          // Everforest theme
          _buildThemeOption(context, AppTheme.everforest, themeProvider),
          
          // Zenburn theme
          _buildThemeOption(context, AppTheme.zenburn, themeProvider),
          
          // Palenight theme
          _buildThemeOption(context, AppTheme.palenight, themeProvider),
          
          // Nord theme
          _buildThemeOption(context, AppTheme.nord, themeProvider),
          
          // Dracula theme
          _buildThemeOption(context, AppTheme.dracula, themeProvider),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppTheme theme, ThemeProvider themeProvider) {
    final isSelected = themeProvider.currentTheme == theme;
    final themeData = ThemeProvider.getThemeData(theme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? themeData.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () => themeProvider.setTheme(theme),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Theme preview circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeData.colorScheme.primary,
                ),
                child: Icon(
                  Icons.palette,
                  color: themeData.colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Theme name
              Expanded(
                child: Text(
                  _appThemeToString(theme),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ),
              // Selected indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: themeData.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 