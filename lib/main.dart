import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonEncode/Decode
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:provider/provider.dart'; // Import Provider
// Removed model imports as they are handled by child screens
import 'screens/add_course_screen.dart'; 
import 'screens/dashboard_screen.dart'; // Import DashboardScreen
import 'screens/course_list_screen.dart'; // Import CourseListScreen
import 'screens/task_list_screen.dart'; // Import TaskListScreen
import 'screens/add_task_screen.dart'; // Import AddTaskScreen
import 'screens/settings_screen.dart'; // Import SettingsScreen
import 'screens/stats_screen.dart'; // Import StatsScreen
import 'models/course.dart'; // Import Course model
import 'models/schedule_entry.dart'; // Import ScheduleEntry model
import 'models/task.dart'; // Import Task model
import 'providers/theme_provider.dart'; // Import ThemeProvider
import 'providers/settings_provider.dart'; // Import SettingsProvider
import 'providers/tasks_provider.dart'; // <<< Import TasksProvider
import 'package:uuid/uuid.dart'; // Keep for non-sample data ID generation
import 'models/time_log_entry.dart'; // Import TimeLogEntry
import 'package:flutter/cupertino.dart'; // Import Cupertino library
// Import SettingsScreen later

// --- Sample Data Definition ---

// Use simple hardcoded IDs for samples
final String _sampleCourse1Id = 'sample_cs101';
final String _sampleCourse2Id = 'sample_math202';
final String _sampleCourse3Id = 'sample_hist150';

final List<Course> _sampleCourses = [
  Course(
    id: _sampleCourse1Id,
    name: 'Introduction to Programming',
    professor: 'Dr. Grace Hopper',
    room: 'Comp Sci Bldg 101',
    schedule: [
      ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 10, minute: 0)),
      ScheduleEntry(day: DayOfWeek.wednesday, time: const TimeOfDay(hour: 10, minute: 0)),
      ScheduleEntry(day: DayOfWeek.friday, time: const TimeOfDay(hour: 10, minute: 0)),
    ],
    color: 'F44336', // Red
    notesLink: 'https://example.com/notes/cs101',
  ),
  Course(
    id: _sampleCourse2Id,
    name: 'Calculus I',
    professor: 'Dr. Leonhard Euler',
    room: 'Math Hall 305',
    schedule: [
      ScheduleEntry(day: DayOfWeek.tuesday, time: const TimeOfDay(hour: 13, minute: 0)),
      ScheduleEntry(day: DayOfWeek.thursday, time: const TimeOfDay(hour: 13, minute: 0)),
    ],
    color: '2196F3', // Blue
    materialsLink: 'https://example.com/materials/math202',
  ),
    Course(
    id: _sampleCourse3Id,
    name: 'World History: Ancient Civilizations',
    professor: 'Dr. Herodotus',
    room: 'History Wing 210',
    schedule: [
      ScheduleEntry(day: DayOfWeek.monday, time: const TimeOfDay(hour: 14, minute: 30)),
      ScheduleEntry(day: DayOfWeek.wednesday, time: const TimeOfDay(hour: 14, minute: 30)),
    ],
    color: '4CAF50', // Green
  ),
];

// --- End Sample Data Definition ---

void main() {
  // Use MultiProvider to provide ThemeProvider, SettingsProvider, and TasksProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()), // <<< Add TasksProvider
      ],
      child: const StudyPlannerApp(),
    ),
  );
}

