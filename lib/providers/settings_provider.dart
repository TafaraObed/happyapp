import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart'; // Import for StartingDayOfWeek enum
import 'dart:convert';

class SettingsProvider with ChangeNotifier {
  static const String _startingDayKey = 'starting_day_of_week';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _taskRemindersEnabledKey = 'task_reminders_enabled';
  static const String _classRemindersEnabledKey = 'class_reminders_enabled';
  static const String _termStartPrefKey = 'term_start_date'; // Key for term start
  static const String _termEndPrefKey = 'term_end_date'; // Key for term end
  static const String _userProfileKey = 'user_profile';

  // Default to Monday
  StartingDayOfWeek _startingDayOfWeek = StartingDayOfWeek.monday;
  DateTime? _termStartDate; // State for term start date
  DateTime? _termEndDate; // State for term end date
  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _classRemindersEnabled = true;

  // User profile data
  String? _profilePicture;
  String? _displayName;

  SettingsProvider() {
    _loadSettings();
  }

  // Getters
  StartingDayOfWeek get startingDayOfWeek => _startingDayOfWeek;
  DateTime? get termStartDate => _termStartDate; // Getter
  DateTime? get termEndDate => _termEndDate; // Getter
  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool get classRemindersEnabled => _classRemindersEnabled;
  String? get profilePicture => _profilePicture;
  String? get displayName => _displayName;

  // Setters
  Future<void> setStartingDayOfWeek(StartingDayOfWeek value) async {
    _startingDayOfWeek = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startingDayKey, value.index);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<void> setTaskRemindersEnabled(bool value) async {
    _taskRemindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taskRemindersEnabledKey, value);
  }

  Future<void> setClassRemindersEnabled(bool value) async {
    _classRemindersEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_classRemindersEnabledKey, value);
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

  // Profile management methods
  Future<void> updateProfilePicture(String base64Image) async {
    _profilePicture = base64Image;
    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    _displayName = name;
    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileData = {
      'profilePicture': _profilePicture,
      'displayName': _displayName,
    };
    await prefs.setString(_userProfileKey, jsonEncode(profileData));
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load starting day of week
      final startingDayIndex = prefs.getInt(_startingDayKey);
      if (startingDayIndex != null) {
        _startingDayOfWeek = StartingDayOfWeek.values[startingDayIndex];
      }

      // Load notification settings
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _taskRemindersEnabled = prefs.getBool(_taskRemindersEnabledKey) ?? true;
      _classRemindersEnabled = prefs.getBool(_classRemindersEnabledKey) ?? true;

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

      // Load user profile data
      final profileString = prefs.getString(_userProfileKey);
      if (profileString != null) {
        final profileData = jsonDecode(profileString) as Map<String, dynamic>;
        _profilePicture = profileData['profilePicture'] as String?;
        _displayName = profileData['displayName'] as String?;
      }

      notifyListeners();
    } catch (e) {
      print("ERROR loading settings: $e");
    }
  }
} 