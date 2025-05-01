import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:uuid/uuid.dart';
import 'time_log_entry.dart'; // Import TimeLogEntry
import 'dart:convert'; // For JSON encoding/decoding timeLog

@immutable
class Task {
  final String id;
  final String title;
  final bool isComplete;
  final String? courseId; // Optional: Link to a Course ID
  final DateTime? dueDate; // Optional: Due date for the task
  final DateTime? completedAt; // Optional: Tracks when the task was completed
  // Add grade fields
  final double? pointsEarned;
  final double? pointsPossible;
  // Add time log list
  final List<TimeLogEntry> timeLog;
  final DateTime createdAt; // <<< Add createdAt field
  // Add other fields later if needed (priority, notes, etc.)

  Task({
    required this.title,
    this.isComplete = false,
    this.courseId,
    this.dueDate,
    this.completedAt, // Add to constructor
    this.pointsEarned, // Add to constructor
    this.pointsPossible, // Add to constructor
    List<TimeLogEntry>? timeLog, // Add to constructor
    DateTime? createdAt, // <<< Add to constructor
    String? id, // Allow providing an ID for updates
  }) : id = id ?? const Uuid().v4(),
       timeLog = timeLog ?? const [],
       // Initialize createdAt, defaulting to now if not provided
       createdAt = createdAt ?? DateTime.now();

  // Helper method to create a copy with updated values (for immutability)
  Task copyWith({
    String? id,
    String? title,
    bool? isComplete,
    // Use ValueGetter<T?> pattern to allow explicitly setting to null
    // This requires importing 'package:flutter/foundation.dart' but we already have it
    ValueGetter<String?>? courseId,
    ValueGetter<DateTime?>? dueDate,
    ValueGetter<DateTime?>? completedAt, // Add completedAt
    ValueGetter<double?>? pointsEarned,
    ValueGetter<double?>? pointsPossible,
    List<TimeLogEntry>? timeLog, // Add timeLog
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
      courseId: courseId != null ? courseId() : this.courseId,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      completedAt: completedAt != null ? completedAt() : this.completedAt, // Add completedAt
      pointsEarned: pointsEarned != null ? pointsEarned() : this.pointsEarned,
      pointsPossible: pointsPossible != null ? pointsPossible() : this.pointsPossible,
      timeLog: timeLog ?? this.timeLog, // Add timeLog
      createdAt: createdAt ?? this.createdAt, // Include in copyWith
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
    'completedAt': completedAt?.toIso8601String(), // Add completedAt to JSON
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
      completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String), // Parse completedAt
      // Read from JSON, allowing null. Ensure type safety.
      pointsEarned: (json['pointsEarned'] as num?)?.toDouble(), 
      pointsPossible: (json['pointsPossible'] as num?)?.toDouble(),
      timeLog: parsedTimeLog, // Assign parsed list
      createdAt: DateTime.parse(json['createdAt'] as String), // Parse createdAt
    );
  }
  // --- End JSON Conversion ---

  // --- Database Map Conversion ---
  Map<String, dynamic> toMapForDb() {
    // Handle timeLog serialization carefully
    String timeLogJson = jsonEncode(timeLog.map((e) => e.toJson()).toList());
    
    return {
      'id': id,
      'title': title,
      'isComplete': isComplete ? 1 : 0, // Convert bool to int
      'courseId': courseId,
      'dueDate': dueDate?.toIso8601String(), 
      // 'completedAt' might not be stored directly; could be inferred or added
      'pointsEarned': pointsEarned,
      'pointsPossible': pointsPossible,
      'timeLogged': timeLogJson, // Store timeLog as JSON string 
      'createdAt': createdAt.toIso8601String(), // Store createdAt
      // 'user_id' is added by DatabaseHelper
    };
  }

  factory Task.fromMapFromDb(Map<String, dynamic> map) {
    // Basic validation
    if (map['id'] == null || map['title'] == null || map['isComplete'] == null || map['createdAt'] == null) {
       throw FormatException("Invalid DB Map for Task: Missing required fields in $map");
    }

    // Handle timeLog deserialization
    List<TimeLogEntry> parsedTimeLog = [];
    if (map['timeLogged'] != null && map['timeLogged'] is String) {
      try {
        List<dynamic> logJson = jsonDecode(map['timeLogged'] as String);
        parsedTimeLog = logJson.map((e) => TimeLogEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        print("Error decoding timeLog from DB map: $e - String: ${map['timeLogged']}");
      }
    }
    
    // Parse completedAt based on isComplete flag and potentially a stored completion time if added later
    DateTime? completedAtValue;
    // If we decide to store completedAt in the DB:
    // completedAtValue = map['completedAt'] == null ? null : DateTime.parse(map['completedAt'] as String);
    // OR, if inferring from isComplete:
    if (map['isComplete'] == 1 && map['completedAtStoredTime'] != null) { // Assuming a hypothetical column
       // completedAtValue = DateTime.parse(map['completedAtStoredTime'] as String);
    } // Otherwise, keep it null

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isComplete: map['isComplete'] == 1, // Convert int back to bool
      courseId: map['courseId'] as String?,
      dueDate: map['dueDate'] == null ? null : DateTime.parse(map['dueDate'] as String),
      completedAt: completedAtValue, // Use parsed/inferred value
      pointsEarned: (map['pointsEarned'] as num?)?.toDouble(), 
      pointsPossible: (map['pointsPossible'] as num?)?.toDouble(),
      timeLog: parsedTimeLog, // Use parsed timeLog
      createdAt: DateTime.parse(map['createdAt'] as String), // Parse createdAt
    );
  }
  // --- End Database Map Conversion ---
} 