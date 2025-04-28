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
import 'course_detail_screen.dart'; // Import Course Detail Screen
import '../providers/tasks_provider.dart'; // <<< Add tasks provider import
import '../utils/task_filter.dart'; // <<< Import TaskFilter

// Convert to StatefulWidget
class DashboardScreen extends StatefulWidget {
  final List<Course> courses;
  final Function(Course) onEditCourse;

  const DashboardScreen({
    super.key,
    required this.courses,
    required this.onEditCourse,
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

  // PageController for the details popup PageView
  PageController? _detailsPageController;

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
  double _calculateCourseProgress(BuildContext context, String courseId) {
    final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
    final courseTasks = tasks.where((task) => task.courseId == courseId).toList();
    if (courseTasks.isEmpty) return 0.0;
    final completedTasks = courseTasks.where((task) => task.isComplete).length;
    return completedTasks / courseTasks.length;
  }

  // --- Event Loader for TableCalendar ---
  List<Object> _getEventsForDay(BuildContext context, DateTime day) {
    final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
    List<Object> events = [];
    final dayOfWeek = DayOfWeek.values[day.weekday - 1];
    events.addAll(widget.courses.where((course) {
      return course.schedule.any((entry) => entry.day == dayOfWeek);
    }));
    events.addAll(tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }));
    return events;
  }

  // --- Calculation Helpers ---

  List<Task> _getTasksDueToday(BuildContext context) {
    final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
    final now = DateTime.now();
    return tasks.where((task) =>
      task.dueDate != null && isSameDay(task.dueDate!, now)
    ).toList();
  }

