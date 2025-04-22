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
import 'models/course.dart'; // Import Course model
import 'models/schedule_entry.dart'; // Import ScheduleEntry model
import 'models/task.dart'; // Import Task model
import 'providers/theme_provider.dart'; // Import ThemeProvider
import 'providers/settings_provider.dart'; // Import SettingsProvider
// Import SettingsScreen later

void main() {
  // Use MultiProvider to provide both ThemeProvider and SettingsProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // Add SettingsProvider
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
  int _selectedIndex = 0; // Index for the selected tab
  bool _isLoading = true; // Add loading state

  // Keys for SharedPreferences
  static const String _coursesKey = 'courses_data';
  static const String _tasksKey = 'tasks_data';

  // --- Course State & Methods ---
  List<Course> _courses = []; // Initialize empty course list
  
  @override
  void initState() {
    super.initState();
    _loadData(); // Load data when the widget is initialized
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load Courses
      final coursesJsonString = prefs.getString(_coursesKey);
      if (coursesJsonString != null) {
        final List<dynamic> coursesJson = jsonDecode(coursesJsonString);
        _courses = coursesJson.map((json) => Course.fromJson(json)).toList();
      }
      // Load Tasks
      final tasksJsonString = prefs.getString(_tasksKey);
      if (tasksJsonString != null) {
        final List<dynamic> tasksJson = jsonDecode(tasksJsonString);
        _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
      }
      _isLoading = false; // Data loaded
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // Save Courses
    final coursesJsonString = jsonEncode(_courses.map((c) => c.toJson()).toList());
    await prefs.setString(_coursesKey, coursesJsonString);
    // Save Tasks
    final tasksJsonString = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJsonString);
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
      MaterialPageRoute(builder: (ctx) => const AddCourseScreen()),
    );
    if (newCourse != null) {
      setState(() {
        _courses.add(newCourse);
        _saveData();
      });
      _showSnackBar('Course "${newCourse.name}" added.');
    }
  }

  void _editCourse(Course courseToEdit) async {
    final updatedCourse = await Navigator.of(context).push<Course>(
      MaterialPageRoute(builder: (ctx) => AddCourseScreen(initialCourse: courseToEdit)),
    );
    if (updatedCourse != null) {
      setState(() {
        final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
        if (index != -1) {
          _courses[index] = updatedCourse;
          _saveData();
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
      String deletedCourseName = courseToRemove.name; // Store name before removing
      setState(() {
        _courses.removeAt(indexToRemove);
        _saveData();
      });
      _showSnackBar('Course "$deletedCourseName" deleted.'); // Use stored name
     }
  }
  // --- End of Course State & Methods ---

  // --- Task State & Methods ---
  List<Task> _tasks = []; // Initialize empty task list
  
  void _addTask() async {
     final newTask = await Navigator.of(context).push<Task>(
       MaterialPageRoute(builder: (ctx) => AddTaskScreen(courses: _courses)),
     );
     if (newTask != null) {
       setState(() {
         _tasks.add(newTask);
         _saveData();
       });
       _showSnackBar('Task "${newTask.title}" added.');
     }
  }
  
  void _editTask(Task taskToEdit) async {
     final updatedTask = await Navigator.of(context).push<Task>(
       MaterialPageRoute(builder: (ctx) => AddTaskScreen(
         courses: _courses, 
         initialTask: taskToEdit,
        )),
     );
     if (updatedTask != null) {
       setState(() {
         final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
         if (index != -1) {
           _tasks[index] = updatedTask;
           _saveData();
         }
       });
       _showSnackBar('Task "${updatedTask.title}" updated.');
     }
  }
  
  void _deleteTask(String taskId) {
      // Find task first for SnackBar message
      final indexToRemove = _tasks.indexWhere((t) => t.id == taskId);
      if (indexToRemove == -1) return;
      String deletedTaskTitle = _tasks[indexToRemove].title;

      // Optional: Add confirmation dialog here like for courses
      setState(() {
         _tasks.removeAt(indexToRemove);
         _saveData();
      });
      _showSnackBar('Task "$deletedTaskTitle" deleted.');
  }
  
  void _toggleTaskComplete(String taskId) {
      // Find task first for SnackBar message
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final newState = !task.isComplete;
        setState(() {
          _tasks[index] = task.copyWith(isComplete: newState);
          _saveData();
        });
         _showSnackBar('Task "${task.title}" marked as ${newState ? 'complete' : 'incomplete'}.');
      }
  }
  // --- End of Task State & Methods ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while data loads
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Build screens once data is loaded
    final List<Widget> screens = <Widget>[
      DashboardScreen(
        courses: _courses,
        tasks: _tasks,
        onToggleTaskComplete: _toggleTaskComplete,
      ),
      CourseListScreen(
        courses: _courses,
        onAdd: _addCourse,
        onEdit: _editCourse,
        onDelete: _deleteCourse,
      ),
      TaskListScreen(
        tasks: _tasks,
        courses: _courses,
        onToggleTaskComplete: _toggleTaskComplete,
        onAddTask: _addTask,
        onEditTask: _editTask,
        onDeleteTask: _deleteTask,
      ),
      // Replace placeholder with actual SettingsScreen
      const SettingsScreen(), 
    ];

    return Scaffold(
      // The body displays the screen selected by the bottom nav bar
      body: IndexedStack( // Use IndexedStack to keep screen state alive
         index: _selectedIndex,
         children: screens, // Use dynamically built list
      ),
      // Add the BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          // Add Tasks tab
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          // Add Settings tab item
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey, // Optional: make unselected items clearer
        showUnselectedLabels: true, // Optional: always show labels
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensure type is fixed for >3 items
      ),
    );
  }
}
