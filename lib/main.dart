import 'package:flutter/material.dart';
// For jsonEncode/Decode
// Import shared_preferences
import 'package:provider/provider.dart'; // Import Provider
import 'screens/add_course_screen.dart'; 
import 'screens/dashboard_screen.dart'; // Import DashboardScreen
import 'screens/course_list_screen.dart'; // Import CourseListScreen
import 'screens/task_list_screen.dart'; // Import TaskListScreen
// Import AddTaskScreen
import 'screens/settings_screen.dart'; // Import SettingsScreen
import 'screens/stats_screen.dart'; // Import StatsScreen
import 'models/course.dart'; // Import Course model
// Import ScheduleEntry model
// Import Task model
import 'providers/theme_provider.dart'; // Import ThemeProvider
import 'providers/settings_provider.dart'; // Import SettingsProvider
import 'providers/tasks_provider.dart'; // <<< Import TasksProvider
// Keep for non-sample data ID generation
// Import TimeLogEntry
import 'package:flutter/cupertino.dart'; // Import Cupertino library
// <<< Import AppThemes
import 'screens/login_screen.dart'; // <<< Import LoginScreen
import 'providers/auth_provider.dart'; // <<< Import AuthProvider
import 'helpers/database_helper.dart'; // <<< Import DatabaseHelper
import 'services/predefined_courses_service.dart'; // <<< Import PredefinedCoursesService
import 'helpers/database_sync_manager.dart';

// --- Remove Sample Data Definition (will load from DB) ---
// final String _sampleCourse1Id = ... 
// final List<Course> _sampleCourses = ...
// --- End Remove Sample Data ---

