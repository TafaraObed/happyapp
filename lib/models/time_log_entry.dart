import 'package:flutter/foundation.dart';

@immutable
class TimeLogEntry {
  final String id; // Unique ID for the log entry itself
  final DateTime startTime; // When the work was done (or logged)
  final Duration duration; // How long was spent
  // We might add taskId/courseId later if needed for querying,
  // but if stored within the Task, it's implicit.

  // Using millisecondsSinceEpoch for simpler JSON storage
  TimeLogEntry({
    required this.startTime,
    required this.duration,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(); // Simple unique enough ID

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTimeEpoch': startTime.millisecondsSinceEpoch,
        'durationMinutes': duration.inMinutes, // Store duration in minutes
      };

  factory TimeLogEntry.fromJson(Map<String, dynamic> json) {
     if (json['id'] == null || json['startTimeEpoch'] == null || json['durationMinutes'] == null) {
       throw FormatException("Invalid JSON for TimeLogEntry: Missing required fields in $json");
    }
    return TimeLogEntry(
      id: json['id'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTimeEpoch'] as int),
      duration: Duration(minutes: json['durationMinutes'] as int),
    );
  }

   // copyWith if needed later
} 