import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart'; // Import for StartingDayOfWeek enum

class SettingsProvider with ChangeNotifier {
  static const String _startDayPrefKey = 'start_day_of_week';
  static const String _termStartPrefKey = 'term_start_date'; // Key for term start
  static const String _termEndPrefKey = 'term_end_date'; // Key for term end
  static const String _taskRemindersKey = 'task_reminders_enabled'; // New Key
  static const String _classRemindersKey = 'class_reminders_enabled'; // New Key

  // Default to Monday
  StartingDayOfWeek _startingDayOfWeek = StartingDayOfWeek.monday;
  DateTime? _termStartDate; // State for term start date
  DateTime? _termEndDate; // State for term end date
  bool _taskRemindersEnabled = true; // Default to true
  bool _classRemindersEnabled = true; // Default to true

  SettingsProvider() {
    _loadPreferences(); // Load all prefs
  }

  StartingDayOfWeek get startingDayOfWeek => _startingDayOfWeek;
  DateTime? get termStartDate => _termStartDate; // Getter
  DateTime? get termEndDate => _termEndDate; // Getter
  bool get taskRemindersEnabled => _taskRemindersEnabled; // New Getter
  bool get classRemindersEnabled => _classRemindersEnabled; // New Getter

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Start Day
    final dayIndex = prefs.getInt(_startDayPrefKey) ?? StartingDayOfWeek.monday.index;
    if (dayIndex >= 0 && dayIndex < StartingDayOfWeek.values.length) {
       _startingDayOfWeek = StartingDayOfWeek.values[dayIndex];
    } else {
      // Handle potential corrupted data, default to Monday
      _startingDayOfWeek = StartingDayOfWeek.monday; 
    }

    // Load Term Start Date
    final termStartString = prefs.getString(_termStartPrefKey);
    if (termStartString != null) {
        _termStartDate = DateTime.tryParse(termStartString);
    }

    // Load Term End Date
    final termEndString = prefs.getString(_termEndPrefKey);
     if (termEndString != null) {
        _termEndDate = DateTime.tryParse(termEndString);
    }

    // Load Notification Prefs
    _taskRemindersEnabled = prefs.getBool(_taskRemindersKey) ?? true; // Default true if not found
    _classRemindersEnabled = prefs.getBool(_classRemindersKey) ?? true; // Default true if not found

    notifyListeners();
  }

  Future<void> setStartingDayOfWeek(StartingDayOfWeek day) async {
    if (_startingDayOfWeek == day) return;

    _startingDayOfWeek = day;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startDayPrefKey, day.index);
  }

  // Method to set Term Start Date
  Future<void> setTermStartDate(DateTime? date) async {
     if (_termStartDate == date) return;
     _termStartDate = date;
     final prefs = await SharedPreferences.getInstance();
     if (date == null) {
       await prefs.remove(_termStartPrefKey);
     } else {
       await prefs.setString(_termStartPrefKey, date.toIso8601String());
     }
     notifyListeners();
  }

  // Method to set Term End Date
   Future<void> setTermEndDate(DateTime? date) async {
     if (_termEndDate == date) return;
     _termEndDate = date;
     final prefs = await SharedPreferences.getInstance();
      if (date == null) {
       await prefs.remove(_termEndPrefKey);
     } else {
       await prefs.setString(_termEndPrefKey, date.toIso8601String());
     }
     notifyListeners();
  }

  // Setters for Notifications
  Future<void> setTaskRemindersEnabled(bool enabled) async {
    if (_taskRemindersEnabled == enabled) return;
    _taskRemindersEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taskRemindersKey, enabled);
    notifyListeners();
  }

   Future<void> setClassRemindersEnabled(bool enabled) async {
    if (_classRemindersEnabled == enabled) return;
    _classRemindersEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_classRemindersKey, enabled);
    notifyListeners();
  }
} 