  List<Task> _getTasksDueThisWeek(BuildContext context) {
    final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - settingsProvider.startingDayOfWeek.index)); // Assumes monday=0, sunday=6
    // Use index from StartingDayOfWeek enum provided by table_calendar
    // Monday = 1 -> index 0
    // Sunday = 7 -> index 6
    int startOffset = settingsProvider.startingDayOfWeek.index; // 0 for Monday, 6 for Sunday
    final startOfWeekDate = now.subtract(Duration(days: (now.weekday - 1 - startOffset + 7) % 7));
    final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6));

    return tasks.where((task) {
      if (task.dueDate == null) return false;
      // Exclude today
      if (isSameDay(task.dueDate!, now)) return false;
      // Check if due date is within the current week (inclusive start, inclusive end)
      return !task.dueDate!.isBefore(startOfWeekDate) &&
             !task.dueDate!.isAfter(endOfWeekDate);
    }).toList();
  }

  List<Task> _getOverdueTasks(BuildContext context) {
     final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
     final now = DateTime.now();
     // A task is overdue if it's not complete and its due date is before today (ignoring time)
     return tasks.where((task) =>
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
  void dispose() {
    _detailsPageController?.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get tasks from provider here
    final tasksProvider = Provider.of<TasksProvider>(context); // listen: true is default
    final tasks = tasksProvider.tasks;
    final todaysSchedule = _getTodaysSchedule();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- Recalculate stats using context ---
    final tasksDueToday = _getTasksDueToday(context);
    final tasksDueThisWeek = _getTasksDueThisWeek(context);
    final overdueTasks = _getOverdueTasks(context);
    final activeCoursesCount = widget.courses.length;
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isComplete).length;

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
             elevation: 0.5,
             child: Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               // Wrap TableCalendar with AnimatedSize
               child: AnimatedSize(
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeInOut,
                 child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1), // Define reasonable range
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: settingsProvider.startingDayOfWeek,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      // Always show the popup when a day is tapped
                      _showDayDetailsPopup(context, selectedDay);

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
                      // Only update state if mounted to avoid errors during dispose
                      if (mounted) {
                        setState(() {
                           _focusedDay = focusedDay;
                        });
                      }
                    },
                    eventLoader: (day) => _getEventsForDay(context, day),
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
            ? Card( // Use a card for better visual separation
                elevation: 0.5, // Lower elevation
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Nothing scheduled for today! Enjoy your day.')),
                ),
              )
            : Card(
                elevation: 0.5, // Lower elevation
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
                elevation: 0.5, // Lower elevation
                // Build list of progress bars
                 child: Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding top/bottom
                   child: ListView.separated(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: widget.courses.length,
                     itemBuilder: (context, index) {
                       final course = widget.courses[index];
                       final progress = _calculateCourseProgress(context, course.id);
                       // Wrap with InkWell for tap detection
                       return InkWell(
                          onTap: () {
                             Navigator.of(context).push(CupertinoPageRoute(
                               builder: (ctx) => CourseDetailScreen(
                                 course: course,
                                 onEditCourse: widget.onEditCourse, // Use the callback from widget
                               ),
                             ));
                          },
                          borderRadius: BorderRadius.circular(8.0), // Optional: for ink splash shape
                          child: Padding(
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
             elevation: 0.5, // Lower elevation
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

  // Updated Summary Card to be tappable and fill horizontal space
  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, {Color? valueColor}) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate width for two cards per row
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 16.0 * 2; // Padding of the parent ListView
    final wrapSpacing = 12.0; // Spacing defined in the Wrap widget
    final cardWidth = (screenWidth - horizontalPadding - wrapSpacing) / 2;

    // Update filter logic calls to pass context
    List<Task>? filteredTasks;
    String screenTitle = 'Tasks';
    TaskFilter taskFilter = TaskFilter.all; // Default filter

    VoidCallback? onTapAction;
    bool isTaskCard = false; // Flag to identify task-related cards

    if (title == 'Tasks Due Today') {
      filteredTasks = _getTasksDueToday(context);
      screenTitle = 'Tasks Due Today';
      taskFilter = TaskFilter.dueToday;
      isTaskCard = true;
    } else if (title == 'Due This Week') {
      filteredTasks = _getTasksDueThisWeek(context);
      screenTitle = 'Tasks Due This Week';
      taskFilter = TaskFilter.dueThisWeek;
      isTaskCard = true;
    } else if (title == 'Overdue Tasks') {
      filteredTasks = _getOverdueTasks(context);
      screenTitle = 'Overdue Tasks';
      taskFilter = TaskFilter.overdue;
      isTaskCard = true;
    } // Add cases for other potential tappable cards here (e.g., Courses Active -> CourseListScreen)
    // else if (title == 'Courses Active') {
    //   // Define action if needed
    // }

    // Determine if the card should be tappable
    bool allowTap = false;
    if (isTaskCard) {
      // Only allow tap if the filtered task list is not empty
      allowTap = filteredTasks != null && filteredTasks.isNotEmpty;
    } else {
      // Allow tap for non-task cards if an action is defined (currently none for 'Courses Active')
      allowTap = false; // Set to true if you add an action for non-task cards
      // Example: if (title == 'Courses Active') { allowTap = true; /* Define onTapAction below */ }
    }

    // Define the onTap action *only* if tapping is allowed
    if (allowTap) {
      // Keep the existing navigation logic for task cards
       if (isTaskCard) {
          onTapAction = () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (ctx) => TaskListScreen(
                  filter: taskFilter,
                  appBarTitle: screenTitle,
                  courses: widget.courses,
                ),
              ),
            );
          };
       } else {
          // Define actions for other tappable cards here if needed
          // Example:
          // if (title == 'Courses Active') {
          //   onTapAction = () { Navigator.of(context).push(...); };
          // }
       }
    }

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        onTap: allowTap ? onTapAction : null, // Only enable onTap if allowTap is true
        borderRadius: BorderRadius.circular(12.0),
        child: Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: allowTap ? null : Theme.of(context).disabledColor.withOpacity(0.05), // Optional: Dim non-tappable cards
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

  // --- Function to show day details pop-up with Swiping ---
  void _showDayDetailsPopup(BuildContext buildContext, DateTime initialSelectedDate) {
     // Calculate initial page index based on a reasonable range (e.g., 1 year back, 1 year forward)
     final today = DateTime.now();
     final rangeStart = DateTime(today.year - 1, today.month, today.day);
     final initialPageIndex = initialSelectedDate.difference(rangeStart).inDays;

     _detailsPageController = PageController(initialPage: initialPageIndex);

    showModalBottomSheet(
      context: buildContext, // Use passed context
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Use a stateful builder to manage the currently displayed date in the PageView
        DateTime currentPageDate = initialSelectedDate;

        return StatefulBuilder( // Add StatefulBuilder to manage currentPageDate
          builder: (modalContext, setModalState) {
             return DraggableScrollableSheet(
               expand: false,
               initialChildSize: 0.4, // Start at 40% height
               minChildSize: 0.2,   // Allow shrinking to 20%
               maxChildSize: 0.6,   // Allow expanding to 60%
               builder: (_, scrollController) {
                 return PageView.builder(
                    controller: _detailsPageController,
                    onPageChanged: (index) {
                      // Update the date when the page changes
                      final newDate = rangeStart.add(Duration(days: index));
                      setModalState(() {
                         currentPageDate = newDate;
                      });
                      // Update the main calendar focus/selection if desired
                      // This requires passing a callback or using provider if state needs to lift up
                       if (mounted) { // Check if DashboardScreen state is mounted
                         setState(() {
                            _selectedDay = newDate;
                            _focusedDay = newDate;
                         });
                       }
                    },
                    itemBuilder: (pageCtx, pageIndex) {
                       // Calculate the date for the current page
                       final dateForPage = rangeStart.add(Duration(days: pageIndex));
                       // Pass the correct context (modalContext or pageCtx) to content builder
                       return _buildDayDetailsContent(pageCtx, dateForPage, scrollController);
                    },
                 );
               }
            );
          }
        );
      },
    ).whenComplete(() {
      _detailsPageController?.dispose();
      _detailsPageController = null;
    });
  }

  // Helper widget to build the actual content for a given day in the popup
  Widget _buildDayDetailsContent(BuildContext context, DateTime selectedDate, ScrollController scrollController) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Use Consumer or Provider.of to get tasks and listen for changes
    final tasksProvider = Provider.of<TasksProvider>(context);
    final allTasks = tasksProvider.tasks;

    // Filter tasks for the selected date using the latest data
    final tasksDueOnDay = allTasks.where((task) {
      return task.dueDate != null && isSameDay(task.dueDate!, selectedDate);
    }).toList();

    // Calculate time logged based on currently filtered tasks
    Duration currentTotalTimeLoggedForDay = Duration.zero;
    for (var task in tasksDueOnDay) {
      currentTotalTimeLoggedForDay += task.totalTimeSpent;
    }
    final currentTimeLoggedString = '${currentTotalTimeLoggedForDay.inHours}h ${currentTotalTimeLoggedForDay.inMinutes.remainder(60)}m';

    // Removed outer StatefulBuilder as Provider handles updates
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Text(
              DateFormat.yMMMEd().format(selectedDate),
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
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
              Text(currentTimeLoggedString, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),

          // Tasks Due Section
          Text('Tasks Due:', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: tasksDueOnDay.isEmpty
                ? const Center(child: Text('No tasks due on this day.'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: tasksDueOnDay.length,
                    itemBuilder: (listCtx, index) {
                      final task = tasksDueOnDay[index];
                      return CheckboxListTile(
                        title: Text(task.title,
                              style: task.isComplete
                                  ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                                  : null),
                        value: task.isComplete,
                        onChanged: (_) {
                          // Call provider method directly
                          tasksProvider.toggleTaskComplete(task.id);
                          // No need for setPageContentState here - Provider handles notification
                        },
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
          // --- TODO: Add completed tasks section later ---
        ],
      ),
    );
  }
} 