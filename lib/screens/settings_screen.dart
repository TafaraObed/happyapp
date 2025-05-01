import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
// Import ThemeProvider
// Import for StartingDayOfWeek
import '../providers/settings_provider.dart'; // Import SettingsProvider
// Import intl
import '../themes/app_themes.dart'; // <<< Import AppTheme enum
import '../providers/auth_provider.dart'; // Import AuthProvider for logout
import 'theme_selection_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper to get display name for AppTheme
  String _appThemeToString(AppTheme theme) {
    switch (theme) {
      case AppTheme.light: return 'Light (Default)';
      case AppTheme.dark: return 'Dark (Default)';
      case AppTheme.solarizedLight: return 'Solarized Light';
      case AppTheme.solarizedDark: return 'Solarized Dark';
      case AppTheme.everforest: return 'Everforest';
      case AppTheme.zenburn: return 'Zenburn';
      case AppTheme.palenight: return 'Palenight';
      case AppTheme.nord: return 'Nord';
      case AppTheme.dracula: return 'Dracula';
    }
  }

  // --- Helper to pick date and update provider ---
  Future<void> _pickDate(
    BuildContext context, 
    DateTime? initialDate,
    Function(DateTime?) onDateSelected,
  ) async {
     final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5), // Allow selecting past years
      lastDate: DateTime(DateTime.now().year + 5), // Allow selecting future years
    );
    // Pass the selected date (or null if cancelled) back to the provider
    onDateSelected(pickedDate); 
  }

  // Handle logout
  void _showLogoutConfirmation(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Log Out'),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                await authProvider.logout(); // Call async logout
                
                // Navigate back to login screen
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
         elevation: 0,
         surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // Profile Settings Section
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile Settings'),
            subtitle: const Text('Edit profile picture and personal info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const Divider(),

          // Theme Settings Section
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: const Text('Customize app appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
              );
            },
          ),
          const Divider(),

          // Notification Settings
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Enable task reminders'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (bool value) {
              settingsProvider.setNotificationsEnabled(value);
            },
          ),
          const Divider(),

          // Account Settings Section
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Account'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () => _showDeleteAccountDialog(context, authProvider),
          ),

          // Logout at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context, authProvider),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await authProvider.deleteAccount();
      } finally {
        if (context.mounted) {
          Navigator.of(context).pop(); // Remove loading indicator
        }
      }
    }
  }
} 