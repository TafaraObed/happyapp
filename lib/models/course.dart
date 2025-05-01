import 'package:flutter/material.dart';
import 'schedule_entry.dart'; // Import the new model
import 'package:uuid/uuid.dart';
import 'dart:convert'; // Needed for jsonEncode/Decode in toMap/fromMap

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
  final Map<String, dynamic>? metadata; // Additional metadata for the course

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
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  // Helper getter to easily get the Color object when needed
  Color get colorValue => Color(int.parse(color, radix: 16) | 0xFF000000);

  // --- Database Map Conversion ---
  // Converts Course object to a Map suitable for database insertion/update.
  // Excludes dbId (auto-incremented) and user_id (added by DatabaseHelper).
  Map<String, dynamic> toMapForDb() => {
    'id': id,
    'name': name,
    'professor': professor,
    'room': room,
    'schedule': jsonEncode(schedule.map((entry) => entry.toJson()).toList()), 
    'color': color, 
    'materialsLink': materialsLink,
    'notesLink': notesLink,
    'manualGradePercent': manualGradePercent,
    'metadata': metadata != null ? jsonEncode(metadata) : null,
  };

  // Factory constructor to create a Course from a database Map.
  factory Course.fromMapFromDb(Map<String, dynamic> map) {
     // Basic validation (adjust fields as necessary)
     if (map['id'] == null || map['name'] == null || map['color'] == null) {
        throw FormatException("Invalid DB Map for Course (Missing required fields): $map");
     }
     
     // Parse the schedule list from JSON string (handle potential null or errors)
     List<ScheduleEntry> scheduleList = [];
     if (map['schedule'] != null && map['schedule'] is String) {
        try {
          List<dynamic> scheduleJson = jsonDecode(map['schedule'] as String);
          scheduleList = scheduleJson
              .map((entryJson) => ScheduleEntry.fromJson(entryJson as Map<String, dynamic>))
              .toList();
        } catch (e) {
           print("Error decoding schedule from DB map: $e - Schedule String: ${map['schedule']}");
           // Decide how to handle: throw error, default to empty, log, etc.
        }
     } else if (map['schedule'] != null) {
       // Handle cases where schedule might not be a string (e.g., if schema changes)
       print("Warning: 'schedule' field in DB map is not a String: ${map['schedule'].runtimeType}");
     }
     
     // Parse metadata if available
     Map<String, dynamic>? metadataMap;
     if (map['metadata'] != null && map['metadata'] is String) {
       try {
         metadataMap = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
       } catch (e) {
         print("Error decoding metadata from DB map: $e");
       }
     }

    return Course(
      id: map['id'] as String,
      name: map['name'] as String,
      professor: map['professor'] as String?, // Allow null
      room: map['room'] as String?, // Allow null
      schedule: scheduleList, 
      color: map['color'] as String,
      manualGradePercent: map['manualGradePercent'] as double?, // Allow null
      materialsLink: map['materialsLink'] as String?, // Allow null
      notesLink: map['notesLink'] as String?, // Allow null
      metadata: metadataMap,
    );
  }
  // --- End Database Map Conversion ---

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
    Map<String, dynamic>? metadata,
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
      metadata: metadata ?? this.metadata,
    );
  }
} 