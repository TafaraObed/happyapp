import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

import 'program.dart';
import 'course.dart';
import 'schedule_entry.dart';
import 'task.dart';

class PredefinedPrograms {
  static const _uuid = Uuid();

  // Helper to convert Color to hex string (e.g., "FFAABBCC" -> "AABBCC")
  static String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  static List<Program> getPrograms() {
    return [
      // --- Computer Science ---
      Program(
        id: 'cs_program',
        name: 'Computer Science',
        description: 'Focuses on algorithms, data structures, programming, and software engineering.',
        color: Colors.blue, // Pass Color object
        sampleCourses: [
          Course(
            id: _uuid.v4(),
            name: 'Introduction to Programming',
            professor: 'Dr. Ada Lovelace',
            room: 'CS-101',
            schedule: [
              ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 9, minute: 0)),
              ScheduleEntry(day: DayOfWeek.wednesday, time: const TimeOfDay(hour: 9, minute: 0)),
            ],
            color: _colorToHex(Colors.lightBlue), // Pass hex string
          ),
          Course(
            id: _uuid.v4(),
            name: 'Data Structures & Algorithms',
            professor: 'Dr. Alan Turing',
            room: 'CS-205',
            schedule: [
              ScheduleEntry(day: DayOfWeek.tuesday, time: const TimeOfDay(hour: 13, minute: 0)),
              ScheduleEntry(day: DayOfWeek.thursday, time: const TimeOfDay(hour: 13, minute: 0)),
            ],
            color: _colorToHex(Colors.blueAccent), // Pass hex string
          ),
          Course(
            id: _uuid.v4(),
            name: 'Operating Systems',
            professor: 'Dr. Linus Torvalds',
            room: 'CS-310',
            schedule: [
              ScheduleEntry(day: DayOfWeek.friday, time: const TimeOfDay(hour: 11, minute: 0)),
            ],
            color: _colorToHex(Colors.indigo), // Pass hex string
          ),
        ],
        sampleTasks: [
          Task(
            id: _uuid.v4(),
            title: 'Programming Assignment 1: Implement a basic linked list.',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            pointsPossible: 100,
            createdAt: DateTime.now(),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Algorithm Analysis Homework',
            dueDate: DateTime.now().add(const Duration(days: 14)),
            pointsPossible: 50,
            isComplete: false,
            createdAt: DateTime.now(),
          ),
          Task(
            id: _uuid.v4(),
            title: 'OS Project Proposal',
            dueDate: DateTime.now().add(const Duration(days: 21)),
            createdAt: DateTime.now(),
          ),
        ],
      ),

      // --- Informatics ---
      Program(
        id: 'info_program',
        name: 'Informatics',
        description: 'Combines computer science with information management and user-centered design.',
        color: Colors.green, // Pass Color object
        sampleCourses: [
          Course(
            id: _uuid.v4(),
            name: 'Database Management Systems',
            professor: 'Dr. Edgar Codd',
            room: 'INFO-110',
            schedule: [
              ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 11, minute: 0)),
            ],
            color: _colorToHex(Colors.lightGreen), // Pass hex string
          ),
          Course(
            id: _uuid.v4(),
            name: 'Human-Computer Interaction',
            professor: 'Dr. Don Norman',
            room: 'INFO-225',
            schedule: [
              ScheduleEntry(day: DayOfWeek.wednesday, time: const TimeOfDay(hour: 14, minute: 0)),
            ],
            color: _colorToHex(Colors.greenAccent), // Pass hex string
          ),
        ],
        sampleTasks: [
          Task(
            id: _uuid.v4(),
            title: 'Database Design Project: Design a relational schema for a library.',
            dueDate: DateTime.now().add(const Duration(days: 10)),
            pointsPossible: 150,
            createdAt: DateTime.now(),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Usability Study Report',
            dueDate: DateTime.now().add(const Duration(days: 20)),
            createdAt: DateTime.now(),
          ),
        ],
      ),
      
      // --- Network Engineering ---
       Program(
        id: 'net_eng_program',
        name: 'Network Engineering',
        description: 'Focuses on the design, implementation, and management of computer networks.',
        color: Colors.orange, // Pass Color object
        sampleCourses: [
           Course(
             id: _uuid.v4(),
             name: 'Introduction to Networking',
             professor: 'Dr. Vint Cerf',
             room: 'NET-101',
             schedule: [
               ScheduleEntry(day: DayOfWeek.tuesday, time: const TimeOfDay(hour: 10, minute: 0)),
               ScheduleEntry(day: DayOfWeek.thursday, time: const TimeOfDay(hour: 10, minute: 0)),
             ],
             color: _colorToHex(Colors.orangeAccent), // Pass hex string
           ),
           Course(
             id: _uuid.v4(),
             name: 'Network Security',
             professor: 'Dr. Bruce Schneier',
             room: 'NET-350',
             schedule: [
              ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 15, minute: 0)),
             ],
             color: _colorToHex(Colors.deepOrange), // Pass hex string
           ),
        ],
        sampleTasks: [
          Task(
            id: _uuid.v4(),
            title: 'Subnetting Practice Problems',
            dueDate: DateTime.now().add(const Duration(days: 5)),
            pointsPossible: 50,
            createdAt: DateTime.now(),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Firewall Configuration Lab: Configure basic firewall rules.',
            dueDate: DateTime.now().add(const Duration(days: 18)),
            pointsPossible: 100,
            createdAt: DateTime.now(),
          ),
        ],
      ),

      // --- Chemical Engineering ---
      Program(
        id: 'chem_eng_program',
        name: 'Chemical Engineering',
        description: 'Applies principles of chemistry, physics, and math to design and operate industrial chemical processes.',
        color: Colors.purple, // Pass Color object
        sampleCourses: [
           Course(
             id: _uuid.v4(),
             name: 'Thermodynamics I',
             professor: 'Dr. Sadi Carnot',
             room: 'CHEM-210',
             schedule: [
               ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 8, minute: 0)),
               ScheduleEntry(day: DayOfWeek.wednesday, time: const TimeOfDay(hour: 8, minute: 0)),
             ],
             color: _colorToHex(Colors.purpleAccent), // Pass hex string
           ),
           Course(
             id: _uuid.v4(),
             name: 'Transport Phenomena',
             professor: 'Dr. Robert Bird',
             room: 'CHEM-330',
             schedule: [
              ScheduleEntry(day: DayOfWeek.friday, time: const TimeOfDay(hour: 13, minute: 0)),
             ],
             color: _colorToHex(Colors.deepPurple), // Pass hex string
           ),
        ],
        sampleTasks: [
          Task(
            id: _uuid.v4(),
            title: 'Thermodynamics Problem Set 3',
            dueDate: DateTime.now().add(const Duration(days: 12)),
            pointsPossible: 75,
            createdAt: DateTime.now(),
          ),
          Task(
            id: _uuid.v4(),
            title: 'Fluid Flow Lab Report: Analyze data from pipe flow experiment.',
            dueDate: DateTime.now().add(const Duration(days: 25)),
            pointsPossible: 120,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }
} 