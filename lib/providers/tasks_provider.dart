import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/time_log_entry.dart';

class TasksProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _initialLoadComplete = false;

  static const String _tasksKey = 'tasks_data';

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TasksProvider() {
    _loadTasks();
  }

  // --- Sample Data (moved here for encapsulation) ---
  // Assumes sample course IDs are known or handled elsewhere if needed for samples
  final List<Task> _sampleTasks = [
      Task(id: 'sample_task_1', title: 'Assignment 1: Basic Algorithms', courseId: 'sample_cs101', dueDate: DateTime.now().add(const Duration(days: 7))),
      Task(id: 'sample_task_2', title: 'Read Chapter 3: Functions', courseId: 'sample_cs101', dueDate: DateTime.now().add(const Duration(days: 4)), isComplete: true),
      Task(id: 'sample_task_3', title: 'Problem Set 1: Limits', courseId: 'sample_math202', dueDate: DateTime.now().add(const Duration(days: 6))),
      Task(id: 'sample_task_4', title: 'Watch Khan Academy: Derivatives', courseId: 'sample_math202'),
      Task(id: 'sample_task_5', title: 'Essay Outline: Mesopotamia', courseId: 'sample_hist150', dueDate: DateTime.now().add(const Duration(days: 10))),
      Task(id: 'sample_task_6', title: 'Map Quiz Practice', courseId: 'sample_hist150', dueDate: DateTime.now().add(const Duration(days: 3))),
      Task(id: 'sample_task_7', title: 'Prepare Midterm Study Guide', dueDate: DateTime.now().add(const Duration(days: 21)))
  ];
  // --- End Sample Data ---


  Future<void> _loadTasks({bool forceSampleData = false}) async {
    if (_initialLoadComplete && !forceSampleData) return; // Prevent reload unless forced
    
    _isLoading = true;
    notifyListeners(); // Notify loading start

    final prefs = await SharedPreferences.getInstance();
    bool dataLoadedFromPrefs = false;

    if (!forceSampleData) {
        final tasksJsonString = prefs.getString(_tasksKey);
        if (tasksJsonString != null) {
        try {
            final List<dynamic> tasksJson = jsonDecode(tasksJsonString);
            _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
            dataLoadedFromPrefs = true;
        } catch (e) {
            print("Error decoding tasks: $e");
            await prefs.remove(_tasksKey); // Clear invalid data
            _tasks = []; // Reset tasks list
        }
        }
    }

    // Load sample data if nothing was loaded and it wasn't forced
    // OR if sample data was explicitly forced
    if (forceSampleData || !dataLoadedFromPrefs) {
      print("Loading sample tasks into provider...");
      _tasks = List.from(_sampleTasks);
      await _saveTasks(); // Save samples immediately
      print("Sample tasks loaded and saved.");
    }

    _isLoading = false;
    _initialLoadComplete = true;
    notifyListeners(); // Notify loading finish and data update
  }

  Future<void> _saveTasks() async {
    if (_isLoading && !_initialLoadComplete) return; // Avoid saving during initial load
    final prefs = await SharedPreferences.getInstance();
    try {
      final tasksJsonString = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_tasksKey, tasksJsonString);
    } catch (e) {
      print("Error saving tasks: $e");
      // Consider notifying UI about the error
    }
  }

  void addTask(Task newTask) {
    _tasks.add(newTask.copyWith(id: newTask.id ?? const Uuid().v4())); // Ensure ID
    _saveTasks();
    notifyListeners();
  }

  void editTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _saveTasks();
      notifyListeners();
    }
  }

  String? deleteTask(String taskId) {
    final indexToRemove = _tasks.indexWhere((t) => t.id == taskId);
    if (indexToRemove != -1) {
      String deletedTaskTitle = _tasks[indexToRemove].title;
      _tasks.removeAt(indexToRemove);
      _saveTasks();
      notifyListeners();
      return deletedTaskTitle;
    }
    return null;
  }

  Task? toggleTaskComplete(String taskId) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newState = !task.isComplete;
      _tasks[index] = task.copyWith(isComplete: newState);
      _saveTasks();
      notifyListeners();
      return _tasks[index]; // Return the updated task
    }
    return null;
  }

  Task? logTimeForTask(String taskId, Duration duration) {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newLogEntry = TimeLogEntry(startTime: DateTime.now(), duration: duration);
      final updatedTimeLog = List<TimeLogEntry>.from(task.timeLog)..add(newLogEntry);
      _tasks[index] = task.copyWith(timeLog: updatedTimeLog);
      _saveTasks();
      notifyListeners();
      return _tasks[index]; // Return the updated task
    }
    return null;
  }
  
  // Method to reload sample data (e.g., from settings)
  Future<void> resetToSampleData() async {
    await _loadTasks(forceSampleData: true);
  }
} 