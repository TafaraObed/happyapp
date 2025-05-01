import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For groupBy and sorting
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar
import 'package:provider/provider.dart'; // Import Provider
import 'package:flutter/cupertino.dart'; // Import Cupertino library
import 'package:fl_chart/fl_chart.dart'; // <<< Import fl_chart
import 'dart:io'; // Import dart:io for platform checking
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

  // --- Event Loader for TableCalendar (ensure context is passed if needed) ---
  List<Object> _getEventsForDay(BuildContext context, DateTime day) {
     // Use listen: false if just reading data within the loader
     final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
     List<Object> events = [];
     final dayOfWeek = DayOfWeek.values[day.weekday - 1];
     // Filter courses based on schedule
     events.addAll(widget.courses.where((course) {
       return course.schedule.any((entry) => entry.day == dayOfWeek);
     }));
     // Filter tasks based on due date
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
      !task.isComplete && // Only show incomplete tasks
      task.dueDate != null && 
      isSameDay(task.dueDate!, now)
    ).toList();
  }

  List<Task> _getTasksDueThisWeek(BuildContext context) {
    final tasks = Provider.of<TasksProvider>(context, listen: false).tasks;
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final now = DateTime.now();
    
    // Calculate the start and end of the current week based on user's settings
    int startOffset = settingsProvider.startingDayOfWeek.index; // 0 for Monday, 6 for Sunday
    final startOfWeekDate = now.subtract(Duration(days: (now.weekday - 1 - startOffset + 7) % 7));
    final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6));

    return tasks.where((task) {
      if (task.dueDate == null || task.isComplete) return false; // Skip completed or undated tasks
      
      // Exclude tasks due today and overdue tasks
      if (isSameDay(task.dueDate!, now)) return false;
      if (task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))) return false;
      
      // Check if due date is within the current week (after today, before end of week)
      return task.dueDate!.isAfter(now) && 
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
  // Cache for chart data to avoid recalculation on every build unless tasks change
  Map<DateTime, int>? _weeklyCompletionDataCache;
  Map<String, int>? _taskStatusDataCache;

  @override
  void initState() {
    super.initState();
    // Initialize selected day to today if needed for initial focus
    _selectedDay = _focusedDay;
     // Listen to TasksProvider to clear cache when tasks change
     // No, Provider updates will trigger rebuild anyway. Caching might be premature.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
     // TasksProvider changes will trigger a rebuild via the Provider.of in build().
     // We can calculate chart data within build or dedicated helper methods called from build.
  }

   @override
  void dispose() {
    _detailsPageController?.dispose();
    super.dispose();
  }

  // --- Chart Helper Methods ---

  // Helper to build legend widgets for the pie chart
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWeeklyCompletionChart(BuildContext context, List<Task> tasks) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    // Calculate completions for the last 7 days
    Map<DateTime, int> dailyCompletions = {};
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      dailyCompletions[date] = 0;
    }

    int maxCount = 0;
    for (final task in tasks) {
      if (task.isComplete && task.completedAt != null) {
        final completedDate = DateUtils.dateOnly(task.completedAt!);
        if (dailyCompletions.containsKey(completedDate)) {
          dailyCompletions[completedDate] = dailyCompletions[completedDate]! + 1;
          if (dailyCompletions[completedDate]! > maxCount) {
            maxCount = dailyCompletions[completedDate]!;
          }
        }
      }
    }

    // Ensure y-axis shows at least 1, even if maxCount is 0
    final maxY = (maxCount < 5) ? 5.0 : (maxCount + 1).toDouble();

    final List<BarChartGroupData> barGroups = [];
    dailyCompletions.entries.toList().asMap().forEach((index, entry) {
       final date = entry.key;
       final count = entry.value;
        barGroups.add(
          BarChartGroupData(
            x: index, // Use index for x-axis position
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: primaryColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                )
              ),
            ],
          ),
        );
    });

     if (barGroups.isEmpty) {
       return const Center(child: Text("Not enough data for weekly chart."));
     }

    return LayoutBuilder(
      builder: (context, constraints) {
        return BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: theme.colorScheme.surfaceContainerHighest,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final date = dailyCompletions.keys.elementAt(group.x.toInt());
                  final count = rod.toY.toInt();
                  return BarTooltipItem(
                    '${DateFormat.Md().format(date)}\n', // Format date as Month/Day
                    TextStyle(
                      color: theme.colorScheme.onSurfaceVariant, // Use theme color
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$count completed',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant, // Use theme color
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                // Handle touch events if needed
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Simplified title widget compatible with older versions
                    final index = value.toInt();
                    if (index < 0 || index >= dailyCompletions.length) {
                      return Container();
                    }
                    final date = dailyCompletions.keys.elementAt(index);
                    return Text(
                      DateFormat.E().format(date), // 'E' gives abbreviated day name
                      style: TextStyle(
                        color: onSurfaceVariant, // Use theme color
                        fontWeight: FontWeight.bold,
                        fontSize: 10
                      )
                    );
                  },
                  reservedSize: 22, // Adjust reserved size for labels
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28, // Adjust reserved size for y-axis labels
                  interval: maxY / 5 > 1 ? (maxY / 5).floor().toDouble() : 1, // Dynamic interval, at least 1
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Simplified title widget compatible with older versions
                    if (value % 1 != 0 && value != 0) return Container(); // Only show integer values or 0
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: onSurfaceVariant, // Use theme color
                        fontWeight: FontWeight.bold,
                        fontSize: 10
                      ),
                      textAlign: TextAlign.right,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false, // Remove border
            ),
            barGroups: barGroups,
            gridData: const FlGridData(show: false), // Hide grid lines
          ),
        );
      }
    );
  }

  // Build Pie Chart for Task Status
  Widget _buildTaskStatusPieChart(BuildContext context, Map<String, int> taskStatusData) {
     final theme = Theme.of(context);
     final colors = [
       theme.colorScheme.primary, // Completed
       theme.colorScheme.secondary, // Due Today
       theme.colorScheme.tertiary, // Due This Week
       theme.colorScheme.error,   // Overdue
       theme.colorScheme.surfaceContainerHighest, // Other/Pending
     ];
     final statusLabels = [
       'Completed',
       'Due Today',
       'Due This Week',
       'Overdue',
       'Other/Pending'
     ];

     int totalTasks = taskStatusData.values.fold(0, (sum, count) => sum + count);

     if (totalTasks == 0) {
       return const Center(child: Text("No task data for pie chart."));
     }

     final List<PieChartSectionData> sections = [];
     final List<Widget> legendItems = [];
     int colorIndex = 0;

     taskStatusData.forEach((status, count) {
       if (count > 0) { // Only add sections for non-zero counts
         final isTouched = false; // Placeholder for touch interaction if needed later
         final fontSize = isTouched ? 16.0 : 12.0;
         final radius = isTouched ? 60.0 : 50.0;
         final value = (count / totalTasks) * 100; // Calculate percentage
         final color = colors[colorIndex % colors.length];

         sections.add(PieChartSectionData(
           color: color,
           value: value,
           title: '${value.toStringAsFixed(0)}%', // Show percentage
           radius: radius,
           titleStyle: TextStyle(
             fontSize: fontSize,
             fontWeight: FontWeight.bold,
             color: theme.colorScheme.onPrimary, // Text color on the section
             shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)] // Add shadow for better readability
           ),
           showTitle: true, // Show percentage on slice
         ));
          // Add corresponding legend item
         legendItems.add(_buildLegendItem(color, statusLabels[colorIndex]));
       }
        colorIndex++;
     });


     return LayoutBuilder(
       builder: (context, constraints) {
         return Column( // Use Column to place legend below chart
           mainAxisAlignment: MainAxisAlignment.center,
           mainAxisSize: MainAxisSize.min,
           children: [
             SizedBox( // Constrain the PieChart size
               height: 150, // Adjust height as needed
               width: constraints.maxWidth, // Use available width
               child: PieChart(
                 PieChartData(
                   pieTouchData: PieTouchData(
                     touchCallback: (FlTouchEvent event, pieTouchResponse) {
                       // Handle touch interactions if needed
                     },
                   ),
                   borderData: FlBorderData(show: false),
                   sectionsSpace: 2, // Space between sections
                   centerSpaceRadius: 40, // Make it a donut chart
                   sections: sections,
                 ),
               ),
             ),
             const SizedBox(height: 16), // Space between chart and legend
             Wrap( // Use Wrap for the legend items for responsiveness
               spacing: 12.0, // Horizontal space between items
               runSpacing: 4.0, // Vertical space between lines
               alignment: WrapAlignment.center,
               children: legendItems,
             ),
           ],
         );
       }
     );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get providers
    final tasksProvider = Provider.of<TasksProvider>(context); // listen: true
    final settingsProvider = Provider.of<SettingsProvider>(context); // listen: true for theme/settings changes
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
    final completedTasksCount = tasks.where((task) => task.isComplete).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView( // Keep ListView for scrolling
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Summary Cards Section ---
          Text("Summary", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12.0),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                _buildSummaryCard(context, 'Courses Active', activeCoursesCount.toString(), Icons.book_outlined),
                _buildSummaryCard(context, 'Due Today', tasksDueToday.length.toString(), Icons.today_outlined, onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => TaskListScreen(courses: widget.courses, filter: TaskFilter.dueToday)));
                }),
                _buildSummaryCard(context, 'Due This Week', tasksDueThisWeek.length.toString(), Icons.date_range_outlined, onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => TaskListScreen(courses: widget.courses, filter: TaskFilter.dueThisWeek)));
                }),
                _buildSummaryCard(context, 'Overdue', overdueTasks.length.toString(), Icons.warning_amber_rounded,
                                valueColor: overdueTasks.isNotEmpty ? theme.colorScheme.error : null, onTap: () {
                  if (overdueTasks.isNotEmpty) {
                    Navigator.push(context, CupertinoPageRoute(builder: (_) => TaskListScreen(courses: widget.courses, filter: TaskFilter.overdue)));
                  }
                }),
                _buildSummaryCard(context, 'Completed Tasks', completedTasksCount.toString(), Icons.check_circle_outline,
                                valueColor: completedTasksCount > 0 ? Colors.green[700] : null),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // --- Today's Agenda Section ---
          if (todaysSchedule.isNotEmpty)
             _buildSectionTitle(context, "Today's Agenda"),
          if (todaysSchedule.isNotEmpty)
             SizedBox(
                height: 80, // Adjust height as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: todaysSchedule.length,
                  itemBuilder: (context, index) {
                    final item = todaysSchedule[index];
                    return _buildAgendaCard(context, item);
                  },
                ),
             ),
           if (todaysSchedule.isNotEmpty)
              const SizedBox(height: 24.0),


          // --- Weekly View Section ---
           _buildSectionTitle(context, "Weekly View"),
           Card(
             elevation: 0.5,
              clipBehavior: Clip.antiAlias, // Prevents calendar bleeding out of card corners
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             child: Padding(
               padding: const EdgeInsets.all(8.0),
               child: AnimatedSize(
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeInOut,
                 alignment: Alignment.topCenter, // Add alignment for proper animation
                 child: SizedBox(
                   width: double.infinity, // Ensure full width
                   child: TableCalendar(
                      firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1), // Adjusted range
                      lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      startingDayOfWeek: settingsProvider.startingDayOfWeek,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        _showDayDetailsPopup(context, selectedDay);
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        } else {
                           if (!isSameDay(_focusedDay, focusedDay)) {
                              setState(() { _focusedDay = focusedDay; });
                           }
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        // Don't necessarily change selected day on page change
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() { _calendarFormat = format; });
                        }
                      },
                      // --- Event Loading ---
                       eventLoader: (day) => _getEventsForDay(context, day),
                       // --- Calendar Styling ---
                       calendarStyle: CalendarStyle(
                         // Use theme colors
                         todayDecoration: BoxDecoration(
                           color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                           shape: BoxShape.circle,
                         ),
                         selectedDecoration: BoxDecoration(
                           color: theme.colorScheme.primary,
                           shape: BoxShape.circle,
                         ),
                         markerDecoration: BoxDecoration(
                           color: theme.colorScheme.secondary.withOpacity(0.7),
                           shape: BoxShape.circle,
                         ),
                          // markerSize: 5.0,
                         // markersMaxCount: 1, // Simplified marker display
                         outsideDaysVisible: false,
                         weekendTextStyle: TextStyle(color: theme.colorScheme.tertiary), // Example: Different color for weekends
                         // isTodayHighlighted: true,
                         // selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                         // todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                         // defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                         // weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                         // outsideTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                         canMarkersOverflow: false, // Prevent markers going outside cell
                       ),
                       headerStyle: HeaderStyle(
                         titleCentered: true,
                         formatButtonVisible: true, // Show Week/Month toggle
                         formatButtonShowsNext: false,
                         titleTextStyle: textTheme.titleMedium ?? const TextStyle(),
                         formatButtonTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                         formatButtonDecoration: BoxDecoration(
                           color: theme.colorScheme.primary.withOpacity(0.8),
                           borderRadius: BorderRadius.circular(12.0),
                         ),
                         leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
                         rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                       ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                         weekdayStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                         weekendStyle: TextStyle(color: theme.colorScheme.tertiary), // Consistent weekend color
                      ),
                   ),
                 ),
               ),
             ),
           ),
           const SizedBox(height: 24.0),

          // --- Activity Overview / Charts Section ---
          _buildSectionTitle(context, "Activity Overview"),
          Column(
             children: [
               Card(
                 elevation: 0.5,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("Completed (Last 7 Days)", style: textTheme.titleMedium),
                       const SizedBox(height: 16.0),
                       SizedBox(
                         height: 180, // Fixed height for the chart
                         width: double.infinity, // Add width constraint
                         child: _buildWeeklyCompletionChart(context, tasks),
                       ),
                     ],
                   ),
                 ),
               ),
               const SizedBox(height: 16.0), // Space between charts
               Card(
                 elevation: 0.5,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("Task Status", style: textTheme.titleMedium),
                       const SizedBox(height: 16.0),
                       SizedBox(
                         height: 180, // Fixed height for the chart
                         width: double.infinity, // Add width constraint
                         child: _buildTaskStatusPieChart(context, _taskStatusDataCache ?? {}),
                       ),
                     ],
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 24.0),


          // --- Course Progress Section ---
          _buildSectionTitle(context, "Course Progress"),
          if (widget.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: Text("No courses added yet.", style: textTheme.bodyMedium)),
            )
          else
            ...widget.courses.map((course) => _buildCourseProgressIndicator(context, course, tasks)),

          const SizedBox(height: 60), // Add padding at the bottom
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  // Helper for Section Titles
  Widget _buildSectionTitle(BuildContext context, String title) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12.0),
       child: Text(
         title,
         style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
       ),
     );
  }

  // Helper for Summary Cards
  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, {Color? valueColor, VoidCallback? onTap}) {
     final theme = Theme.of(context);
     return SizedBox(
       width: 160, // Fixed width for all cards
       height: 100, // Fixed height for all cards
       child: Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: InkWell(
             onTap: onTap,
             borderRadius: BorderRadius.circular(12.0),
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space elements evenly
                 children: [
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        Icon(icon, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                     ],
                   ),
                   Text(
                     value,
                     style: theme.textTheme.headlineMedium?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: valueColor ?? theme.colorScheme.onSurface
                     ),
                   ),
                 ],
               ),
             ),
          ),
       ),
     );
  }

   // Helper for Agenda Cards
   Widget _buildAgendaCard(BuildContext context, AgendaItem item) {
       final theme = Theme.of(context);
       final textTheme = theme.textTheme;
       return SizedBox(
           width: 160, // Fixed width for horizontal scrolling cards
           child: Card(
               elevation: 0.5,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
               margin: const EdgeInsets.only(right: 12.0), // Space between cards
               child: InkWell(
                   onTap: () {
                     // Find the course and navigate to its detail screen
                     final course = widget.courses.firstWhere(
                       (c) => c.name == item.courseName,
                       orElse: () => widget.courses.first,
                     );
                     Navigator.push(
                       context,
                       CupertinoPageRoute(
                         builder: (_) => CourseDetailScreen(
                           course: course,
                           onEditCourse: widget.onEditCourse,
                         ),
                       ),
                     );
                   },
                   borderRadius: BorderRadius.circular(12.0),
                   child: Padding(
                       padding: const EdgeInsets.all(12.0),
                       child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                               Text(
                                   item.courseName,
                                   style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                   overflow: TextOverflow.ellipsis,
                               ),
                               const SizedBox(height: 4),
                               Row(
                                  children: [
                                     Icon(Icons.access_time, size: 14, color: theme.colorScheme.secondary),
                                     const SizedBox(width: 4),
                                     Text(item.timeOfDay.format(context), style: textTheme.bodySmall),
                                  ],
                               ),
                           ],
                       ),
                   ),
               ),
           ),
       );
   }

  // Helper for Course Progress Indicator
  Widget _buildCourseProgressIndicator(BuildContext context, Course course, List<Task> allTasks) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final courseTasks = allTasks.where((task) => task.courseId == course.id).toList();
    final completedTasks = courseTasks.where((task) => task.isComplete).length;
    final progress = courseTasks.isEmpty ? 0.0 : completedTasks / courseTasks.length;

     // Find the next due task for this course
    Task? nextDueTask;
    DateTime? nextDueDate;
    final now = DateTime.now();
    for (final task in courseTasks) {
      if (!task.isComplete && task.dueDate != null && task.dueDate!.isAfter(now)) {
        if (nextDueDate == null || task.dueDate!.isBefore(nextDueDate)) {
          nextDueDate = task.dueDate;
          nextDueTask = task;
        }
      }
    }


    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(
               builder: (_) => CourseDetailScreen(course: course, onEditCourse: widget.onEditCourse)
            ));
          },
          borderRadius: BorderRadius.circular(12.0),
         child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Flexible(
                        child: Text(course.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                     ),
                      Text(
                         '${(progress * 100).toStringAsFixed(0)}%',
                         style: textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                       ),
                   ],
                ),
                const SizedBox(height: 8.0),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: course.colorValue, // Use course color
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8.0),
                // Show next due task info
                 if (nextDueTask != null && nextDueDate != null)
                   Row(
                      children: [
                         Icon(Icons.arrow_forward, size: 14, color: theme.colorScheme.secondary),
                         const SizedBox(width: 4),
                         Expanded(
                           child: Text(
                              'Next: ${nextDueTask.title} (Due ${DateFormat.Md().format(nextDueDate)})',
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                           ),
                         ),
                      ],
                   )
                 else if (courseTasks.isNotEmpty && progress == 1.0)
                   Row(
                     children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text('All tasks complete!', style: textTheme.bodySmall),
                     ],
                   )
                  else if (courseTasks.isEmpty)
                     Text('No tasks added for this course.', style: textTheme.bodySmall),
              ],
            ),
          ),
       ),
    );
  }

   // --- Popup for Day Details ---
   void _showDayDetailsPopup(BuildContext context, DateTime selectedDay) {
     final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
     final tasks = tasksProvider.tasks;
     final settings = Provider.of<SettingsProvider>(context, listen: false);

     final dayOfWeek = DayOfWeek.values[selectedDay.weekday - 1];
     final coursesOnDay = widget.courses.where((c) {
        return c.schedule.any((entry) => entry.day == dayOfWeek);
      }).toList();
     // Sort courses by scheduled time on that day
     coursesOnDay.sort((a, b) {
       final timeA = a.schedule.firstWhere((e) => e.day == dayOfWeek).time;
       final timeB = b.schedule.firstWhere((e) => e.day == dayOfWeek).time;
       final totalMinutesA = timeA.hour * 60 + timeA.minute;
       final totalMinutesB = timeB.hour * 60 + timeB.minute;
       return totalMinutesA.compareTo(totalMinutesB);
     });

     final tasksDueOnDay = tasks.where((t) => t.dueDate != null && isSameDay(t.dueDate!, selectedDay)).toList();
     // Sort tasks due today by completion status (incomplete first), then title
     tasksDueOnDay.sort((a, b) {
        if (a.isComplete != b.isComplete) {
           return a.isComplete ? 1 : -1; // Incomplete first
        }
        return a.title.compareTo(b.title);
     });

      // No need to show popup if nothing is scheduled or due
      if (coursesOnDay.isEmpty && tasksDueOnDay.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Nothing scheduled or due on ${DateFormat.yMMMd().format(selectedDay)}.'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
         ));
         return;
      }

     showModalBottomSheet(
       context: context,
       isScrollControlled: true, // Allow taller sheet
       shape: const RoundedRectangleBorder(
         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
       ),
       builder: (ctx) {
         final theme = Theme.of(ctx);
         return StatefulBuilder( // Add StatefulBuilder to handle state updates
           builder: (context, setState) {
             return DraggableScrollableSheet(
               expand: false,
               initialChildSize: 0.4,
               minChildSize: 0.3,
               maxChildSize: 0.7,
               builder: (_, controller) {
                 return Container(
                   padding: const EdgeInsets.all(16.0),
                   child: ListView(
                     controller: controller,
                     children: [
                       Center(
                          child: Container(
                             height: 5,
                             width: 40,
                             decoration: BoxDecoration(
                               color: theme.dividerColor,
                               borderRadius: BorderRadius.circular(10),
                             ),
                           ),
                        ),
                       const SizedBox(height: 16),
                       Text(
                         DateFormat.yMMMEd().format(selectedDay),
                         style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 16),

                       if (coursesOnDay.isNotEmpty)
                         Text('Scheduled Courses', style: theme.textTheme.titleMedium),
                       if (coursesOnDay.isNotEmpty)
                         ...coursesOnDay.map((course) {
                           final entry = course.schedule.firstWhere((e) => e.day == dayOfWeek);
                           return ListTile(
                             leading: Icon(Icons.class_outlined, color: course.colorValue),
                             title: Text(course.name),
                             trailing: Text(entry.time.format(ctx)),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                           );
                         }),
                       if (coursesOnDay.isNotEmpty)
                          const SizedBox(height: 16),

                       if (tasksDueOnDay.isNotEmpty)
                         Text('Tasks Due', style: theme.textTheme.titleMedium),
                       if (tasksDueOnDay.isNotEmpty)
                          ...tasksDueOnDay.map((task) {
                           final courseName = widget.courses.firstWhereOrNull((c) => c.id == task.courseId)?.name;
                           return ListTile(
                             leading: InkWell(
                               onTap: () async {
                                 // Toggle task completion
                                 final updatedTask = task.copyWith(
                                   isComplete: !task.isComplete,
                                   completedAt: () => !task.isComplete ? DateTime.now() : null,
                                 );
                                 await tasksProvider.editTask(updatedTask);
                                 // Update local state to show change immediately
                                 setState(() {});
                                 // Trigger rebuild of parent widget to update charts and stats
                                 if (mounted) {
                                   this.setState(() {});
                                 }
                               },
                               child: AnimatedSwitcher(
                                 duration: const Duration(milliseconds: 200),
                                 child: Icon(
                                   task.isComplete ? Icons.check_box : Icons.check_box_outline_blank,
                                   color: task.isComplete ? Colors.green : theme.colorScheme.primary,
                                   size: 20,
                                   key: ValueKey(task.isComplete), // Key for animation
                                 ),
                               ),
                             ),
                             title: Text(
                                task.title,
                                style: task.isComplete ? TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.disabledColor
                                ) : null,
                             ),
                             subtitle: courseName != null ? Text(courseName) : null,
                             dense: true,
                             visualDensity: VisualDensity.compact,
                           );
                         }),
                     ],
                   ),
                 );
               },
             );
           }
         );
       },
     );
   }
} 