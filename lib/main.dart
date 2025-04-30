import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonEncode/Decode
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:provider/provider.dart'; // Import Provider
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
import 'themes/app_themes.dart'; // <<< Import AppThemes

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
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
      ],
      child: const StudyPlannerApp(),
    ),
  );
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final ThemeData currentTheme = themeProvider.themeData;
        return MaterialApp(
          title: 'Study Planner',
          theme: currentTheme,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  static const String _coursesKey = 'courses_data';
  List<Course> _courses = [];
  bool _showSampleData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

    // Load Courses
    final coursesJsonString = prefs.getString(_coursesKey);
    List<Course> loadedCourses = [];
    bool coursesLoadedFromPrefs = false;
    if (coursesJsonString != null) {
      try {
        final List<dynamic> coursesJson = jsonDecode(coursesJsonString);
        loadedCourses = coursesJson.map((json) => Course.fromJson(json)).toList();
        coursesLoadedFromPrefs = true;
      } catch (e) {
        print("Error decoding courses: $e");
        await prefs.remove(_coursesKey);
      }
    }

    // Tasks are loaded by the TasksProvider constructor, check if it's done and if tasks are empty
    // We might need a short delay or a way to listen for the provider's initial load completion
    // For simplicity, assume provider loaded quickly or check its state:
    await Future.delayed(Duration.zero); // Allow provider constructor to run

    // Check if we should show sample data (no courses and no tasks loaded)
    if (!coursesLoadedFromPrefs && tasksProvider.tasks.isEmpty) {
      print("No existing data found. Loading sample data...");
      setState(() {
        _courses = _sampleCourses; // Use sample courses
        tasksProvider.resetToSampleData(); // Tell provider to load sample tasks
        _showSampleData = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _courses = loadedCourses;
        _showSampleData = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCourses() async {
    if (_showSampleData) return; // Don't save sample data
    final prefs = await SharedPreferences.getInstance();
    final String coursesJsonString = jsonEncode(_courses.map((c) => c.toJson()).toList());
    await prefs.setString(_coursesKey, coursesJsonString);
  }

  // --- Course Management Navigation & Callbacks ---

  // Navigate to Add Course screen and handle result
  Future<void> _navigateToAddCourse() async {
    final newCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(
        builder: (ctx) => const AddCourseScreen(), // No onSave needed
      ),
    );

    if (newCourse != null) {
      setState(() {
        if (_showSampleData) {
          // Clear sample data if adding the first real course
          _courses = [];
          Provider.of<TasksProvider>(context, listen: false).resetToSampleData(); // Or clear tasks
          _showSampleData = false;
        }
        _courses.add(newCourse);
      });
      _saveCourses();
      // Optionally show snackbar
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course "${newCourse.name}" added.'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // Navigate to Edit Course screen and handle result
  Future<void> _navigateToEditCourse(Course courseToEdit) async {
     final updatedCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(
        builder: (ctx) => AddCourseScreen(initialCourse: courseToEdit), // Pass initial course
      ),
    );

    if (updatedCourse != null) {
      setState(() {
        final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
        if (index != -1) {
          _courses[index] = updatedCourse;
        }
      });
      _saveCourses();
      // Optionally show snackbar
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course "${updatedCourse.name}" updated.'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // Handle Deleting a Course
  Future<void> _handleDeleteCourse(String courseId) async {
    // Find the course to get its name for confirmation
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;
    final courseName = _courses[courseIndex].name;

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$courseName"? This will also delete all associated tasks.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      // Find tasks associated with the course
      final tasksToDelete = tasksProvider.tasks.where((task) => task.courseId == courseId).toList();

      setState(() {
        // Delete the course
        _courses.removeAt(courseIndex);

        // Delete associated tasks (iterate and call provider method)
        for (var task in tasksToDelete) {
          tasksProvider.deleteTask(task.id);
        }

        // Check if remaining data is empty to decide if we should reload samples
        if (_courses.isEmpty && tasksProvider.tasks.isEmpty) {
          // Optionally reload sample data
          // _loadData(); // This might be too aggressive, maybe just clear flag
           _showSampleData = false; // Ensure flag is off
        }
      });
      _saveCourses(); // Save the updated course list
      // Task saving is handled within tasksProvider.deleteTask
      // Optionally show snackbar
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course "$courseName" and associated tasks deleted.'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // --- Navigation ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Screen Building ---
  Widget _buildScreen(int index) {
    final currentCourses = _courses;

    switch (index) {
      case 0: // Dashboard
        return DashboardScreen(
          courses: currentCourses,
          // Pass the navigation method for editing directly from detail screen
          onEditCourse: _navigateToEditCourse, 
        );
      case 1: // Courses
        return CourseListScreen(
          courses: currentCourses,
          onAdd: _navigateToAddCourse, // Use the navigation method
          onEdit: _navigateToEditCourse, // Use the navigation method
          onDelete: _handleDeleteCourse, // Use the handler method
        );
      case 2: // Tasks
        return TaskListScreen(
          courses: currentCourses, // Pass courses for filtering/linking
        );
      case 3: // Stats
        return StatsScreen(courses: currentCourses);
      case 4: // Settings
        return SettingsScreen();
      default:
        // Pass the navigation method for editing
        return DashboardScreen(courses: currentCourses, onEditCourse: _navigateToEditCourse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _buildScreen(_selectedIndex),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
           NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 2 // Show only on Tasks screen
          ? FloatingActionButton(
              onPressed: () {
                 // Navigate to Add Task Screen
                 Navigator.of(context).push(CupertinoPageRoute(
                  builder: (ctx) => AddTaskScreen(
                     courses: _courses, // Pass courses to link task
                  ),
                ));
              },
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
