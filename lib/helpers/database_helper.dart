import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart'; // Assuming you'll create a User model
import '../models/course.dart'; // <<< Add Course model import
// Import ScheduleEntry for serialization
import '../models/task.dart'; // <<< Add Task model import
// Import TimeLogEntry for Task serialization
// For JSON encoding/decoding schedule
// For date formatting
import '../models/program.dart'; // Import the Program model
import '../models/predefined_programs.dart'; // Import predefined programs
import 'package:shared_preferences/shared_preferences.dart'; // For tracking DB version

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  static const String _dbName = 'study_planner_v2.db'; // Increment version if schema changes
  static const int _dbVersion = 4; // Increment version to trigger upgrades (v3->v4 for metadata)
  static const String _prefDbVersionKey = 'db_version'; // Key for storing DB version in prefs

  // Table names
  static const String tableUsers = 'users';
  static const String tableCourses = 'courses';
  static const String tableTasks = 'tasks';
  static const String tablePrograms = 'programs'; // Add programs table
  // Add other table names here (e.g., tableTimeLogs)

  // For development: Force recreate database to fix schema issues
  Future<void> forceRecreateDatabase() async {
    try {
      print("Attempting to force recreate database for development...");
      // Close the database if open
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Get path and delete the database
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _dbName);
      await deleteDatabase(path);
      
      // Also clear the stored DB version in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefDbVersionKey);
      
      print("Database deleted successfully, will be recreated on next access");
    } catch (e) {
      print("ERROR during forced database recreation: $e");
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('study_planner.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);
    print("Database path: $path");
    
    // Check stored DB version from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_prefDbVersionKey) ?? 0;
    
    // Open the database with onConfigure to enable foreign keys
    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // After successfully opening, update the stored version
        await prefs.setInt(_prefDbVersionKey, _dbVersion);
        print("Database opened successfully, version $_dbVersion");
      },
    );
  }
  
  // Enable foreign keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    print("Foreign keys enabled");
  }

  Future<void> _onCreate(Database db, int version) async {
    print("Creating database tables from scratch (version $version)");
    
    // Create Programs table first (so we can reference it in Users table)
    await db.execute('''
      CREATE TABLE $tablePrograms (
        dbId INTEGER PRIMARY KEY AUTOINCREMENT,
        id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');
    print("Table '$tablePrograms' created.");
    
    // Create Users table with program_id foreign key
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        program_id TEXT,
        FOREIGN KEY (program_id) REFERENCES $tablePrograms (id)
      )
    ''');
    print("Table '$tableUsers' created.");

    // Create Courses table
    await db.execute('''
      CREATE TABLE $tableCourses (
        dbId INTEGER PRIMARY KEY AUTOINCREMENT, -- Auto-incrementing primary key
        id TEXT UNIQUE NOT NULL,          -- Original String ID from the model
        user_id INTEGER NOT NULL,           -- Foreign key to users table
        name TEXT NOT NULL,
        professor TEXT,
        room TEXT,
        schedule TEXT,                      -- Storing JSON string for schedule list
        color TEXT,
        notesLink TEXT,
        materialsLink TEXT,
        manualGradePercent REAL,          -- For manual grade override
        metadata TEXT,                      -- Store metadata as JSON string
        FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');
     print("Table '$tableCourses' created.");

    // --- TODO: Create Tasks table --- 
     await db.execute('''
       CREATE TABLE $tableTasks (
         dbId INTEGER PRIMARY KEY AUTOINCREMENT,
         id TEXT UNIQUE NOT NULL,            -- Original String ID from the model
         user_id INTEGER NOT NULL,
         courseId TEXT,                      -- Link to Course (using Course's String ID)
         title TEXT NOT NULL,
         description TEXT,
         dueDate TEXT,                       -- Store as ISO8601 String
         isComplete INTEGER NOT NULL,        -- 0 for false, 1 for true
         pointsEarned REAL,
         pointsPossible REAL,
         timeLogged TEXT,                    -- Store Duration as ISO8601 String (e.g., PT1H30M)
         createdAt TEXT NOT NULL,            -- Store as ISO8601 String
         completedAt TEXT,                   -- Store as ISO8601 String when completed
         FOREIGN KEY (user_id) REFERENCES $tableUsers (id) ON DELETE CASCADE
         -- Optional: FOREIGN KEY (courseId) REFERENCES $tableCourses (id) 
         -- Note: Foreign key on courseId (TEXT) is trickier in SQLite if not primary key of courses
       )
     ''');
     print("Table '$tableTasks' created.");

     // Populate predefined programs with retry mechanism
     await populatePredefinedProgramsWithRetry(db);
  }
  
  // For database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from v$oldVersion to v$newVersion");
    
    // Add metadata column to courses table if upgrading to version 4
    if (oldVersion < 4) {
      try {
        final tableInfo = await db.rawQuery("PRAGMA table_info($tableCourses)");
        final hasMetadata = tableInfo.any((col) => col['name'] == 'metadata');
        if (!hasMetadata) {
          print("Adding metadata column to courses table");
          await db.execute("ALTER TABLE $tableCourses ADD COLUMN metadata TEXT");
        }
      } catch (e) {
        print("ERROR adding metadata column during upgrade: $e");
        // Handle or log error appropriately
      }
    }

    // Add completedAt column to tasks table if upgrading to version 3
    if (oldVersion < 3) {
      // Check if the column exists first to avoid errors
      final tableInfo = await db.rawQuery("PRAGMA table_info($tableTasks)");
      final hasCompletedAt = tableInfo.any((col) => col['name'] == 'completedAt');
      
      if (!hasCompletedAt) {
        print("Adding completedAt column to tasks table");
        await db.execute("ALTER TABLE $tableTasks ADD COLUMN completedAt TEXT");
      }
    }
    
    if (oldVersion < 2) {
      // Check if the programs table exists
      final tableCheck = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$tablePrograms'");
      if (tableCheck.isEmpty) {
        print("Creating missing programs table during upgrade");
        // Create the programs table if it doesn't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tablePrograms (
            dbId INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            color TEXT NOT NULL
          )
        ''');
        // Populate with predefined programs
        await populatePredefinedProgramsWithRetry(db);
      } else {
        print("Programs table already exists, checking content");
        // Check if the table has data
        final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM $tablePrograms"));
        if (count == 0) {
          print("Programs table is empty, populating with predefined programs");
          await populatePredefinedProgramsWithRetry(db);
        }
      }
    }
  }
  
  // Populate predefined programs with retry mechanism
  Future<void> populatePredefinedProgramsWithRetry(Database db, {int maxRetries = 3}) async {
    int retryCount = 0;
    bool success = false;
    
    while (!success && retryCount < maxRetries) {
      try {
        retryCount++;
        print("Attempt $retryCount to populate predefined programs...");
        final programs = PredefinedPrograms.getPrograms();
        print("Found ${programs.length} predefined programs");
        
        // Use a transaction for better atomicity
        await db.transaction((txn) async {
          for (final program in programs) {
            await txn.insert(
              tablePrograms,
              program.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            print("Added program: ${program.name} with ID: ${program.id}");
          }
        });
        
        print("Successfully populated all predefined programs");
        success = true;
      } catch (e) {
        print("ERROR populating predefined programs (attempt $retryCount): $e");
        if (retryCount < maxRetries) {
          print("Retrying in 500ms...");
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    
    if (!success) {
      print("WARNING: Failed to populate predefined programs after $maxRetries attempts");
    }
  }

  // --- Program Operations ---
  
  // Get all available programs
  Future<List<Program>> getPrograms() async {
    try {
      final db = await database;
      print("Fetching programs from database...");
      final maps = await db.query(tablePrograms);
      print("Found ${maps.length} programs in database");
      
      if (maps.isEmpty) {
        print("WARNING: No programs found in database, attempting to repopulate");
        await populatePredefinedProgramsWithRetry(db);
        final retryMaps = await db.query(tablePrograms);
        print("After repopulation: found ${retryMaps.length} programs");
        return retryMaps.map((map) => Program.fromMap(map)).toList();
      }
      
      return maps.map((map) {
        try {
          return Program.fromMap(map);
        } catch (e) {
          print("Error mapping program from database: $e");
          print("Problematic map: $map");
          return null;
        }
      }).whereType<Program>().toList();
    } catch (e) {
      print("ERROR getting programs: $e");
      return [];
    }
  }
  
  // Get program by ID
  Future<Program?> getProgramById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        tablePrograms,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Program.fromMap(maps.first);
      }
    } catch (e) {
      print("ERROR getting program by ID $id: $e");
    }
    return null;
  }

  // --- User Operations ---

  // Sign Up (Insert User)
  Future<int> signUp(User user) async {
    final db = await database;
    try {
       return await db.insert(tableUsers, user.toMap(), 
           conflictAlgorithm: ConflictAlgorithm.abort); // Use abort to prevent duplicate usernames
    } catch (e) {
      print("Error signing up user: $e");
      if (e is DatabaseException && e.isUniqueConstraintError()) {
         return -1; // Indicate username already exists
      }
      return -2; // Indicate other database error
    }
  }

  // Log In (Query User)
  Future<User?> login(String username, String password) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableUsers,
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
    } catch (e) {
      print("ERROR during login: $e");
    }
    return null;
  }

  // Check if username exists
  Future<bool> checkUsernameExists(String username) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableUsers,
        where: 'username = ?',
        whereArgs: [username],
        limit: 1, // We only need to know if at least one exists
      );
      return maps.isNotEmpty;
    } catch (e) {
      print("ERROR checking if username exists: $e");
      // Default to true to prevent duplicate usernames in case of error
      return true;
    }
  }

  // Get User by ID (Might be useful later)
  Future<User?> getUserById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableUsers,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
    } catch (e) {
      print("ERROR getting user by ID $id: $e");
    }
    return null;
  }
  
  // Update User's Program
  Future<int> updateUserProgram(int userId, String programId) async {
    try {
      final db = await database;
      return await db.update(
        tableUsers,
        {'program_id': programId},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print("ERROR updating user program: $e");
      return -1;
    }
  }

  // --- Course Operations (New) ---

  // Add a Course for a specific user
  Future<int> addCourse(Course course, int userId) async {
    final db = await database;
    Map<String, dynamic> courseMap = course.toMapForDb(); 
    courseMap['user_id'] = userId; // Add user_id before inserting
    
    print("Inserting course: $courseMap");
    try {
      return await db.insert(tableCourses, courseMap, 
          conflictAlgorithm: ConflictAlgorithm.replace); 
    } catch (e) {
       print("Error adding course: $e");
       return -1;
    }
  }

  // Get all Courses for a specific user
  Future<List<Course>> getCourses(int userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableCourses,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name ASC', 
      );
      
      print("Fetched ${maps.length} courses for user $userId");
      
      List<Course> courses = [];
      for (var map in maps) {
         try {
           courses.add(Course.fromMapFromDb(map)); 
         } catch (e) {
           print("Error converting course map: $e -- Map: $map");
         }
      }
      return courses;
    } catch (e) {
      print("ERROR getting courses for user $userId: $e");
      return [];
    }
  }

  // Update a Course
  Future<int> updateCourse(Course course, int userId) async {
    final db = await database;
    Map<String, dynamic> courseMap = course.toMapForDb();
    courseMap['user_id'] = userId; // Ensure user_id is included for safety

    print("Updating course: ${course.id} for user: $userId");
    try {
       return await db.update(
         tableCourses,
         courseMap,
         where: 'id = ? AND user_id = ?', 
         whereArgs: [course.id, userId],
       );
    } catch (e) {
       print("Error updating course ${course.id}: $e");
       return -1;
    }
  }

  // Delete a Course for a specific user
  Future<int> deleteCourse(String courseId, int userId) async {
    final db = await database;
    print("Deleting course: $courseId for user: $userId");
    try {
       return await db.delete(
         tableCourses,
         where: 'id = ? AND user_id = ?',
         whereArgs: [courseId, userId],
       );
    } catch (e) {
      print("Error deleting course $courseId: $e");
       return -1;
    }
  }

  // Add sample courses for a user based on program
  Future<void> addSampleCoursesForUser(int userId, String programId) async {
    try {
      final program = await getProgramById(programId);
      if (program == null) return;
      
      // Use a transaction for better atomicity
      final db = await database;
      await db.transaction((txn) async {
        for (Course course in program.sampleCourses) {
          Map<String, dynamic> courseMap = course.toMapForDb(); 
          courseMap['user_id'] = userId;
          await txn.insert(tableCourses, courseMap, 
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      print("Successfully added sample courses for program $programId");
    } catch (e) {
      print("ERROR adding sample courses: $e");
    }
  }
  
  // Add sample tasks for a user based on program
  Future<void> addSampleTasksForUser(int userId, String programId, List<Course> userCourses) async {
    try {
      final program = await getProgramById(programId);
      if (program == null) return;
      
      final db = await database;
      await db.transaction((txn) async {
        // Link sample tasks to appropriate courses if possible
        int taskIndex = 0;
        for (Task task in program.sampleTasks) {
          // Assign tasks to courses in a round-robin fashion if courses are available
          String? courseId = userCourses.isNotEmpty ? 
              userCourses[taskIndex % userCourses.length].id : null;
              
          Task taskWithCourse = task.copyWith(courseId: () => courseId);
          Map<String, dynamic> taskMap = taskWithCourse.toMapForDb();
          taskMap['user_id'] = userId;
          
          await txn.insert(tableTasks, taskMap,
              conflictAlgorithm: ConflictAlgorithm.replace);
          taskIndex++;
        }
      });
      print("Successfully added sample tasks for program $programId");
    } catch (e) {
      print("ERROR adding sample tasks: $e");
    }
  }

  // --- Task Operations (New) ---

  // Add a Task for a specific user
  Future<int> addTask(Task task, int userId) async {
    final db = await database;
    Map<String, dynamic> taskMap = task.toMapForDb(); // Use Task's toMapForDb
    taskMap['user_id'] = userId;

    print("Inserting task: $taskMap");
    try {
      return await db.insert(tableTasks, taskMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("Error adding task: $e");
      return -1;
    }
  }

  // Get all Tasks for a specific user (optionally filtered by course)
  Future<List<Task>> getTasks(int userId, {String? courseId}) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> maps;
      if (courseId != null) {
        maps = await db.query(
          tableTasks,
          where: 'user_id = ? AND courseId = ?',
          whereArgs: [userId, courseId],
          orderBy: 'createdAt DESC', // Example: order by creation date
        );
      } else {
        maps = await db.query(
          tableTasks,
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'createdAt DESC',
        );
      }
      
      print("Fetched ${maps.length} tasks for user $userId ${courseId != null ? ' (course: $courseId)' : ''}");
      
      List<Task> tasks = [];
      for (var map in maps) {
        try {
          // Use Task's fromMapFromDb
          tasks.add(Task.fromMapFromDb(map)); 
        } catch (e) {
          print("Error converting task map: $e -- Map: $map");
        }
      }
      return tasks;
    } catch (e) {
      print("ERROR getting tasks for user $userId: $e");
      return [];
    }
  }

  // Update a Task
  Future<int> updateTask(Task task, int userId) async {
    final db = await database;
    Map<String, dynamic> taskMap = task.toMapForDb(); // Use Task's toMapForDb
    taskMap['user_id'] = userId; // Ensure user_id for safety

    print("Updating task: ${task.id} for user: $userId");
    try {
      return await db.update(
        tableTasks,
        taskMap,
        where: 'id = ? AND user_id = ?', // Match task ID and user ID
        whereArgs: [task.id, userId],
      );
    } catch (e) {
      print("Error updating task ${task.id}: $e");
      return -1;
    }
  }

  // Delete a Task for a specific user
  Future<int> deleteTask(String taskId, int userId) async {
    final db = await database;
    print("Deleting task: $taskId for user: $userId");
    try {
      return await db.delete(
        tableTasks,
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, userId],
      );
    } catch (e) {
      print("Error deleting task $taskId: $e");
      return -1;
    }
  }

  // Delete all Tasks associated with a specific course for a user
  Future<int> deleteTasksByCourse(String courseId, int userId) async {
    final db = await database;
    print("Deleting tasks for course: $courseId for user: $userId");
    try {
      return await db.delete(
        tableTasks,
        where: 'courseId = ? AND user_id = ?',
        whereArgs: [courseId, userId],
      );
    } catch (e) {
      print("Error deleting tasks for course $courseId: $e");
      return -1;
    }
  }
  
  // --- TODO: Time Log Operations ---

  // Get a user's program
  Future<Program?> getUserProgram(int userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> userMaps = await db.query(
        tableUsers,
        columns: ['program_id'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      
      if (userMaps.isEmpty || userMaps.first['program_id'] == null) {
        return null;
      }
      
      final String programId = userMaps.first['program_id'] as String;
      return getProgramById(programId);
    } catch (e) {
      print("ERROR getting user program for user $userId: $e");
      return null;
    }
  }

  // Add a predefined course along with its associated tasks
  Future<int> addPredefinedCourseWithTasks(Course course, List<Task> tasks, int userId) async {
    try {
      // First add the course
      final courseId = await addCourse(course, userId);
      if (courseId <= 0) {
        print("Error adding predefined course: $courseId");
        return -1;
      }
      
      // Then add associated tasks with the proper courseId
      final db = await database;
      await db.transaction((txn) async {
        for (Task task in tasks) {
          // Create task with the course ID
          final taskWithCourse = task.copyWith(courseId: () => course.id);
          Map<String, dynamic> taskMap = taskWithCourse.toMapForDb();
          taskMap['user_id'] = userId;
          
          await txn.insert(tableTasks, taskMap,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
      
      print("Successfully added predefined course and ${tasks.length} associated tasks");
      return courseId;
    } catch (e) {
      print("ERROR adding predefined course with tasks: $e");
      return -1;
    }
  }

  // Delete a user and all their associated data
  Future<int> deleteUser(int userId) async {
    final db = await database;
    try {
      // Use a transaction to ensure all operations complete or none do
      return await db.transaction((txn) async {
        // Delete all user's tasks
        await txn.delete(
          tableTasks,
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        // Delete all user's courses
        await txn.delete(
          tableCourses,
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        // Finally, delete the user
        return await txn.delete(
          tableUsers,
          where: 'id = ?',
          whereArgs: [userId],
        );
      });
    } catch (e) {
      print("ERROR deleting user $userId: $e");
      return -1;
    }
  }
} 