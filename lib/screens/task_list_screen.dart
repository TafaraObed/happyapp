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

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks;
  final List<Course> courses; // Needed to display course names
  final Function(String) onToggleTaskComplete;
  final VoidCallback onAddTask; // Add callback for Add Task
  final Function(Task) onEditTask; // Add callback for Edit
  final Function(String) onDeleteTask; // Add callback for Delete
  // Add callback for logging time
  final Function(String taskId, Duration duration) onLogTime; 

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.courses,
    required this.onToggleTaskComplete,
    required this.onAddTask, // Make required
    required this.onEditTask, // Make required
    required this.onDeleteTask, // Make required
    required this.onLogTime, // Make callback required
  });

  // Helper to find course name from courseId
  String? _getCourseName(String? courseId) {
    if (courseId == null) return null;
    try {
      return courses.firstWhere((course) => course.id == courseId).name;
    } catch (e) {
      return null; // Course not found
    }
  }

  // --- Dialog for Logging Time ---
  Future<void> _showLogTimeDialog(BuildContext context, Task task) async {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
      // Call the callback passed from MainScreen
      onLogTime(task.id, loggedDuration);
    }
    // Dispose controllers after use
     hoursController.dispose();
     minutesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optional: Group tasks (e.g., by due date or course)
    // For now, just show a flat list sorted by due date (nulls last)
    List<Task> sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1; // Nulls last
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: surfaceColor.withOpacity(0.90), // Use opacity
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Prevent tinting
      ),
      body: Stack( // Use Stack to overlay empty state text
        children: [
          // Task List
          ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
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
                      courses: courses, // Pass courses for lookup
                      onEditTask: onEditTask, // Pass the edit callback
                    ),
                  ));
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                      onToggleTaskComplete(task.id);
                    },
                    controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                    secondary: PopupMenuButton<String>( // Keep PopupMenu for edit/delete/log time
                       icon: const Icon(Icons.more_vert),
                       onSelected: (value) {
                         if (value == 'edit') {
                            onEditTask(task);
                         } else if (value == 'delete') {
                            onDeleteTask(task.id);
                         } else if (value == 'log_time') { // Handle log time
                            _showLogTimeDialog(context, task);
                         }
                       },
                       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                             value: 'log_time',
                             child: ListTile(leading: Icon(Icons.timer_outlined), title: Text('Log Time')),
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
                  ),
                )
                 .animate()
                 .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                 .slideX(begin: 0.2, duration: 400.ms, delay: (100 * index).ms, curve: Curves.easeOutCubic),
              );
            },
          ),
          // Animated Opacity and IgnorePointer for Empty State Text
          IgnorePointer(
            ignoring: tasks.isNotEmpty,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: tasks.isEmpty ? 1.0 : 0.0,
              child: const Center(child: Text('No tasks added yet!')),
            ),
          ),
        ],
      ),
       // Add FloatingActionButton for adding tasks
       floatingActionButton: FloatingActionButton(
         onPressed: onAddTask,
         tooltip: 'Add Task',
         child: const Icon(Icons.add),
       ).animate().scale(delay: 500.ms),
    );
  }
} 