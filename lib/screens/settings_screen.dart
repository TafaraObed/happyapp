import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/theme_provider.dart'; // Import ThemeProvider
import 'package:table_calendar/table_calendar.dart'; // Import for StartingDayOfWeek
import '../providers/settings_provider.dart'; // Import SettingsProvider
import 'package:intl/intl.dart'; // Import intl

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper to get display name for ThemeMode
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System Default';
    }
  }

  // Predefined accent colors
  final List<Color> _availableAccentColors = const [
    Colors.blueAccent, Colors.redAccent, Colors.greenAccent, Colors.purpleAccent,
    Colors.orange, Colors.teal, Colors.pink, Colors.indigo, 
  ];

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

  @override
  Widget build(BuildContext context) {
    // Get the ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Get SettingsProvider
    final currentSeedColor = themeProvider.seedColor; // Get current seed color

    // Format dates for display
    final DateFormat formatter = DateFormat.yMMMd(); // e.g., Sep 5, 2024
    final String startDateText = settingsProvider.termStartDate == null 
        ? 'Not Set' 
        : formatter.format(settingsProvider.termStartDate!);
    final String endDateText = settingsProvider.termEndDate == null 
        ? 'Not Set' 
        : formatter.format(settingsProvider.termEndDate!);

    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
         backgroundColor: surfaceColor.withOpacity(0.90),
         elevation: 0,
         surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0), // Add vertical padding
        children: [
          // --- Theme Settings Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          // RadioListTiles for theme selection
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
             onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
           RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follows your device settings'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
             onChanged: (ThemeMode? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          
          // --- Accent Color Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // Add padding top
            child: Text('Accent Color', style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _availableAccentColors.map((color) {
                bool isSelected = currentSeedColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    themeProvider.setSeedColor(color);
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                     // Add border if selected for better visibility?
                    // foregroundColor: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32), // Add divider below
          
          // --- Calendar Settings Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Calendar', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
           RadioListTile<StartingDayOfWeek>(
            title: const Text('Start Week on Monday'),
            value: StartingDayOfWeek.monday,
            groupValue: settingsProvider.startingDayOfWeek,
            onChanged: (StartingDayOfWeek? value) {
              if (value != null) {
                settingsProvider.setStartingDayOfWeek(value);
              }
            },
          ),
          RadioListTile<StartingDayOfWeek>(
            title: const Text('Start Week on Sunday'),
            value: StartingDayOfWeek.sunday,
            groupValue: settingsProvider.startingDayOfWeek,
            onChanged: (StartingDayOfWeek? value) {
              if (value != null) {
                settingsProvider.setStartingDayOfWeek(value);
              }
            },
          ),
          // Add more calendar options later (e.g., format toggle)
          const Divider(indent: 16, endIndent: 16),
          
          // --- Academic Term Section ---
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Academic Term', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.date_range_outlined),
            title: const Text('Term Start Date'),
            trailing: Text(startDateText),
            onTap: () => _pickDate(
              context,
              settingsProvider.termStartDate,
              settingsProvider.setTermStartDate, // Pass method reference
             ),
          ),
           ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Term End Date'),
            trailing: Text(endDateText),
            onTap: () => _pickDate(
              context,
              settingsProvider.termEndDate,
              settingsProvider.setTermEndDate, // Pass method reference
             ),
          ),
          const Divider(indent: 16, endIndent: 16),
          
          // --- Notifications Section ---
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
           SwitchListTile(
             title: const Text('Task Due Reminders'),
             subtitle: const Text('Notify before tasks are due'), // Placeholder subtitle
             value: settingsProvider.taskRemindersEnabled,
             onChanged: settingsProvider.setTaskRemindersEnabled,
             secondary: const Icon(Icons.task_alt_outlined),
           ),
           SwitchListTile(
             title: const Text('Class Start Reminders'),
              subtitle: const Text('Notify before classes start'), // Placeholder subtitle
             value: settingsProvider.classRemindersEnabled,
             onChanged: settingsProvider.setClassRemindersEnabled,
             secondary: const Icon(Icons.schedule_outlined),
           ),
          const Divider(indent: 16, endIndent: 16),

          // --- Placeholder Sections ---
          const ListTile(
             leading: Icon(Icons.notifications_none), // Use outlined icons for inactive settings
             title: Text('Notifications (Coming Soon)')
            ),
           const Divider(indent: 16, endIndent: 16),
            const ListTile(
             leading: Icon(Icons.calendar_month_outlined),
             title: Text('Calendar (Coming Soon)')
            ),
            const Divider(indent: 16, endIndent: 16),
             const ListTile(
             leading: Icon(Icons.school_outlined),
             title: Text('Academic Terms (Coming Soon)')
            ),
        ],
      ),
    );
  }
} 