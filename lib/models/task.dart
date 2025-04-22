import 'package:flutter/foundation.dart'; // For immutable annotation
import 'package:uuid/uuid.dart';

@immutable
class Task {
  final String id;
  final String title;
  final bool isComplete;
  final String? courseId; // Optional: Link to a Course ID
  final DateTime? dueDate; // Optional: Due date for the task
  // Add other fields later if needed (priority, notes, etc.)

  Task({
    required this.title,
    this.isComplete = false,
    this.courseId,
    this.dueDate,
    String? id, // Allow providing an ID for updates
  }) : id = id ?? const Uuid().v4(); // Generate ID if not provided

  // Helper method to create a copy with updated values (for immutability)
  Task copyWith({
    String? id,
    String? title,
    bool? isComplete,
    String? courseId,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isComplete: isComplete ?? this.isComplete,
      // Allow explicitly setting courseId/dueDate to null if needed
      courseId: courseId ?? this.courseId,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  // --- JSON Conversion ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isComplete': isComplete,
    'courseId': courseId,
    // Store DateTime as ISO 8601 string, handle null
    'dueDate': dueDate?.toIso8601String(), 
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (json['id'] == null || json['title'] == null || json['isComplete'] == null) {
       throw FormatException("Invalid JSON for Task: $json");
    }
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isComplete: json['isComplete'] as bool,
      courseId: json['courseId'] as String?, // Cast as nullable String
      // Parse DateTime from ISO 8601 string, handle null
      dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String),
    );
  }
  // --- End JSON Conversion ---
} 