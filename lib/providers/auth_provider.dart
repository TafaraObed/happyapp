import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  bool _isCheckingLogin = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  // Shared preferences keys
  static const String _userIdKey = 'userId';
  static const String _usernameKey = 'username';
  static const String _lastLoginKey = 'lastLogin';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  bool get isCheckingLogin => _isCheckingLogin;

  // Initialize and check for persisted login
  Future<void> checkLoginStatus() async {
    if (_isCheckingLogin) return;
    _isCheckingLogin = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIdKey);
      
      if (userId != null) {
        // User ID is stored, try to get the user from database
        final user = await _dbHelper.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
          // Update last login time for tracking purposes
          await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
          print("AuthProvider: Restored login session for ${user.username} (ID: ${user.id})");
        } else {
          // User not found in DB, clear all stored user data
          await _clearStoredUserData(prefs);
          print("AuthProvider: Stored user not found in database, session cleared");
        }
      }
    } catch (e) {
      print("ERROR checking login status: $e");
      // Don't clear data on error - better to retry than to lose the user session
    } finally {
      _isInitialized = true;
      _isCheckingLogin = false;
      notifyListeners();
    }
  }

  // Call this method after successful login
  Future<void> login(User user) async {
    try {
      _currentUser = user;
      _isLoggedIn = true;
      print("AuthProvider: User logged in - ${user.username} (ID: ${user.id})");
      
      // Persist the user data
      if (user.id != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userIdKey, user.id!);
        await prefs.setString(_usernameKey, user.username);
        await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
        print("AuthProvider: Saved user data to persistent storage");
      }
    } catch (e) {
      print("ERROR during login persistence: $e");
      // We still keep the user logged in in memory even if persistence fails
    }
    
    notifyListeners();
  }

  // Call this method on logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_lastLoginKey);
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
      print("User logged out successfully");
    } catch (e) {
      print("ERROR during logout: $e");
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (!_isLoggedIn || _currentUser == null) return;

    try {
      // Delete user data from database
      final result = await _dbHelper.deleteUser(_currentUser!.id!);
      if (result <= 0) {
        throw Exception('Failed to delete user account');
      }

      // Clear stored preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_lastLoginKey);

      // Update state
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
      print("User account deleted successfully");
    } catch (e) {
      print("ERROR deleting account: $e");
      rethrow;
    }
  }
  
  // Helper method to clear all stored user data
  Future<void> _clearStoredUserData(SharedPreferences prefs) async {
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_lastLoginKey);
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final db = await DatabaseHelper.instance.database;
    final user = _currentUser;
    
    if (user == null) {
      throw Exception('No user logged in');
    }

    // Verify current password
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [user.id, currentPassword],
    );

    if (result.isEmpty) {
      throw Exception('Current password is incorrect');
    }

    // Update password
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
} 