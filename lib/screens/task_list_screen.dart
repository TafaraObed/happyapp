import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../models/task.dart';
import '../models/course.dart'; // To look up course names
import '../widgets/tap_scale_container.dart'; // Import the new widget
import '../models/time_log_entry.dart'; // Import TimeLogEntry
import 'package:flutter/services.dart'; // For input formatters
import 'task_detail_screen.dart'; // Import the new detail screen
import 'package:flutter/cupertino.dart'; // Import for CupertinoPageRoute
import 'package:provider/provider.dart'; // Add provider import
import '../providers/tasks_provider.dart'; // Add tasks provider import
import 'add_task_screen.dart'; // Import AddTaskScreen
import '../utils/task_filter.dart'; // <<< Import the filter enum
import '../providers/settings_provider.dart'; // <<< Import for week start day
import 'package:table_calendar/table_calendar.dart'; // <<< Import for isSameDay

class TaskListScreen extends StatelessWidget {
  final List<Course> courses;
  final TaskFilter filter; // <<< ADD Filter parameter
  final String? appBarTitle; // Keep optional title

  const TaskListScreen({
    super.key,
    required this.courses,
    this.filter = TaskFilter.all, // <<< ADD Filter (default to all)
    this.appBarTitle,
  });

  // Helper to determine if we are in a non-default filtered view
  bool get _isFilteredView => filter != TaskFilter.all;

  // Helper to find course name from courseId
  String? _getCourseName(String? courseId) {
    if (courseId == null) return null;
    try {
      return courses.firstWhere((course) => course.id == courseId).name;
    } catch (e) {
      return null; // Course not found
    }
  }

