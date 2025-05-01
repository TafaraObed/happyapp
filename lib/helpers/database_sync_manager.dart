import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import '../providers/auth_provider.dart';

class DatabaseSyncManager {
  static final DatabaseSyncManager _instance = DatabaseSyncManager._internal();
  factory DatabaseSyncManager() => _instance;
  DatabaseSyncManager._internal();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final _syncInterval = const Duration(minutes: 5);
  
  // Keep track of pending changes
  final Map<String, List<Map<String, dynamic>>> _pendingChanges = {
    'courses': [],
    'tasks': [],
    'programs': [],
  };

  // Start periodic sync
  void startSync(DatabaseHelper dbHelper, AuthProvider authProvider) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      syncDatabase(dbHelper, authProvider);
    });
  }

  // Stop sync
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Main sync function
  Future<void> syncDatabase(DatabaseHelper dbHelper, AuthProvider authProvider) async {
    if (_isSyncing || !authProvider.isLoggedIn) return;
    
    try {
      _isSyncing = true;
      final userId = authProvider.currentUser!.id!;

      // Process any pending changes first
      await _processPendingChanges(dbHelper, userId);

      // Validate and repair database integrity
      await _validateDatabaseIntegrity(dbHelper, userId);

      // Ensure predefined data is up to date
      await _ensurePredefinedData(dbHelper);

      debugPrint('Database sync completed successfully');
    } catch (e) {
      debugPrint('Error during database sync: $e');
      // Store failed operations for retry
      await _storePendingChangesForRetry();
    } finally {
      _isSyncing = false;
    }
  }

  // Process any pending changes that failed in previous sync attempts
  Future<void> _processPendingChanges(DatabaseHelper dbHelper, int userId) async {
    for (var table in _pendingChanges.keys) {
      final changes = _pendingChanges[table]!;
      if (changes.isEmpty) continue;

      try {
        for (var change in changes) {
          switch (table) {
            case 'courses':
              await dbHelper.addCourse(change['course'], userId);
              break;
            case 'tasks':
              await dbHelper.addTask(change['task'], userId);
              break;
            // Add other cases as needed
          }
        }
        // Clear processed changes
        _pendingChanges[table]!.clear();
      } catch (e) {
        debugPrint('Error processing pending changes for $table: $e');
        // Leave remaining changes for next sync attempt
        break;
      }
    }
  }

  // Validate database integrity and repair if needed
  Future<void> _validateDatabaseIntegrity(DatabaseHelper dbHelper, int userId) async {
    try {
      // Check for orphaned tasks (tasks without valid courses)
      final tasks = await dbHelper.getTasks(userId);
      final courses = await dbHelper.getCourses(userId);
      final courseIds = courses.map((c) => c.id).toSet();

      for (var task in tasks) {
        if (task.courseId != null && !courseIds.contains(task.courseId)) {
          // Task references non-existent course, update it
          final updatedTask = task.copyWith(courseId: () => null);
          await dbHelper.updateTask(updatedTask, userId);
        }
      }

      // Add other integrity checks as needed
    } catch (e) {
      debugPrint('Error during database integrity check: $e');
      rethrow;
    }
  }

  // Ensure predefined data is up to date
  Future<void> _ensurePredefinedData(DatabaseHelper dbHelper) async {
    try {
      final programs = await dbHelper.getPrograms();
      if (programs.isEmpty) {
        // Repopulate predefined programs if missing
        await dbHelper.populatePredefinedProgramsWithRetry(await dbHelper.database);
      }
    } catch (e) {
      debugPrint('Error ensuring predefined data: $e');
      rethrow;
    }
  }

  // Store failed operations for retry
  Future<void> _storePendingChangesForRetry() async {
    // Implementation would depend on your storage strategy
    // Could use SharedPreferences, local file, etc.
  }

  // Add a change to be processed in next sync
  void addPendingChange(String table, Map<String, dynamic> change) {
    _pendingChanges[table]!.add(change);
  }
} 