import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../models/task.dart';
import '../models/course.dart'; // To look up course names
import '../widgets/tap_scale_container.dart'; // Import the new widget

class TaskListScreen extends StatelessWidget {
  final List<Task> tasks;
  final List<Course> courses; // Needed to display course names
  final Function(String) onToggleTaskComplete;
  final VoidCallback onAddTask; // Add callback for Add Task
  final Function(Task) onEditTask; // Add callback for Edit
  final Function(String) onDeleteTask; // Add callback for Delete

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.courses,
    required this.onToggleTaskComplete,
    required this.onAddTask, // Make required
    required this.onEditTask, // Make required
    required this.onDeleteTask, // Make required
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
              String subtitle = '';
              if (courseName != null) {
                subtitle += courseName;
              }
              if (task.dueDate != null) {
                subtitle += (subtitle.isNotEmpty ? ' - ' : '');
                subtitle += 'Due: ${DateFormat.yMd().format(task.dueDate!)}'; // Format date
              }

              // Wrap the animated Card with TapScaleContainer
              return TapScaleContainer(
                onTap: () => onToggleTaskComplete(task.id), // Trigger toggle on tap
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  // Add shape with increased radius for M3 style
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  // Use InkWell for ripple effect if CheckboxListTile doesn't provide one
                  // for the entire area, but CheckboxListTile is usually sufficient.
                  child: CheckboxListTile(
                    title: Text(
                      task.title,
                      style: task.isComplete 
                        ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
                        : null,
                     ),
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                    value: task.isComplete,
                    onChanged: (bool? value) {
                      // onToggleTaskComplete is now handled by TapScaleContainer's onTap
                      // This onChanged is only for the checkbox itself, visually.
                      // Let TapScaleContainer handle the state change logic.
                      // OR: Keep logic here and remove onTap from TapScaleContainer?
                      // Let's keep it simple: Tap anywhere triggers toggle.
                      // Keep onChanged for accessibility/direct checkbox tap.
                      onToggleTaskComplete(task.id);
                    },
                    controlAffinity: ListTileControlAffinity.leading, // Checkbox on left
                    secondary: PopupMenuButton<String>( // Keep PopupMenu for edit/delete
                       icon: const Icon(Icons.more_vert),
                       onSelected: (value) {
                         if (value == 'edit') {
                            onEditTask(task);
                         } else if (value == 'delete') {
                            onDeleteTask(task.id);
                         }
                       },
                       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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