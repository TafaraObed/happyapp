import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/time_log_entry.dart';
import '../helpers/database_helper.dart';
import 'auth_provider.dart';

class TasksProvider with ChangeNotifier {
  final DatabaseHelper dbHelper;
  final AuthProvider authProvider;

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _initialLoadComplete = false;
  bool _isError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get hasError => _isError;
  String get errorMessage => _errorMessage;

  TasksProvider({required this.dbHelper, required this.authProvider}) {
    if (authProvider.isLoggedIn) {
      _loadTasksFromDb();
    } else {
      // Listen for auth changes
      authProvider.addListener(_handleAuthChange);
      _isLoading = false;
    }
  }
  
  @override
  void dispose() {
    authProvider.removeListener(_handleAuthChange);
    super.dispose();
  }
  
  void _handleAuthChange() {
    if (authProvider.isLoggedIn) {
      print("TasksProvider: Auth changed, user logged in. Loading tasks.");
      _loadTasksFromDb();
    } else {
      print("TasksProvider: Auth changed, user logged out. Clearing tasks.");
      _tasks = [];
      _isLoading = false;
      _initialLoadComplete = false;
      _isError = false;
      _errorMessage = '';
      _retryCount = 0;
      notifyListeners();
    }
  }

  Future<void> _loadTasksFromDb() async {
    if (!authProvider.isLoggedIn) return;
    final userId = authProvider.currentUser!.id!;
    
    _isLoading = true;
    _isError = false;
    notifyListeners(); 

    try {
      _tasks = await dbHelper.getTasks(userId);
      print("TasksProvider: Loaded ${_tasks.length} tasks from DB for user $userId.");
      _retryCount = 0; // Reset retry count on success
    } catch (e) {
      print("ERROR loading tasks from DB: $e");
      _isError = true;
      _errorMessage = "Failed to load tasks. ${_retryCount > 0 ? 'Retry attempt $_retryCount.' : ''}";
      
      // Auto-retry with exponential backoff
      if (_retryCount < _maxRetries) {
        _retryCount++;
        final delay = Duration(milliseconds: 500 * (1 << _retryCount)); // 500ms, 1s, 2s, etc.
        print("TasksProvider: Retrying in ${delay.inMilliseconds}ms...");
        
        // Notify listeners about retry
        notifyListeners();
        
        // Wait and retry
        await Future.delayed(delay);
        return _loadTasksFromDb(); // Recursive retry
      } else {
        // Max retries reached, keep last known tasks if available
        print("TasksProvider: Max retries reached. Using cached tasks (${_tasks.length}).");
      }
    } finally {
      _isLoading = false;
      _initialLoadComplete = true;
      notifyListeners();
    }
  }

  // Force reload tasks
  Future<void> refreshTasks() async {
    _retryCount = 0; // Reset retry count
    return _loadTasksFromDb();
  }