void main() async {  // Make main async
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Initialize the database helper first
  final dbHelper = DatabaseHelper.instance;
  
  // For development: Uncommenting this will force database recreation
  // await dbHelper.forceRecreateDatabase();
  
  // Preload the database to ensure it's created/migrated properly
  await dbHelper.database;
  
  // Create AuthProvider early to check login status
  final authProvider = AuthProvider();
  
  // Initialize the TasksProvider with database and auth dependencies
  final tasksProvider = TasksProvider(
    dbHelper: dbHelper,
    authProvider: authProvider
  );

  // Initialize and start database sync manager
  final syncManager = DatabaseSyncManager();
  syncManager.startSync(dbHelper, authProvider);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: tasksProvider),
      ],
      child: const StudyPlannerApp(),
    ),
  );
  
  // Check login status after runApp to avoid blocking startup
  authProvider.checkLoginStatus();
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to AuthProvider
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        final ThemeData currentTheme = themeProvider.themeData;
        return MaterialApp(
          title: 'Study Planner',
          theme: currentTheme.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: authProvider.isCheckingLogin
              ? const SplashScreen()
              : authProvider.isLoggedIn
                  ? MainScreen(userId: authProvider.currentUser!.id!)
                  : const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// Simple splash screen to show while checking login status
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_icon.png', width: 100, height: 100, errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.school, size: 100, color: Colors.blue)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading your study planner...'),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int userId; // <<< Accept userId
  const MainScreen({super.key, required this.userId}); // <<< Require userId

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Course> _courses = [];
  int _previousIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // <<< Use DatabaseHelper

  @override
  void initState() {
    super.initState();
    _loadData(); 
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    
    try {
      // Load courses from the database
      List<Course> loadedCourses = await _dbHelper.getCourses(widget.userId);
      
      if (mounted) {
        setState(() {
          _courses = loadedCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("ERROR loading data in MainScreen: $e");
      if (mounted) {
        setState(() {
          _courses = [];
          _isLoading = false;
        });
        
        // Show an error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading courses. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ),
        );
      }
    }
  }

  // --- Course Management Navigation & Callbacks (Modified for DB) ---

  // Navigate to Add Course screen and handle result (save to DB)
  Future<void> _navigateToAddCourse() async {
    final newCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(
        builder: (ctx) => const AddCourseScreen(),
      ),
    );

    if (newCourse != null && mounted) {
      try {
        // Check if the course is a predefined course with tasks
        final isPredefined = newCourse.metadata != null && 
                            newCourse.metadata!.containsKey('isPredefined') && 
                            newCourse.metadata!['isPredefined'] == true;
        
        if (isPredefined) {
          // This is a predefined course, get associated tasks from the service
          final programId = newCourse.metadata!['programId'] as String;
          final programName = newCourse.metadata!['programName'] as String;
          
          // Get tasks for this program
          final tasks = PredefinedCoursesService.getTasksForProgramCourse(newCourse);
          
          // Add both the course and its tasks to the database
          final result = await _dbHelper.addPredefinedCourseWithTasks(newCourse, tasks, widget.userId);
          
          if (result > 0) {
            setState(() {
              _courses.add(newCourse);
              _courses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added "${newCourse.name}" from $programName program with ${tasks.length} tasks.'
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Force reload tasks in the TasksProvider to show the new tasks
            final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
            await tasksProvider.refreshTasks();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding predefined course "${newCourse.name}".'), duration: const Duration(seconds: 2)),
            );
          }
        } else {
          // Regular course, add normally
          final result = await _dbHelper.addCourse(newCourse, widget.userId);
          if (result > 0) {
            setState(() {
              _courses.add(newCourse);
              // Sort courses
              _courses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Course "${newCourse.name}" added.'), duration: const Duration(seconds: 2)),
            );
          } else {
            // Handle DB error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding course "${newCourse.name}".'), duration: const Duration(seconds: 2)),
            );
          }
        }
      } catch (e) {
        print("ERROR adding course: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not add course "${newCourse.name}".'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // Navigate to Edit Course screen and handle result (update in DB)
  Future<void> _navigateToEditCourse(Course courseToEdit) async {
    final updatedCourse = await Navigator.of(context).push<Course>(
      CupertinoPageRoute(
        builder: (ctx) => AddCourseScreen(initialCourse: courseToEdit), 
      ),
    );

    if (updatedCourse != null && mounted) {
      try {
        // Update course in DB
        final result = await _dbHelper.updateCourse(updatedCourse, widget.userId);
        if (result > 0) {
          setState(() {
            final index = _courses.indexWhere((c) => c.id == updatedCourse.id);
            if (index != -1) {
              _courses[index] = updatedCourse;
              _courses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Course "${updatedCourse.name}" updated.'), duration: const Duration(seconds: 2)),
          );
        } else {
          // Handle DB error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating course "${updatedCourse.name}".'), duration: const Duration(seconds: 2)),
          );
        }
      } catch (e) {
        print("ERROR updating course: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not update course "${updatedCourse.name}".'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // Handle Deleting a Course (delete from DB)
  Future<void> _handleDeleteCourse(String courseId) async {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;
    final courseName = _courses[courseIndex].name;

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

    if (confirm == true && mounted) {
      try {
        // Get TasksProvider to delete associated tasks
        final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
        
        // Delete associated tasks from DB via provider
        await tasksProvider.deleteTasksForCourse(courseId);
        
        // Delete the course from DB
        final result = await _dbHelper.deleteCourse(courseId, widget.userId);
        
        if (result > 0) {
          setState(() {
            _courses.removeAt(courseIndex);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Course "$courseName" and associated tasks deleted.'), duration: const Duration(seconds: 2)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting course "$courseName".'), duration: const Duration(seconds: 2)),
          );
        }
      } catch (e) {
        print("ERROR deleting course: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not delete course "$courseName".'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  // --- Navigation ---
  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
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
          onEditCourse: _navigateToEditCourse, 
        );
      case 1: // Courses
        return CourseListScreen(
          courses: currentCourses,
          onAdd: _navigateToAddCourse,
          onEdit: _navigateToEditCourse,
          onDelete: _handleDeleteCourse,
        );
      case 2: // Tasks
        return TaskListScreen(
          courses: currentCourses,
        );
      case 3: // Stats
        return StatsScreen(courses: currentCourses);
      case 4: // Settings
        return SettingsScreen();
      default:
        return DashboardScreen(courses: currentCourses, onEditCourse: _navigateToEditCourse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Determine slide direction based on index change
                final slidingRight = _selectedIndex < _previousIndex;
                
                // Use a combined animation for iOS-like transitions
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(slidingRight ? -1.0 : 1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart, // More iOS-like curve
                ));
                
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.3, 1.0), // Start fading in slightly after slide begins
                    ),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex), // Use a key to ensure rebuilds on tab changes
                child: _buildScreen(_selectedIndex),
              ),
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
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              onPressed: _navigateToAddCourse,
              tooltip: 'Add Course',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
