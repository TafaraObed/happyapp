import 'package:flutter/material.dart';
import 'schedule_entry.dart'; // Import the new model
import 'package:uuid/uuid.dart';

class Course {
  final String id; // Unique identifier for the course
  final String name;
  final String? professor; // Optional field
  final String? room; // Optional field
  final List<ScheduleEntry> schedule; // Changed to List<ScheduleEntry>
  final String color; // Store color as hex string
  final String? materialsLink; // Optional link for materials
  final String? notesLink; // Optional link for notes
  final double? manualGradePercent; // Optional manual grade percentage (0.0 to 1.0)

  Course({
    required this.name,
    required this.color,
    this.manualGradePercent, // Add to constructor
    String? id,
    this.professor,
    this.room,
    required this.schedule, // Now expects List<ScheduleEntry>
    this.materialsLink,
    this.notesLink,
  }) : id = id ?? const Uuid().v4();

  // Helper getter to easily get the Color object when needed
  Color get colorValue => Color(int.parse(color, radix: 16) | 0xFF000000);

  // --- JSON Conversion ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'professor': professor,
    'room': room,
    // Convert list of ScheduleEntry objects to list of JSON maps
    'schedule': schedule.map((entry) => entry.toJson()).toList(),
    'color': color, // Already int
    'materialsLink': materialsLink,
    'notesLink': notesLink,
    'manualGradePercent': manualGradePercent, // Serialize
  };

  factory Course.fromJson(Map<String, dynamic> json) {
     // Basic validation
     if (json['id'] == null || json['name'] == null || json['schedule'] == null || json['color'] == null) {
        throw FormatException("Invalid JSON for Course: $json");
     }
     // Parse the schedule list
     var scheduleListFromJson = json['schedule'] as List;
     List<ScheduleEntry> scheduleList = scheduleListFromJson
         .map((entryJson) => ScheduleEntry.fromJson(entryJson as Map<String, dynamic>))
         .toList();

    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      professor: json['professor'] as String?,
      room: json['room'] as String?,
      schedule: scheduleList,
      color: json['color'] as String,
      manualGradePercent: json['manualGradePercent'] as double?, // Deserialize
      materialsLink: json['materialsLink'] as String?,
      notesLink: json['notesLink'] as String?,
    );
  }
  // --- End JSON Conversion ---

  // Consider adding methods for serialization/deserialization (toJson, fromJson)
  // if you plan to store course data persistently later.

  // CopyWith method for easy updates
  Course copyWith({
    String? id,
    String? name,
    String? professor,
    String? room,
    List<ScheduleEntry>? schedule,
    String? color,
    double? manualGradePercent, // Add to copyWith
    String? materialsLink,
    String? notesLink,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      professor: professor ?? this.professor,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      color: color ?? this.color,
      manualGradePercent: manualGradePercent ?? this.manualGradePercent,
      materialsLink: materialsLink ?? this.materialsLink,
      notesLink: notesLink ?? this.notesLink,
    );
  }
} 