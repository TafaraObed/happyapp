import 'package:flutter/material.dart';
import '../models/predefined_programs.dart';
import '../models/course.dart';
import '../models/program.dart';
import '../models/task.dart';

class PredefinedCoursesService {
  // Get all predefined courses from all programs
  static List<Course> getAllPredefinedCourses() {
    final List<Course> allCourses = [];
    
    // Get all programs and extract their courses
    final programs = PredefinedPrograms.getPrograms();
    for (final program in programs) {
      for (final course in program.sampleCourses) {
        // Create a copy with program info in the course
        final courseWithProgramInfo = course.copyWith(
          metadata: {'programId': program.id, 'programName': program.name}
        );
        allCourses.add(courseWithProgramInfo);
      }
    }
    
    return allCourses;
  }
  
  // Get tasks associated with a course's program
  static List<Task> getTasksForProgramCourse(Course course) {
    if (course.metadata == null || !course.metadata!.containsKey('programId')) {
      return [];
    }
    
    final programId = course.metadata!['programId'] as String;
    final programs = PredefinedPrograms.getPrograms();
    final program = programs.firstWhere(
      (p) => p.id == programId,
      orElse: () => Program(
        name: 'Unknown',
        description: '',
        sampleCourses: [],
        sampleTasks: [],
        color: Colors.grey,
      ),
    );
    
    // If we found the program, return its sample tasks
    return program.sampleTasks;
  }
  
  // Get predefined courses by program ID
  static List<Course> getPredefinedCoursesByProgramId(String programId) {
    final programs = PredefinedPrograms.getPrograms();
    final program = programs.firstWhere(
      (p) => p.id == programId,
      orElse: () => Program(
        name: 'Unknown',
        description: '',
        sampleCourses: [],
        sampleTasks: [],
        color: Colors.grey,
      ),
    );
    
    return program.sampleCourses.map((course) {
      return course.copyWith(
        metadata: {'programId': program.id, 'programName': program.name}
      );
    }).toList();
  }
  
  // Get all programs
  static List<Program> getAllPrograms() {
    return PredefinedPrograms.getPrograms();
  }
} 