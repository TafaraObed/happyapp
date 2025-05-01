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
import 'dart:math'; // For min function in sorting
import 'package:vibration/vibration.dart';  // Add vibration import

// --- Enums for Sorting and Filtering ---
enum SortOption {
  dueDateAsc, dueDateDesc,
  titleAsc, titleDesc,
  courseAsc, courseDesc,
  // Add others like completion status if needed
}

enum CompletionFilter {
  all, complete, incomplete,
}
// --- End Enums ---


// --- StatefulWidget Conversion ---
class TaskListScreen extends StatefulWidget { // Changed to StatefulWidget
  final List<Course> courses;
  final TaskFilter filter; // Base filter (e.g., dueToday, overdue)
  final String? appBarTitle; // Optional title based on base filter

  const TaskListScreen({
    super.key,
    required this.courses,
    this.filter = TaskFilter.all,
    this.appBarTitle,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState(); // Create state
}

class _TaskListScreenState extends State<TaskListScreen> { // State class
  // --- State Variables ---
  SortOption _sortBy = SortOption.dueDateAsc; // Default sort
  CompletionFilter _completionFilter = CompletionFilter.all; // Default filter
  String? _courseFilterId; // Default: filter by all courses
  // --- End State Variables ---


  // Helper to determine if we are in a non-default filtered view (based on widget.filter)
  bool get _isBaseFilteredView => widget.filter != TaskFilter.all;

  // Helper to find course name from courseId
  String? _getCourseName(String? courseId) {
    if (courseId == null) return null;
    try {
      // Access courses from the widget
      return widget.courses.firstWhere((course) => course.id == courseId).name;
    } catch (e) {
      return null; // Course not found
    }
  }

  // --- Filter Logic (Base Filter from widget.filter) ---
  List<Task> _applyBaseFilter(BuildContext context, List<Task> allTasks) {
    final now = DateTime.now();
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    switch (widget.filter) { // Use widget.filter here
      case TaskFilter.dueToday:
        return allTasks.where((task) => task.dueDate != null && isSameDay(task.dueDate!, now)).toList();
      case TaskFilter.dueThisWeek:
        int startOffset = settingsProvider.startingDayOfWeek.index;
        // Adjust logic to match table_calendar's start of week if necessary
        // This calculation seems okay, assuming Sunday = 0, Monday = 1 etc.
        final todayWeekday = now.weekday % 7; // Sunday=0, Monday=1...
        final daysSinceStart = (todayWeekday - startOffset + 7) % 7;
        final startOfWeekDate = DateUtils.dateOnly(now).subtract(Duration(days: daysSinceStart));
        final endOfWeekDate = startOfWeekDate.add(const Duration(days: 6));

        // print("Now: $now, StartOffset: $startOffset, TodayWeekday: $todayWeekday, DaysSinceStart: $daysSinceStart, StartOfWeek: $startOfWeekDate, EndOfWeek: $endOfWeekDate");

        return allTasks.where((task) {
          if (task.dueDate == null) return false;
          final dueDateOnly = DateUtils.dateOnly(task.dueDate!);
           // Include tasks due today within "this week"
          return !dueDateOnly.isBefore(startOfWeekDate) && !dueDateOnly.isAfter(endOfWeekDate);
        }).toList();
      case TaskFilter.overdue:
        return allTasks.where((task) =>
          !task.isComplete &&
          task.dueDate != null &&
          task.dueDate!.isBefore(DateUtils.dateOnly(now)) // Use DateUtils.dateOnly
        ).toList();
      case TaskFilter.all:
      default:
        return allTasks;
    }
  }

  // --- Dialog for Logging Time (Unchanged, kept for context) ---
  Future<void> _showLogTimeDialog(BuildContext context, Task task) async {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // Get providers needed
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture ScaffoldMessenger

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
                    // Optionally show a message if time is zero
                    // scaffoldMessenger.showSnackBar(SnackBar(content: Text('Please enter a duration greater than zero.')));
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
      // Await the result of logging time, which returns Future<Task?>
      final Task? updatedTask = await tasksProvider.logTimeForTask(task.id, loggedDuration);
      
      // Check if the task was successfully updated and the widget is still mounted
      if (updatedTask != null && context.mounted) { 
         final hours = loggedDuration.inHours;
         final minutes = loggedDuration.inMinutes.remainder(60);
         // Use the updatedTask object safely
         scaffoldMessenger.showSnackBar(SnackBar(content: Text('Logged ${hours}h ${minutes}m for "${updatedTask.title}".')));
      } else if (updatedTask == null) {
        // Handle the case where the task update failed in the provider
         scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to log time. Please try again.')));
      }
    }
    hoursController.dispose();
    minutesController.dispose();
  }
   // --- Helper to get AppBar Title (moved to State) ---
  String _getTitleFromFilter(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.dueToday: return 'Due Today';
      case TaskFilter.dueThisWeek: return 'Due This Week';
      case TaskFilter.overdue: return 'Overdue Tasks';
      case TaskFilter.all:
      default: return 'All Tasks';
    }
  }