  Future<void> addTask(Task newTask) async {
    if (!authProvider.isLoggedIn) return;
    final userId = authProvider.currentUser!.id!;
     
    final taskToAdd = newTask.id == null ? newTask.copyWith(id: const Uuid().v4()) : newTask;

    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await dbHelper.addTask(taskToAdd, userId);
      if (result > 0) {
        _tasks.add(taskToAdd);
        print("TasksProvider: Task added successfully: ${taskToAdd.title}");
      } else {
        print("TasksProvider: Failed to add task to DB.");
        throw Exception("Failed to add task");
      }
    } catch (e) {
      print("ERROR adding task: $e");
      _isError = true;
      _errorMessage = "Failed to add task: ${taskToAdd.title}";
      
      // Try to restore state consistency by reloading tasks
      await _loadTasksFromDb();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editTask(Task updatedTask) async {
    if (!authProvider.isLoggedIn) return;
    final userId = authProvider.currentUser!.id!;
    
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      try {
        _isLoading = true;
        notifyListeners();
        
        final result = await dbHelper.updateTask(updatedTask, userId);
        if (result > 0) {
          _tasks[index] = updatedTask;
          print("TasksProvider: Task updated successfully: ${updatedTask.title}");
        } else {
          print("TasksProvider: Failed to update task in DB.");
          throw Exception("Failed to update task");
        }
      } catch (e) {
        print("ERROR updating task: $e");
        _isError = true;
        _errorMessage = "Failed to update task: ${updatedTask.title}";
        
        // Try to restore state consistency by reloading tasks
        await _loadTasksFromDb();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<String?> deleteTask(String taskId) async {
    if (!authProvider.isLoggedIn) return null;
    final userId = authProvider.currentUser!.id!;
    
    final indexToRemove = _tasks.indexWhere((t) => t.id == taskId);
    if (indexToRemove != -1) {
      String deletedTaskTitle = _tasks[indexToRemove].title;
      
      try {
        _isLoading = true;
        notifyListeners();
        
        final result = await dbHelper.deleteTask(taskId, userId);
        if (result > 0) {
          _tasks.removeAt(indexToRemove);
          print("TasksProvider: Task deleted successfully: $deletedTaskTitle");
          return deletedTaskTitle;
        } else {
          print("TasksProvider: Failed to delete task from DB.");
          throw Exception("Failed to delete task");
        }
      } catch (e) {
        print("ERROR deleting task: $e");
        _isError = true;
        _errorMessage = "Failed to delete task: $deletedTaskTitle";
        
        // Try to restore state consistency by reloading tasks
        await _loadTasksFromDb();
        return null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
    return null;
  }
  
  Future<void> deleteTasksForCourse(String courseId) async {
    if (!authProvider.isLoggedIn) return;
    final userId = authProvider.currentUser!.id!;
     
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await dbHelper.deleteTasksByCourse(courseId, userId);
      if (result >= 0) {
        int removedCount = _tasks.where((task) => task.courseId == courseId).length;
        _tasks.removeWhere((task) => task.courseId == courseId);
        print("TasksProvider: Deleted $removedCount tasks for course $courseId from DB.");
      } else {
        print("TasksProvider: Failed to delete tasks for course $courseId from DB.");
        throw Exception("Failed to delete tasks for course");
      }
    } catch (e) {
      print("ERROR deleting tasks for course: $e");
      _isError = true;
      _errorMessage = "Failed to delete tasks for the course";
      
      // Try to restore state consistency by reloading tasks
      await _loadTasksFromDb();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Task?> toggleTaskComplete(String taskId) async {
    if (!authProvider.isLoggedIn) return null;
    final userId = authProvider.currentUser!.id!;
    
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newState = !task.isComplete;
      final DateTime? newCompletedAt = newState ? DateTime.now() : null;
      
      final updatedTask = task.copyWith(
        isComplete: newState,
        completedAt: () => newCompletedAt,
      );
      
      try {
        // Update state immediately for better UX
        _tasks[index] = updatedTask;
        notifyListeners();
        
        final result = await dbHelper.updateTask(updatedTask, userId);
        if (result > 0) {
          print("TasksProvider: Task completion toggled successfully: ${task.title}");
          return updatedTask;
        } else {
          print("TasksProvider: Failed to update task completion in DB.");
          
          // Revert the optimistic update
          _tasks[index] = task;
          notifyListeners();
          throw Exception("Failed to update task completion");
        }
      } catch (e) {
        print("ERROR toggling task completion: $e");
        _isError = true;
        _errorMessage = "Failed to update task completion";
        
        // Revert the optimistic update if not already done
        _tasks[index] = task;
        notifyListeners();
        return null;
      }
    }
    return null;
  }

  Future<Task?> logTimeForTask(String taskId, Duration duration) async {
    if (!authProvider.isLoggedIn) return null;
    final userId = authProvider.currentUser!.id!;
     
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newLogEntry = TimeLogEntry(startTime: DateTime.now(), duration: duration);
      final updatedTimeLog = List<TimeLogEntry>.from(task.timeLog)..add(newLogEntry);
      final updatedTask = task.copyWith(timeLog: updatedTimeLog);
      
      try {
        // Update state immediately for better UX
        _tasks[index] = updatedTask;
        notifyListeners();
        
        final result = await dbHelper.updateTask(updatedTask, userId);
        if (result > 0) {
          print("TasksProvider: Time logged successfully for task: ${task.title}");
          return updatedTask;
        } else {
          print("TasksProvider: Failed to log time in DB.");
          
          // Revert the optimistic update
          _tasks[index] = task;
          notifyListeners();
          throw Exception("Failed to log time");
        }
      } catch (e) {
        print("ERROR logging time: $e");
        _isError = true;
        _errorMessage = "Failed to log time for task";
        
        // Revert the optimistic update if not already done
        _tasks[index] = task;
        notifyListeners();
        return null;
      }
    }
    return null;
  }
} 