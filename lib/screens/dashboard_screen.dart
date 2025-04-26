import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For groupBy and sorting
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar
import 'package:provider/provider.dart'; // Import Provider
import 'package:flutter/cupertino.dart'; // Import Cupertino library
import '../models/course.dart';
import '../models/schedule_entry.dart';
import '../models/task.dart'; // Import Task model
import '../providers/settings_provider.dart'; // Import SettingsProvider
import 'package:intl/intl.dart'; // For date formatting
import '../widgets/tap_scale_container.dart'; // Import for animations if needed elsewhere
import '../screens/task_list_screen.dart'; // Import TaskListScreen

// Convert to StatefulWidget
class DashboardScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Task> tasks; // Add tasks parameter
  final Function(String) onToggleTaskComplete; // Add callback parameter

  const DashboardScreen({
    super.key,
    required this.courses,
    required this.tasks, // Make required
    required this.onToggleTaskComplete, // Make required
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// Helper class to hold agenda item details
class AgendaItem {
  final String courseName;
  final Color courseColor;
  final TimeOfDay timeOfDay;
  final ScheduleEntry entry; // Keep original entry if needed later

  AgendaItem({
    required this.courseName,
    required this.courseColor,
    required this.timeOfDay,
    required this.entry,
  });
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {

  // --- State for Calendar ---
  CalendarFormat _calendarFormat = CalendarFormat.week; 
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<AgendaItem> _getTodaysSchedule() {
    final now = DateTime.now();
    // DateTime.weekday: Monday = 1, Sunday = 7
    // DayOfWeek enum: monday = 0, sunday = 6
    final today = DayOfWeek.values[now.weekday - 1]; 

    List<AgendaItem> todaysAgenda = [];

    for (final course in widget.courses) {
      for (final entry in course.schedule) {
        if (entry.day == today) {
          todaysAgenda.add(AgendaItem(
            courseName: course.name,
            courseColor: course.colorValue, // Use getter for Color
            timeOfDay: entry.time,
            entry: entry
          ));
        }
      }
    }

    // Sort the agenda items by time
    todaysAgenda.sort((a, b) {
       final aTotalMinutes = a.timeOfDay.hour * 60 + a.timeOfDay.minute;
       final bTotalMinutes = b.timeOfDay.hour * 60 + b.timeOfDay.minute;
       return aTotalMinutes.compareTo(bTotalMinutes);
    });

    return todaysAgenda;
  }

  // --- Helper to calculate progress ---
  double _calculateCourseProgress(String courseId) {
    final courseTasks = widget.tasks.where((task) => task.courseId == courseId).toList();
    if (courseTasks.isEmpty) {
      return 0.0; // Or 1.0 if you prefer (no tasks = 100% complete?)
    }
    final completedTasks = courseTasks.where((task) => task.isComplete).length;
    return completedTasks / courseTasks.length;
  }

  // --- Event Loader for TableCalendar ---
  List<Object> _getEventsForDay(DateTime day) {
    List<Object> events = [];

    // Check for courses scheduled on this day of the week
    final dayOfWeek = DayOfWeek.values[day.weekday - 1];
    events.addAll(widget.courses.where((course) {
      return course.schedule.any((entry) => entry.day == dayOfWeek);
    }));

    // Check for tasks due on this specific day
    events.addAll(widget.tasks.where((task) {
      if (task.dueDate == null) return false;
      // Compare year, month, and day only
      return isSameDay(task.dueDate!, day);
    }));

    // Return a list of Course/Task objects. TableCalendar just checks if it's non-empty.
    return events; 
  }

  // --- Calculation Helpers ---

  List<Task> _getTasksDueToday() {
    final now = DateTime.now();
    return widget.tasks.where((task) => 
      task.dueDate != null && isSameDay(task.dueDate!, now)
    ).toList();
  }

  List<Task> _getTasksDueThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - settingsProvider.startingDayOfWeek.index)); // Assumes monday=0, sunday=6
    // Use index from StartingDayOfWeek enum provided by table_calendar
    // Monday = 1 -> index 0
    // Sunday = 7 -> index 6
    int startOffset = settingsProvider.startingDayOfWeek.index; // 0 for Monday, 6 for Sunday
    final startOfWeekDate = now.subtract(Duration(days: (now.weekday - 1 - startOffset + 7) % 7)); 
    final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6));

    return widget.tasks.where((task) {
      if (task.dueDate == null) return false;
      // Exclude today
      if (isSameDay(task.dueDate!, now)) return false; 
      // Check if due date is within the current week (inclusive start, inclusive end)
      return !task.dueDate!.isBefore(startOfWeekDate) && 
             !task.dueDate!.isAfter(endOfWeekDate);
    }).toList();
  }

  List<Task> _getOverdueTasks() {
     final now = DateTime.now();
     // A task is overdue if it's not complete and its due date is before today (ignoring time)
     return widget.tasks.where((task) => 
       !task.isComplete && 
       task.dueDate != null && 
       task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))
     ).toList();
  }

  // Access SettingsProvider within build or where context is available
  late SettingsProvider settingsProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize settingsProvider here as context is available
    settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final todaysSchedule = _getTodaysSchedule();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- Calculate All Stats ---
    final tasksDueToday = _getTasksDueToday();
    final tasksDueThisWeek = _getTasksDueThisWeek();
    final overdueTasks = _getOverdueTasks();
    final activeCoursesCount = widget.courses.length;
    
    // Re-add these needed calculations
    final totalTasks = widget.tasks.length;
    final completedTasks = widget.tasks.where((task) => task.isComplete).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView( // Use ListView to allow scrolling multiple sections
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Summary Cards Section ---
           Text("Summary", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           Wrap(
             spacing: 12.0, // Horizontal space between cards
             runSpacing: 12.0, // Vertical space between rows
             children: [
               _buildSummaryCard(context, 'Courses Active', activeCoursesCount.toString(), Icons.book_outlined),
               _buildSummaryCard(context, 'Tasks Due Today', tasksDueToday.length.toString(), Icons.today_outlined),
               _buildSummaryCard(context, 'Due This Week', tasksDueThisWeek.length.toString(), Icons.date_range_outlined),
               _buildSummaryCard(context, 'Overdue Tasks', overdueTasks.length.toString(), Icons.warning_amber_rounded, 
                                 valueColor: overdueTasks.isNotEmpty ? theme.colorScheme.error : null),
             ],
           ),
           const SizedBox(height: 24.0), // Space before next section

          // --- Weekly View Section ---
           Text("Weekly View", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           Card(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 8.0), 
               // Wrap TableCalendar with AnimatedSize
               child: AnimatedSize(
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeInOut,
                 child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: settingsProvider.startingDayOfWeek,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      // Always show the popup when a day is tapped
                      _showDayDetailsPopup(selectedDay); 

                      // Only update state if the selected day has actually changed
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay; // Update focused day as well
                        });
                      } else {
                         // If the same day is tapped, we might still want to ensure it's focused
                         // although TableCalendar might handle this already. 
                         // Adding it defensively.
                         if (!isSameDay(_focusedDay, focusedDay)) {
                            setState(() {
                                _focusedDay = focusedDay;
                            });
                         }
                      }
                    },
                    // Implement onFormatChanged
                    onFormatChanged: (format) {
                       if (_calendarFormat != format) {
                         setState(() {
                           _calendarFormat = format;
                         });
                       }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getEventsForDay,
                    headerStyle: HeaderStyle(
                      // Show format button
                      formatButtonVisible: true, 
                      titleCentered: true,
                      titleTextStyle: textTheme.titleMedium ?? const TextStyle(),
                      // Optional: Customize format button text/icon
                      // formatButtonTextStyle: ..., 
                      // formatButtonDecoration: ..., 
                      // formatButtonShowsNext: false, // default true
                    ),
                    calendarStyle: CalendarStyle(
                       todayDecoration: BoxDecoration(
                         color: theme.colorScheme.primary.withOpacity(0.5),
                         shape: BoxShape.circle,
                       ),
                       selectedDecoration: BoxDecoration(
                         color: theme.colorScheme.primary,
                         shape: BoxShape.circle,
                       ),
                       // Style for marker(s)
                       markerDecoration: BoxDecoration(
                          color: theme.colorScheme.secondary, // Use secondary color for markers
                          shape: BoxShape.circle,
                       ),
                     ),
                    calendarBuilders: CalendarBuilders(), // Use default builders for now
                  ),
               ),
             ),
           ),
           const SizedBox(height: 24.0),
           
           // --- Today's Agenda Section ---
          Text("Today's Agenda", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           todaysSchedule.isEmpty
            ? const Card( // Use a card for better visual separation
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Nothing scheduled for today! Enjoy your day.')),
                ),
              )
            : Card(
               // elevation: 1,
               // clipBehavior: Clip.antiAlias, // Optional: ensures content respects rounded corners
                child: ListView.separated(
                  shrinkWrap: true, // Important inside another ListView
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                  itemCount: todaysSchedule.length,
                  itemBuilder: (context, index) {
                    final item = todaysSchedule[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.courseColor,
                        radius: 15,
                      ),
                      title: Text(item.courseName),
                      trailing: Text(
                         item.timeOfDay.format(context), 
                         style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                       ),
                      // Add onTap later if needed
                    );
                  },
                   separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16), // Add dividers
                ),
              ),

          // --- Course Progress Section ---
           const SizedBox(height: 24.0),
           Text("Course Progress", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           widget.courses.isEmpty
            ? const Card( // Handle case with no courses
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Add courses to track progress.')),
                ),
              )
            : Card(
                // Build list of progress bars
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding top/bottom
                   child: ListView.separated(
                     shrinkWrap: true, 
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: widget.courses.length,
                     itemBuilder: (context, index) {
                       final course = widget.courses[index];
                       final progress = _calculateCourseProgress(course.id);
                       return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(course.name, style: textTheme.titleMedium),
                                 Text('${(progress * 100).toStringAsFixed(0)}%', style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                               ],
                             ),
                             const SizedBox(height: 6.0),
                             LinearProgressIndicator(
                               value: progress,
                               backgroundColor: theme.colorScheme.surfaceVariant, 
                               valueColor: AlwaysStoppedAnimation<Color>(course.colorValue),
                               minHeight: 6, // Make the bar slightly thicker
                               borderRadius: BorderRadius.circular(3), // Rounded corners
                             ),
                           ],
                         ),
                       );
                     },
                     separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                   ),
                 ),
               ),

           const SizedBox(height: 24.0),
           Text("Stats", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           Card(
             child: Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjusted padding
               child: Row( // Use Row for horizontal layout
                 mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out elements
                 children: [
                    const Row( // Group icon and label
                     children: [
                       Icon(Icons.task_alt, color: Colors.green),
                       SizedBox(width: 8),
                       Text('Tasks Completed:'),
                     ],
                   ),
                   Text(
                     '$completedTasks / $totalTasks',
                     style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                   ),
                  // Add more stats later (e.g., streak)
                 ],
               ),
             ),
           ),

        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Updated Summary Card to be tappable
  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, {Color? valueColor}) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Determine filter logic based on title
    List<Task>? filteredTasks;
    String screenTitle = 'Tasks'; // Default title for the pushed screen

    VoidCallback? onTapAction;
    if (title == 'Tasks Due Today') {
      filteredTasks = _getTasksDueToday();
      screenTitle = 'Tasks Due Today';
    } else if (title == 'Due This Week') {
      filteredTasks = _getTasksDueThisWeek();
      screenTitle = 'Tasks Due This Week';
    } else if (title == 'Overdue Tasks') {
      filteredTasks = _getOverdueTasks();
      screenTitle = 'Overdue Tasks';
    } // Add more cases if needed, e.g., for 'Courses Active'

    if (filteredTasks != null) {
      final tasksToShow = filteredTasks; // Capture for closure
      onTapAction = () {
        Navigator.of(context).push(
          // Use CupertinoPageRoute for iOS-style transition
          CupertinoPageRoute(
            builder: (ctx) => TaskListScreen(
              tasks: tasksToShow, // Pass the pre-filtered list
              courses: widget.courses, // Pass all courses for lookups
              onToggleTaskComplete: widget.onToggleTaskComplete,
              // We might need dummy or adapted callbacks if add/edit/delete
              // should behave differently or be disabled in this filtered view.
              // For now, let's pass them through, but they might need adjustment.
              onAddTask: () { /* Decide how adding works here - maybe add with date prefilled? */
                 ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Add Task Tapped (from filtered view)')));
              },
              onEditTask: (task) { /* Decide how editing works */
                 ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Edit Task Tapped (from filtered view)')));
              },
              onDeleteTask: (taskId) { /* Decide how deleting works */
                 ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Delete Task Tapped (from filtered view)')));
              }, 
              onLogTime: (taskId, duration) { /* Decide how logging works */
                 ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Log Time Tapped (from filtered view)')));
              },
              // Optionally add a specific title to the TaskListScreen
              // appBarTitle: screenTitle, 
            ),
          ),
        );
      };
    }

    return SizedBox(
      width: 160, // Fixed width or use constraints
      child: InkWell( // Make card tappable
        onTap: onTapAction, // Assign the tap action
        borderRadius: BorderRadius.circular(12.0), // Match card's border radius
        child: Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Fit content vertically
              children: [
                Icon(icon, size: 28.0, color: theme.colorScheme.primary),
                const SizedBox(height: 8.0),
                Text(title, style: textTheme.bodyMedium),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? theme.colorScheme.onSurface, // Use provided color or default
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Placeholder build methods for list sections ---
  // (These need to contain the actual list building logic from the original code)
  Widget _buildTodaysSchedule(BuildContext context, List<AgendaItem> schedule) {
     if (schedule.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Nothing scheduled for today.')));
    }
    // Replace with actual ListView.builder logic for schedule items
    return Text('[Placeholder for Today\'s Schedule List]'); 
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    // Filter tasks (e.g., incomplete and due soon)
    final upcoming = widget.tasks.where((t) => !t.isComplete).toList();
    upcoming.sort((a, b) {
       // Sort logic (e.g., by due date)
       if (a.dueDate == null && b.dueDate == null) return 0;
       if (a.dueDate == null) return 1;
       if (b.dueDate == null) return -1;
       return a.dueDate!.compareTo(b.dueDate!);
    });

    if (upcoming.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('No upcoming tasks.')));
    }
     // Replace with actual ListView.builder logic for task items, using CheckboxListTile etc.
     // It will need access to onToggleTaskComplete callback.
    return Text('[Placeholder for Upcoming Tasks List - Needs ListView.builder implementation]');
  }

  // --- Function to show day details pop-up ---
  void _showDayDetailsPopup(DateTime selectedDate) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Filter tasks due on the selected date
    final tasksDueOnDay = widget.tasks.where((task) {
      return task.dueDate != null && isSameDay(task.dueDate!, selectedDate);
    }).toList();

    // Calculate total time logged for tasks due on that day
    Duration totalTimeLoggedForDay = Duration.zero;
    for (var task in tasksDueOnDay) {
      totalTimeLoggedForDay += task.totalTimeSpent;
    }
    final timeLoggedString = '${totalTimeLoggedForDay.inHours}h ${totalTimeLoggedForDay.inMinutes.remainder(60)}m';

    // --- TODO: Filter tasks completed on this day (requires Task model change) ---
    // final tasksCompletedOnDay = widget.tasks.where(...).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // Start at 40% height
          minChildSize: 0.2,   // Allow shrinking to 20%
          maxChildSize: 0.6,   // Allow expanding to 60%
          builder: (_, scrollController) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Text(
                      DateFormat.yMMMEd().format(selectedDate), // Format: e.g., Wed, Sep 28, 2023
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                      child: Container( // Handle graphic
                         width: 40, height: 4, 
                         decoration: BoxDecoration(
                           color: Colors.grey[300],
                           borderRadius: BorderRadius.circular(10)
                         )
                      ),
                  ),
                  const SizedBox(height: 20),

                  // Time Logged Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text('Time Logged (for tasks due): ', style: textTheme.titleMedium),
                       Text(timeLoggedString, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Tasks Due Section
                  Text('Tasks Due:', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded( // Make the list scrollable if it exceeds space
                    child: tasksDueOnDay.isEmpty
                        ? const Center(child: Text('No tasks due on this day.'))
                        : ListView.builder(
                            controller: scrollController, // Use the controller for scrolling
                            itemCount: tasksDueOnDay.length,
                            itemBuilder: (listCtx, index) {
                              final task = tasksDueOnDay[index];
                              return CheckboxListTile(
                                title: Text(task.title,
                                      style: task.isComplete
                                          ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                                          : null),
                                value: task.isComplete,
                                onChanged: (_) => widget.onToggleTaskComplete(task.id),
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
                  ),

                  // --- TODO: Add completed tasks section later ---

                ],
              ),
            ),
        );
      },
    );
  }
} 