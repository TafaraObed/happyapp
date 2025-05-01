import 'package:flutter/material.dart';
import 'task.dart';
import 'course.dart';
import 'package:uuid/uuid.dart';

class Program {
  final String id;
  final String name;
  final String description;
  final List<Course> sampleCourses;
  final List<Task> sampleTasks;
  final Color color;

  Program({
    required this.name, 
    required this.description,
    required this.sampleCourses,
    required this.sampleTasks,
    required this.color,
    String? id,
  }) : id = id ?? const Uuid().v4();

  // Convert color to string for storage
  String get colorString => color.value.toRadixString(16).padLeft(8, '0').substring(2);

  // Convert Program to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': colorString,
    };
  }
  
  // Create Program from Map
  factory Program.fromMap(Map<String, dynamic> map) {
    return Program(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      sampleCourses: [], // We handle these separately
      sampleTasks: [], // We handle these separately
      color: Color(int.parse(map['color'], radix: 16) | 0xFF000000),
    );
  }
}

// Predefined programs with sample courses and tasks - REMOVED as this logic is now in predefined_programs.dart
/*
class PredefinedPrograms {
  static List<Program> getPrograms() {
    return [
      // ... (rest of the old PredefinedPrograms class)
    ];
  }
}
*/ 