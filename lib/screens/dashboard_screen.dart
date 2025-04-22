import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For groupBy and sorting
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar
import 'package:provider/provider.dart'; // Import Provider
import '../models/course.dart';
import '../models/schedule_entry.dart';
import '../models/task.dart'; // Import Task model
import '../providers/settings_provider.dart'; // Import SettingsProvider

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

class _DashboardScreenState extends State<DashboardScreen> {

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

  @override
  Widget build(BuildContext context) {
    final todaysSchedule = _getTodaysSchedule();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- Calculate Stats ---
    final totalTasks = widget.tasks.length;
    final completedTasks = widget.tasks.where((task) => task.isComplete).length;

    // Get SettingsProvider
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: ListView( // Use ListView to allow scrolling multiple sections
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Weekly View Section ---
           Text("Weekly View", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12.0),
           Card(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 8.0), // Padding inside card
               child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1), // Example range
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: settingsProvider.startingDayOfWeek, // Use value from provider
                  selectedDayPredicate: (day) {
                    // Use `selectedDayPredicate` to determine which day is currently selected. 
                    // `isSameDay` is recommended to compare only day/month/year.
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      // Call `setState()` when updating the selected day
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // update `_focusedDay` as well
                      });
                      // Add logic here if you want to display details for the selected day below the calendar
                    }
                  },
                  onFormatChanged: (format) {
                    // Allow changing format if needed later (e.g., week/month toggle)
                    // For now, keep it fixed to week
                    // if (_calendarFormat != format) {
                    //   setState(() {
                    //     _calendarFormat = format;
                    //   });
                    // }
                  },
                  onPageChanged: (focusedDay) {
                    // No need to call `setState()` here
                    _focusedDay = focusedDay;
                  },
                  // --- Add Event Loader --- 
                  eventLoader: _getEventsForDay,
                  // Basic styling (can be customized further)
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false, // Hide format button for now
                    titleCentered: true,
                    titleTextStyle: textTheme.titleMedium ?? const TextStyle(),
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
} 