  // --- Sorting Logic ---
  List<Task> _applySort(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks); // Create a mutable copy
    sortedTasks.sort((a, b) {
      int compareResult = 0;
      switch (_sortBy) {
        case SortOption.dueDateAsc:
          compareResult = _compareDueDates(a.dueDate, b.dueDate);
          break;
        case SortOption.dueDateDesc:
          compareResult = _compareDueDates(b.dueDate, a.dueDate); // Reversed
          break;
        case SortOption.titleAsc:
          compareResult = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortOption.titleDesc:
          compareResult = b.title.toLowerCase().compareTo(a.title.toLowerCase());
          break;
        case SortOption.courseAsc:
          compareResult = _compareCourses(a.courseId, b.courseId);
          break;
        case SortOption.courseDesc:
          compareResult = _compareCourses(b.courseId, a.courseId); // Reversed
          break;
      }
      // As a secondary sort, always put incomplete tasks first within the primary sort
      if (compareResult == 0) {
         if (!a.isComplete && b.isComplete) {
            return -1; // a (incomplete) comes before b (complete)
         } else if (a.isComplete && !b.isComplete) {
            return 1; // b (incomplete) comes before a (complete)
         }
      }
      // If still equal and primary sort was not due date, sort by due date ascending
      if (compareResult == 0 && _sortBy != SortOption.dueDateAsc && _sortBy != SortOption.dueDateDesc) {
         compareResult = _compareDueDates(a.dueDate, b.dueDate);
      }
      return compareResult;
    });
    return sortedTasks;
  }

  // Helper for comparing due dates (nulls last)
  int _compareDueDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1; // Nulls last
    if (b == null) return -1; // Nulls last
    return a.compareTo(b);
  }

  // Helper for comparing courses (nulls last, then by name)
  int _compareCourses(String? courseIdA, String? courseIdB) {
    final nameA = _getCourseName(courseIdA);
    final nameB = _getCourseName(courseIdB);
    if (nameA == null && nameB == null) return 0;
    if (nameA == null) return 1; // Nulls last
    if (nameB == null) return -1; // Nulls last
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }

  // --- Helper to handle navigation to add task screen ---
  void _navigateToAddTask() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddTaskScreen(
          courses: widget.courses,
        ),
      ),
    );
  }

  // Helper to build animated task item
  Widget _buildAnimatedTaskItem(BuildContext context, Task task, String subtitle, Color? tileColor, int animationIndex) {
    // Calculate animation delays explicitly to avoid linter errors
    final Duration fadeInDelay = Duration(milliseconds: 100 * animationIndex);
    final Duration slideDelay = Duration(milliseconds: 100 * animationIndex);
    
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
    
    return TapScaleContainer(
      onTap: () {
        // Find the latest task state using the ID
        final latestTask = tasksProvider.tasks.firstWhere((t) => t.id == task.id, orElse: () => task);

        // Define the edit callback
        void handleEdit(Task taskToEdit) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => AddTaskScreen(
                initialTask: taskToEdit,
                courses: widget.courses,
              ),
            ),
          );
        }

        // Navigate to TaskDetailScreen
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => TaskDetailScreen(
              task: latestTask,
              courses: widget.courses,
              onEditTask: handleEdit,
            ),
          ),
        );
      },
      child: Card(
        elevation: task.isComplete ? 0.5 : 2.0,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        color: tileColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: task.isComplete
              ? BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3), width: 0.5)
              : BorderSide.none,
        ),
        child: CheckboxListTile(
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isComplete ? TextDecoration.lineThrough : null,
              color: task.isComplete ? Theme.of(context).disabledColor : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle.isNotEmpty ? Text(
            subtitle, 
            style: TextStyle(color: task.isComplete ? Theme.of(context).disabledColor : null)
          ) : null,
          value: task.isComplete,
          onChanged: (bool? value) {
            if (value != null) {
              _toggleTaskCompletion(task);
            }
          },
          secondary: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              if (result == 'edit') {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => AddTaskScreen(
                      initialTask: tasksProvider.tasks.firstWhere((t) => t.id == task.id),
                      courses: widget.courses,
                    ),
                  ),
                );
              } else if (result == 'delete') {
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: Text('Are you sure you want to delete "${task.title}"?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          tasksProvider.deleteTask(task.id);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task "${task.title}" deleted'))
                          );
                        },
                      ),
                    ],
                  ),
                );
              } else if (result == 'log_time') {
                _showLogTimeDialog(context, task);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'log_time',
                child: ListTile(leading: Icon(Icons.timer), title: Text('Log Time')),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
              ),
            ],
          ),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    )
    .animate()
    .fadeIn(duration: const Duration(milliseconds: 400), delay: fadeInDelay)
    .slideX(begin: 0.2, duration: const Duration(milliseconds: 400), delay: slideDelay, curve: Curves.easeOutCubic);
  }

  void _toggleTaskCompletion(Task task) async {
    try {
      // Vibrate when task is toggled
      // Use a very short duration for sharper feedback
      await Vibration.vibrate(duration: 20); 
      
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      await tasksProvider.toggleTaskComplete(task.id);
    } catch (e) {
      print("Error toggling task completion: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating task')),
        );
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final tasksProvider = Provider.of<TasksProvider>(context);
    final allTasks = tasksProvider.tasks;

    // 1. Apply base filter (from widget parameter)
    List<Task> baseFilteredTasks = _applyBaseFilter(context, allTasks);

    // 2. Apply state filters (Completion, Course)
    List<Task> locallyFilteredTasks = baseFilteredTasks.where((task) {
      // Completion Filter
      bool completionMatch = true;
      switch (_completionFilter) {
        case CompletionFilter.complete:
          completionMatch = task.isComplete;
          break;
        case CompletionFilter.incomplete:
          completionMatch = !task.isComplete;
          break;
        case CompletionFilter.all:
        default:
          completionMatch = true;
          break;
      }

      // Course Filter
      bool courseMatch = true;
      if (_courseFilterId != null) {
        courseMatch = task.courseId == _courseFilterId;
      }

      return completionMatch && courseMatch;
    }).toList();

    // 3. Apply state sorting
    List<Task> sortedAndFilteredTasks = _applySort(locallyFilteredTasks);

    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    // Determine AppBar Title based on base filter if not provided by widget
    final String currentAppBarTitle = widget.appBarTitle ?? _getTitleFromFilter(widget.filter);

    // Build dynamic title based on filters/sorts? Maybe too complex.
    // String subtitleInfo = _buildFilterSortSubtitle(); // Example

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAppBarTitle),
        backgroundColor: surfaceColor.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // --- Add Button (only if not a filtered view) ---
          if (!_isBaseFilteredView)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Add Task",
              onPressed: _navigateToAddTask,
            ),
          // --- Filter Button ---
          PopupMenuButton<dynamic>( // Use dynamic for mixed types
            icon: const Icon(Icons.filter_list),
            tooltip: "Filter Tasks",
            onSelected: (value) {
              setState(() {
                if (value is CompletionFilter) {
                  _completionFilter = value;
                  _courseFilterId = null; // Reset course filter when changing completion
                } else if (value is String) { // Course ID or 'all'
                  _courseFilterId = (value == 'all') ? null : value;
                   _completionFilter = CompletionFilter.all; // Reset completion when choosing course
                }
              });
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<dynamic>> items = [];

              items.add(const PopupMenuItem(
                enabled: false, // Not selectable
                child: Text("By Status", style: TextStyle(fontWeight: FontWeight.bold)),
              ));
              items.addAll(CompletionFilter.values.map((filter) {
                return CheckedPopupMenuItem<CompletionFilter>(
                  value: filter,
                  checked: _completionFilter == filter && _courseFilterId == null, // Checked only if status filter active
                  child: Text(filter.toString().split('.').last.capitalize()), // Simple names
                );
              }).toList());

              if (widget.courses.isNotEmpty) {
                 items.add(const PopupMenuDivider());
                 items.add(const PopupMenuItem(
                   enabled: false, // Not selectable
                   child: Text("By Course", style: TextStyle(fontWeight: FontWeight.bold)),
                 ));
                 // 'All Courses' option
                 items.add(CheckedPopupMenuItem<String>(
                   value: 'all',
                   checked: _courseFilterId == null,
                   child: const Text("All Courses"),
                 ));
                 // Individual course options
                 items.addAll(widget.courses.map((course) {
                   return CheckedPopupMenuItem<String>(
                     value: course.id,
                     checked: _courseFilterId == course.id,
                     child: Text(course.name),
                   );
                 }).toList());
              }

              return items;
            },
          ),
          // --- Sort Button ---
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: "Sort Tasks",
            onSelected: (SortOption result) {
              setState(() {
                _sortBy = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              CheckedPopupMenuItem<SortOption>(
                value: SortOption.dueDateAsc,
                checked: _sortBy == SortOption.dueDateAsc,
                child: const Text('Sort by Due Date (Earliest First)'),
              ),
              CheckedPopupMenuItem<SortOption>(
                value: SortOption.dueDateDesc,
                checked: _sortBy == SortOption.dueDateDesc,
                child: const Text('Sort by Due Date (Latest First)'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem<SortOption>(
                value: SortOption.titleAsc,
                checked: _sortBy == SortOption.titleAsc,
                child: const Text('Sort by Title (A-Z)'),
              ),
              CheckedPopupMenuItem<SortOption>(
                value: SortOption.titleDesc,
                checked: _sortBy == SortOption.titleDesc,
                child: const Text('Sort by Title (Z-A)'),
              ),
               const PopupMenuDivider(),
               CheckedPopupMenuItem<SortOption>(
                value: SortOption.courseAsc,
                checked: _sortBy == SortOption.courseAsc,
                child: const Text('Sort by Course (A-Z)'),
              ),
              CheckedPopupMenuItem<SortOption>(
                value: SortOption.courseDesc,
                checked: _sortBy == SortOption.courseDesc,
                child: const Text('Sort by Course (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
           // --- Display active filters ---
           if (_completionFilter != CompletionFilter.all || _courseFilterId != null)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
               child: Wrap(
                 spacing: 8.0,
                 runSpacing: 4.0,
                 children: [
                   if (_completionFilter != CompletionFilter.all)
                     Chip(
                       label: Text('Status: ${_completionFilter.toString().split('.').last.capitalize()}'),
                       onDeleted: () => setState(() => _completionFilter = CompletionFilter.all),
                       visualDensity: VisualDensity.compact,
                       padding: EdgeInsets.zero,
                     ),
                   if (_courseFilterId != null)
                     Chip(
                       label: Text('Course: ${_getCourseName(_courseFilterId) ?? "Unknown"}'),
                       onDeleted: () => setState(() => _courseFilterId = null),
                       visualDensity: VisualDensity.compact,
                       padding: EdgeInsets.zero,
                     ),
                 ],
               ),
             ),
           // --- End active filters display ---

          Expanded(
            child: Builder(
              builder: (context) {
                if (sortedAndFilteredTasks.isEmpty) {
                  return Center(
                    child: Text(
                      'No tasks match the current filters.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  itemCount: sortedAndFilteredTasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final taskFromSortedList = sortedAndFilteredTasks[index];
                    // Still fetch the definitive task state from the provider using the ID
                    // This ensures updates (like completion toggle) are reflected immediately
                    // even if the list hasn't fully rebuilt yet.
                     Task task = allTasks.firstWhere((t) => t.id == taskFromSortedList.id, orElse: () => taskFromSortedList);

                    final courseName = _getCourseName(task.courseId);

                    List<String> subtitleParts = [];
                    if (courseName != null) {
                      subtitleParts.add(courseName);
                    }
                    if (task.dueDate != null) {
                       final formattedDate = DateFormat.yMd().format(task.dueDate!);
                       final now = DateUtils.dateOnly(DateTime.now());
                       final dueDateOnly = DateUtils.dateOnly(task.dueDate!);
                       String dateLabel = 'Due: $formattedDate';
                       if (dueDateOnly.isBefore(now) && !task.isComplete) {
                          dateLabel += ' (Overdue)';
                       } else if (isSameDay(dueDateOnly, now)) {
                          dateLabel += ' (Today)';
                       }
                       subtitleParts.add(dateLabel);
                    }

                    String gradeString = '';
                    if (task.pointsEarned != null && task.pointsPossible != null) {
                       final earnedStr = task.pointsEarned!.toStringAsFixed(task.pointsEarned! % 1 == 0 ? 0 : 1);
                       final possibleStr = task.pointsPossible!.toStringAsFixed(task.pointsPossible! % 1 == 0 ? 0 : 1);
                       gradeString = 'Grade: $earnedStr/$possibleStr';
                       subtitleParts.add(gradeString);
                    } else if (task.pointsEarned != null) {
                       final earnedStr = task.pointsEarned!.toStringAsFixed(task.pointsEarned! % 1 == 0 ? 0 : 1);
                       gradeString = 'Grade: $earnedStr';
                       subtitleParts.add(gradeString);
                    }

                    final totalTime = task.totalTimeSpent;
                    String timeSpentString = '';
                    if (totalTime > Duration.zero) {
                      final hours = totalTime.inHours;
                      final minutes = totalTime.inMinutes.remainder(60);
                      timeSpentString = 'Logged: ${hours}h ${minutes}m';
                       subtitleParts.add(timeSpentString);
                    }

                    String subtitle = subtitleParts.join('  •  ');

                    Color? tileColor = task.isComplete
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                      : null;
                     if (task.dueDate != null && task.dueDate!.isBefore(DateUtils.dateOnly(DateTime.now())) && !task.isComplete) {
                        tileColor = Theme.of(context).colorScheme.errorContainer.withOpacity(0.3);
                     }

                    return _buildAnimatedTaskItem(context, task, subtitle, tileColor, index);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}


// Helper extension for String capitalization
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
} 