// --- Custom Fade Transition Builder ---
class FadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Apply fade transition for all routes
    return FadeTransition(opacity: animation, child: child);
  }
}
// --- End Custom Transition ---

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer or Provider.of to listen to theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Get seedColor from provider
        final Color currentSeedColor = themeProvider.seedColor; 

        // Define the custom page transitions theme
        final pageTransitionsTheme = PageTransitionsTheme(
          builders: {
            // Apply fade transition to Android and iOS
            TargetPlatform.android: FadeTransitionBuilder(),
            TargetPlatform.iOS: FadeTransitionBuilder(),
            // Use the correct builder for other platforms
             TargetPlatform.windows: FadeTransitionBuilder(), // Fixed
             TargetPlatform.macOS: FadeTransitionBuilder(), // Fixed
             TargetPlatform.linux: FadeTransitionBuilder(), // Fixed
             TargetPlatform.fuchsia: FadeTransitionBuilder(), // Fixed
          },
        );

        // Define consistent input decoration
        const inputDecorationTheme = InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            // No border side by default for a cleaner look, relies on fill color
            borderSide: BorderSide.none, 
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide.none, // Or maybe a slight border: BorderSide(color: currentSeedColor.withOpacity(0.5), width: 1)
          ),
          // Add other states like errorBorder if needed
        );

        // Generate base color schemes
        final baseLightColorScheme = ColorScheme.fromSeed(
          seedColor: currentSeedColor,
          brightness: Brightness.light,
        );
        final baseDarkColorScheme = ColorScheme.fromSeed(
          seedColor: currentSeedColor,
          brightness: Brightness.dark,
        );

        // Refine color schemes
        final refinedLightColorScheme = baseLightColorScheme.copyWith(
          // Example: Make primary container slightly lighter/less saturated
          primaryContainer: Color.alphaBlend(
            baseLightColorScheme.primary.withOpacity(0.08), // Blend primary lightly
            baseLightColorScheme.surfaceVariant, // Over surfaceVariant or surface
          ),
          // Example: Make surface variant closer to surface
          surfaceVariant: Color.alphaBlend(
             baseLightColorScheme.primary.withOpacity(0.05), // Blend primary very lightly
             baseLightColorScheme.surface, // Over surface
          ),
          // You could override many other colors here (secondary, background, etc.)
        );

        final refinedDarkColorScheme = baseDarkColorScheme.copyWith(
           // Example: Define a specific dark surface color
           surface: const Color(0xFF1F1F1F), // Dark grey instead of near-black
           // Example: Adjust surface variant based on new surface
           surfaceVariant: const Color(0xFF2A2A2A), // Slightly lighter grey
           // Example: Adjust primary container for dark theme
           primaryContainer: Color.alphaBlend(
             baseDarkColorScheme.primary.withOpacity(0.15), // Blend primary lightly
             const Color(0xFF2A2A2A), // Over new surfaceVariant
           ),
           // Ensure onSurface provides enough contrast with the new surface
           onSurface: Colors.white.withOpacity(0.87), // Common practice for dark themes
        );

    return MaterialApp(
          title: 'Study Planner',
      theme: ThemeData(
            colorScheme: refinedLightColorScheme, // Use refined scheme
            useMaterial3: true, // Enabling Material 3 for modern components
            pageTransitionsTheme: pageTransitionsTheme, // Apply the custom theme
            inputDecorationTheme: inputDecorationTheme, // Apply theme
            // Define text themes if needed for specific styling
            // textTheme: TextTheme(...)
          ),
          darkTheme: ThemeData( // Define a dark theme
             colorScheme: refinedDarkColorScheme, // Use refined scheme
            useMaterial3: true,
            pageTransitionsTheme: pageTransitionsTheme, // Apply the custom theme here too
            inputDecorationTheme: inputDecorationTheme, // Apply theme
          ),
          themeMode: themeProvider.themeMode, // Get mode from provider
          home: const MainScreen(),
        );
      },
    );
  }
}

