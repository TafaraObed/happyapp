import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:uuid/uuid.dart';
import 'time_log_entry.dart'; // Import TimeLogEntry

@immutable
class Task {
  final String id;
  final String title;
  final bool isComplete;
  final String? courseId; // Optional: Link to a Course ID
  final DateTime? dueDate; // Optional: Due date for the task
  // Add grade fields
  final double? pointsEarned;
  final double? pointsPossible;
  // Add time log list
  final List<TimeLogEntry> timeLog;
  // Add other fields later if needed (priority, notes, etc.)

  Task({
    required this.title,
    this.isComplete = false,
    this.courseId,
    this.dueDate,
    this.pointsEarned, // Add to constructor
    this.pointsPossible, // Add to constructor
    List<TimeLogEntry>? timeLog, // Add to constructor
    String? id, // Allow providing an ID for updates
  }) : id = id ?? const Uuid().v4(),
       timeLog = timeLog ?? const []; // Initialize if null

  // Helper method to create a copy with updated values (for immutability)
  Task copyWith({
    String? id,
    String? title,
    bool? isComplete,
    // Use ValueGetter<T?> pattern to allow explicitly setting to null
    // This requires importing 'package:flutter/foundation.dart' but we already have it
    ValueGetter<String?>? courseId,
    ValueGetter<DateTime?>? dueDate,
    ValueGetter<double?>? pointsEarned,
    ValueGetter<double?>? pointsPossible,
    List<TimeLogEntry>? timeLog, // Add timeLog
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
      courseId: courseId != null ? courseId() : this.courseId,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      pointsEarned: pointsEarned != null ? pointsEarned() : this.pointsEarned,
      pointsPossible: pointsPossible != null ? pointsPossible() : this.pointsPossible,
      timeLog: timeLog ?? this.timeLog, // Add timeLog
    );
  }

  // Helper to get total time spent
  Duration get totalTimeSpent {
    if (timeLog.isEmpty) return Duration.zero;
    return timeLog.fold(Duration.zero, (sum, entry) => sum + entry.duration);
  }

  // --- JSON Conversion ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isComplete': isComplete,
    'courseId': courseId,
    // Store DateTime as ISO 8601 string, handle null
    'dueDate': dueDate?.toIso8601String(), 
    'pointsEarned': pointsEarned, // Add to JSON
    'pointsPossible': pointsPossible, // Add to JSON
    // Convert TimeLogEntry list to JSON list
    'timeLog': timeLog.map((entry) => entry.toJson()).toList(), 
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (json['id'] == null || json['title'] == null || json['isComplete'] == null) {
       throw FormatException("Invalid JSON for Task: Missing required fields in $json");
    }
    // Handle parsing the timeLog list, defaulting to empty if null or missing
    List<TimeLogEntry> parsedTimeLog = [];
    if (json['timeLog'] is List) {
      parsedTimeLog = (json['timeLog'] as List)
          .map((entryJson) => TimeLogEntry.fromJson(entryJson as Map<String, dynamic>))
          .toList();
    }
    
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isComplete: json['isComplete'] as bool,
      courseId: json['courseId'] as String?, // Cast as nullable String
      // Parse DateTime from ISO 8601 string, handle null
      dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String),
      // Read from JSON, allowing null. Ensure type safety.
      pointsEarned: (json['pointsEarned'] as num?)?.toDouble(), 
      pointsPossible: (json['pointsPossible'] as num?)?.toDouble(),
      timeLog: parsedTimeLog, // Assign parsed list
    );
  }
  // --- End JSON Conversion ---
} 