  // --- Filter Logic --- (Moved inside build or helper)
  List<Task> _applyFilter(BuildContext context, List<Task> allTasks) {
    final now = DateTime.now();
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    switch (filter) {
      case TaskFilter.dueToday:
        return allTasks.where((task) => task.dueDate != null && isSameDay(task.dueDate!, now)).toList();
      case TaskFilter.dueThisWeek:
        int startOffset = settingsProvider.startingDayOfWeek.index;
        final startOfWeekDate = now.subtract(Duration(days: (now.weekday - 1 - startOffset + 7) % 7));
        final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6));
        return allTasks.where((task) {
          if (task.dueDate == null) return false;
          if (isSameDay(task.dueDate!, now)) return false; // Exclude today
          return !task.dueDate!.isBefore(startOfWeekDate) && !task.dueDate!.isAfter(endOfWeekDate);
        }).toList();
      case TaskFilter.overdue:
        return allTasks.where((task) =>
          !task.isComplete &&
          task.dueDate != null &&
          task.dueDate!.isBefore(DateTime(now.year, now.month, now.day))
        ).toList();
      case TaskFilter.all:
      default:
        return allTasks;
    }
  }

  // --- Dialog for Logging Time ---
  Future<void> _showLogTimeDialog(BuildContext context, Task task) async {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

    final Duration? loggedDuration = await showDialog<Duration>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Log Time for "${task.title}"'),
          content: Form(
            key: formKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: hoursController,
                    decoration: const InputDecoration(labelText: 'Hours', hintText: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                     validator: (value) {
                      if (value == null || value.isEmpty) return null; // Optional
                      if (int.tryParse(value) == null) return 'Invalid';
                      return null;
                     },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(':'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: minutesController,
                    decoration: const InputDecoration(labelText: 'Minutes', hintText: '0'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return null; // Optional
                      final minutes = int.tryParse(value);
                      if (minutes == null || minutes < 0 || minutes > 59) {
                        return '0-59';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Log Time'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final hours = int.tryParse(hoursController.text) ?? 0;
                  final minutes = int.tryParse(minutesController.text) ?? 0;
                  if (hours == 0 && minutes == 0) {
                     // Show snackbar maybe? Or just disallow.
                    return;
                  }
                  final duration = Duration(hours: hours, minutes: minutes);
                  Navigator.of(dialogContext).pop(duration);
                }
              },
            ),
          ],
        );
      },
    );

    if (loggedDuration != null) {
      // Call the provider method
      final updatedTask = tasksProvider.logTimeForTask(task.id, loggedDuration);
      if (updatedTask != null && context.mounted) {
         final hours = loggedDuration.inHours;
         final minutes = loggedDuration.inMinutes.remainder(60);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged ${hours}h ${minutes}m for "${updatedTask.title}".')));
      }
    }
    hoursController.dispose();
    minutesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksProvider = Provider.of<TasksProvider>(context); // Listen to provider
    // Get ALL tasks
    final allTasks = tasksProvider.tasks;
    // Apply the filter
    final filteredTasks = _applyFilter(context, allTasks);

    // Sort the filtered tasks
    List<Task> sortedTasks = List.from(filteredTasks);
    sortedTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
     });

    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    // Determine AppBar Title based on filter if not provided
    final String currentAppBarTitle = appBarTitle ?? _getTitleFromFilter(filter);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAppBarTitle),
        backgroundColor: surfaceColor.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(8.0),
            // Use sorted (and filtered) tasks
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              // IMPORTANT: Get the task by ID from the *original provider list*
              // to ensure we have the latest state for the CheckboxListTile
              // Find the task from the full list that corresponds to the sorted item
              // This assumes task IDs are unique and stable.
              final taskFromSorted = sortedTasks[index];
              Task task = allTasks.firstWhere((t) => t.id == taskFromSorted.id, orElse: () => taskFromSorted);
              // Fallback to taskFromSorted if somehow not found (shouldn't happen)

              final courseName = _getCourseName(task.courseId);
              
              // Build subtitle string incrementally
              List<String> subtitleParts = [];
              if (courseName != null) {
                subtitleParts.add(courseName);
              }
              if (task.dueDate != null) {
                subtitleParts.add('Due: ${DateFormat.yMd().format(task.dueDate!)}');
              }

              // --- Add Grade Display ---
              String gradeString = '';
              if (task.pointsEarned != null && task.pointsPossible != null) {
                 // Format nicely, handling potential decimals
                 final earnedStr = task.pointsEarned!.toStringAsFixed(
                    task.pointsEarned! % 1 == 0 ? 0 : 1 // No decimal if whole number
                 ); 
                 final possibleStr = task.pointsPossible!.toStringAsFixed(
                    task.pointsPossible! % 1 == 0 ? 0 : 1 
                 );
                 gradeString = 'Grade: $earnedStr/$possibleStr';
                 subtitleParts.add(gradeString);
              } else if (task.pointsEarned != null) {
                 // Handle case where only points earned is set (less likely but possible)
                 final earnedStr = task.pointsEarned!.toStringAsFixed(
                    task.pointsEarned! % 1 == 0 ? 0 : 1 
                 );
                 gradeString = 'Grade: $earnedStr';
                 subtitleParts.add(gradeString);
              }
              // --- End Grade Display ---

              // --- Calculate Time Spent Display ---
              final totalTime = task.totalTimeSpent;
              String timeSpentString = '';
              if (totalTime > Duration.zero) {
                final hours = totalTime.inHours;
                final minutes = totalTime.inMinutes.remainder(60);
                timeSpentString = 'Logged: ${hours}h ${minutes}m';
                 subtitleParts.add(timeSpentString); // Add time to parts
              }
              // --- End Time Spent Display ---

              // Combine subtitle parts with a separator
              String subtitle = subtitleParts.join('  •  '); // Use a bullet or similar separator

              // Wrap the animated Card with TapScaleContainer
              return TapScaleContainer(
                onTap: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (ctx) => TaskDetailScreen(
                      task: task,
                      courses: courses,
                      onEditTask: (editedTask) async {
                        final updatedTask = await Navigator.of(context).push<Task>(
                          MaterialPageRoute(builder: (_) => AddTaskScreen(
                            courses: courses,
                            initialTask: editedTask,
                          )),
                        );
                        if (updatedTask != null) {
                          tasksProvider.editTask(updatedTask);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "${updatedTask.title}" updated.')));
                          }
                        }
                      },
                    ),
                  ));
                },
                child: Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: CheckboxListTile(
                    title: Text(
                      task.title,
                      style: task.isComplete 
                        ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                        : null,
                     ),
                    // Use the combined subtitle string
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null, 
                    value: task.isComplete,
                    onChanged: (bool? value) {
                      tasksProvider.toggleTaskComplete(task.id);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    // Conditionally show secondary actions only if NOT in filtered view
                    secondary: _isFilteredView ? null : PopupMenuButton<String>(
                       icon: const Icon(Icons.more_vert),
                       onSelected: (value) async {
                         if (value == 'edit') {
                           final updatedTask = await Navigator.of(context).push<Task>(
                             MaterialPageRoute(builder: (_) => AddTaskScreen(
                               courses: courses,
                               initialTask: task,
                             )),
                           );
                           if (updatedTask != null) {
                              tasksProvider.editTask(updatedTask);
                               if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "${updatedTask.title}" updated.')));
                               }
                           }
                         } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 title: const Text('Confirm Delete'),
                                 content: Text('Delete task "${task.title}"?'),
                                 actions: [
                                   TextButton(
                                     child: const Text('Cancel'),
                                     onPressed: () => Navigator.of(ctx).pop(false),
                                   ),
                                   TextButton(
                                     child: const Text('Delete'),
                                     onPressed: () => Navigator.of(ctx).pop(true),
                                   ),
                                 ],
                               ),
                             ) ?? false;
                            
                            if (confirm && context.mounted) {
                                final deletedTitle = tasksProvider.deleteTask(task.id);
                                if (deletedTitle != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "$deletedTitle" deleted.')));
                                }
                            }
                         } else if (value == 'log_time') {
                            _showLogTimeDialog(context, task);
                         }
                       },
                       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(value: 'log_time', child: ListTile(leading: Icon(Icons.timer_outlined), title: Text('Log Time'))),
                          const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                          const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
                        ],
                    ),
                  ),
                )
                 .animate()
                 .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                 .slideX(begin: 0.2, duration: 400.ms, delay: (100 * index).ms, curve: Curves.easeOutCubic),
              );
            },
          ),
          // Empty State Text (logic remains the same, message might need adjustment for filtered view)
          IgnorePointer(
            ignoring: sortedTasks.isNotEmpty,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: sortedTasks.isEmpty ? 1.0 : 0.0,
              // Consider changing text if filtered: e.g., 'No tasks match this filter.'
              child: Center(child: Text(_isFilteredView ? 'No tasks match this filter.' : 'No tasks added yet!')),
            ),
          ),
        ],
      ),
       // Only show FAB if not in filtered view
       floatingActionButton: _isFilteredView ? null : FloatingActionButton(
         onPressed: () async {
            final newTask = await Navigator.of(context).push<Task>(
               MaterialPageRoute(builder: (ctx) => AddTaskScreen(courses: courses)),
            );
            if (newTask != null) {
               tasksProvider.addTask(newTask);
               if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task "${newTask.title}" added.')));
               }
            }
         },
         tooltip: 'Add Task',
         child: const Icon(Icons.add),
       ).animate().scale(delay: 500.ms),
    );
  }

  // Helper to get default title from filter
  String _getTitleFromFilter(TaskFilter filter) {
     switch (filter) {
      case TaskFilter.dueToday: return 'Tasks Due Today';
      case TaskFilter.dueThisWeek: return 'Tasks Due This Week';
      case TaskFilter.overdue: return 'Overdue Tasks';
      case TaskFilter.all:
      default: return 'Tasks';
    }
  }
} 