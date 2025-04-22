import 'package:flutter/material.dart';

// Enum for days of the week
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

// Helper to get a short string representation (e.g., "Mon")
String dayOfWeekToString(DayOfWeek day) {
  switch (day) {
    case DayOfWeek.monday: return 'Mon';
    case DayOfWeek.tuesday: return 'Tue';
    case DayOfWeek.wednesday: return 'Wed';
    case DayOfWeek.thursday: return 'Thu';
    case DayOfWeek.friday: return 'Fri';
    case DayOfWeek.saturday: return 'Sat';
    case DayOfWeek.sunday: return 'Sun';
  }
}

// Class to represent a single schedule entry
class ScheduleEntry {
  final DayOfWeek day;
  final TimeOfDay time;

  ScheduleEntry({required this.day, required this.time});

  // Helper to format the entry nicely (e.g., "Mon 10:30 AM")
  String format(BuildContext context) {
    final dayStr = dayOfWeekToString(day);
    final timeStr = time.format(context); // Use MaterialLocalizations for formatting
    return '$dayStr $timeStr';
  }

  // --- JSON Conversion ---
  Map<String, dynamic> toJson() => {
    'day': day.index, // Store enum by index
    'hour': time.hour,
    'minute': time.minute,
  };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    if (json['day'] == null || json['hour'] == null || json['minute'] == null) {
       throw FormatException("Invalid JSON for ScheduleEntry: $json");
    }
    return ScheduleEntry(
      day: DayOfWeek.values[json['day'] as int],
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
    );
  }
  // --- End JSON Conversion ---
} 