// Renamed from StudyPlannerHome
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Renamed from _StudyPlannerHomeState
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true; // Keep loading state for Courses

  // Keys for SharedPreferences
  static const String _coursesKey = 'courses_data';
  // static const String _tasksKey = 'tasks_data'; // <<< Remove tasks key (handled by provider)

  // --- Course State & Methods ---
  List<Course> _courses = []; // Keep course list

  @override
  void initState() {
    super.initState();
    _loadCourseData(); // Load only course data here
    // Tasks are loaded by TasksProvider constructor
  }

  Future<void> _loadCourseData() async {
    setState(() { _isLoading = true; }); // Start loading courses
    final prefs = await SharedPreferences.getInstance();
    bool coursesLoadedFromPrefs = false;

    // Try loading courses
    final coursesJsonString = prefs.getString(_coursesKey);
    if (coursesJsonString != null) {
      try {
        final List<dynamic> coursesJson = jsonDecode(coursesJsonString);
        _courses = coursesJson.map((json) => Course.fromJson(json)).toList();
        coursesLoadedFromPrefs = true;
      } catch (e) {
        print("Error decoding courses: $e");
        await prefs.remove(_coursesKey);
        _courses = [];
      }
    }

    // Load sample courses if none were loaded
    if (!coursesLoadedFromPrefs) {
      print("No existing course data found. Loading sample courses...");
      _courses = List.from(_sampleCourses);
      await _saveCourseData(); // Save samples
      print("Sample courses loaded and saved.");
    }

    // Ensure widget is still mounted before calling setState
     if (mounted) {
      setState(() {
        _isLoading = false; // Course loading finished
      });
    }
  }

  Future<void> _saveCourseData() async {
     if (_isLoading) return;
     final prefs = await SharedPreferences.getInstance();
     try {
       final coursesJsonString = jsonEncode(_courses.map((c) => c.toJson()).toList());
       await prefs.setString(_coursesKey, coursesJsonString);
       // final tasksJsonString = jsonEncode(_tasks.map((t) => t.toJson()).toList()); // <<< Remove task saving
       // await prefs.setString(_tasksKey, tasksJsonString);
     } catch (e) {
       print("Error saving course data: $e");
       _showSnackBar("Error saving course data.");
     }
  }

  // --- Helper for showing SnackBar ---
  void _showSnackBar(String message) {
    // Ensure context is available and mounted
    if (!mounted) return; 
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _addCourse() async {
    final newCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(builder: (ctx) => const AddCourseScreen()),
    );
    if (newCourse != null) {
      setState(() {
        _courses.add(newCourse);
        _saveCourseData();
      });
      _showSnackBar('Course "${newCourse.name}" added.');
    }
  }

  void _editCourse(Course courseToEdit) async {
    final updatedCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(builder: (ctx) => AddCourseScreen(initialCourse: courseToEdit)),
    );
    if (updatedCourse != null) {
      setState(() {
        final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
        if (index != -1) {
          _courses[index] = updatedCourse;
          _saveCourseData();
        }
      });
      _showSnackBar('Course "${updatedCourse.name}" updated.');
    }
  }

  void _deleteCourse(String courseId) async {
     final indexToRemove = _courses.indexWhere((c) => c.id == courseId);
     if (indexToRemove == -1) return;
     final courseToRemove = _courses[indexToRemove];
     final confirm = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text('Confirm Delete'),
         content: Text('Are you sure you want to delete "${courseToRemove.name}"?'),
         actions: [
           TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)),
           TextButton(child: const Text('Delete', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(ctx).pop(true)),
         ],
       ),
     );
     if (confirm == true) {
      String deletedCourseName = courseToRemove.name;
      setState(() {
        _courses.removeAt(indexToRemove);
        _saveCourseData();
      });
      _showSnackBar('Course "$deletedCourseName" deleted.');
     }
  }
  // --- End of Course State & Methods ---

  // --- Task State & Methods (REMOVE ALL) ---
  /*
  List<Task> _tasks = []; 
  void _addTask() async { ... }
  void _editTask(Task taskToEdit) async { ... }
  void _deleteTask(String taskId) { ... }
  void _toggleTaskComplete(String taskId) { ... }
  */
  // --- End of Task State & Methods ---

  // --- Time Logging Method (REMOVE) ---
  /*
  void _logTimeForTask(String taskId, Duration duration) { ... }
  */
  // --- End Time Logging Method ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access TaskProvider to check its loading state as well
    final tasksProvider = Provider.of<TasksProvider>(context); 

    // Show loading indicator if either Courses or Tasks are loading
    if (_isLoading || tasksProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build screens once data is loaded
    final List<Widget> screens = <Widget>[
      // Use Keys for AnimatedSwitcher
      DashboardScreen(
        key: const ValueKey('dashboard'),
        courses: _courses, // Pass courses
        // tasks: _tasks, // <<< Remove tasks from here
        // onToggleTaskComplete: _toggleTaskComplete, // <<< Remove callback
        onEditCourse: _editCourse, // Pass course edit callback
      ),
      CourseListScreen(
        key: const ValueKey('courses'),
        courses: _courses,
        onAdd: _addCourse,
        onEdit: _editCourse,
        onDelete: _deleteCourse,
      ),
      TaskListScreen(
        key: const ValueKey('tasks'),
        // tasks: _tasks, // <<< Remove tasks from here
        courses: _courses, // Pass courses for lookup
        // onToggleTaskComplete: _toggleTaskComplete, // <<< Remove callback
        // onAddTask: _addTask, // <<< Remove callback
        // onEditTask: _editTask, // <<< Remove callback
        // onDeleteTask: _deleteTask, // <<< Remove callback
        // onLogTime: _logTimeForTask, // <<< Remove callback
      ),
      StatsScreen(
         key: const ValueKey('stats'),
         // tasks: _tasks, // <<< Remove tasks from here
         courses: _courses,
      ),
      SettingsScreen(key: const ValueKey('settings')),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
