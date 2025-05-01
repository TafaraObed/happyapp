import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For CupertinoPageRoute if needed
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/course.dart';
import 'add_task_screen.dart'; // To navigate for editing
import '../services/prioritization_service.dart'; // For priority score calculation

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final List<Course> courses;
  final Function(Task) onEditTask; // Callback to trigger editing

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.courses,
    required this.onEditTask,
  });

  // Helper to find course name
  String? _getCourseName(String? courseId) {
    if (courseId == null) return null;
    try {
      return courses.firstWhere((course) => course.id == courseId).name;
    } catch (e) {
      return 'Unknown Course'; // Handle cases where course might be deleted
    }
  }

  // Helper to format duration
  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'Not Logged';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Helper to get importance text and icon
  String _getImportanceText(int? importance) {
    switch (importance) {
      case 1:
        return 'Low';
      case 3:
        return 'High';
      case 2:
      default:
        return 'Medium';
    }
  }

  IconData _getImportanceIcon(int? importance) {
    switch (importance) {
      case 1:
        return Icons.arrow_downward;
      case 3:
        return Icons.arrow_upward;
      case 2:
      default:
        return Icons.remove;
    }
  }

  // Helper to build info rows (Icon, Label, Value)
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
     final textTheme = Theme.of(context).textTheme;
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       child: Row(
         children: [
           Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
           const SizedBox(width: 16),
           Expanded(child: Text(label, style: textTheme.bodyLarge)),
           Text(value, style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyMedium?.color)),
         ],
       ),
     );
   }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final courseName = _getCourseName(task.courseId);

    String gradeString = 'Not Graded';
    if (task.pointsEarned != null && task.pointsPossible != null) {
       final earnedStr = task.pointsEarned!.toStringAsFixed(task.pointsEarned! % 1 == 0 ? 0 : 1);
       final possibleStr = task.pointsPossible!.toStringAsFixed(task.pointsPossible! % 1 == 0 ? 0 : 1);
       gradeString = '$earnedStr / $possibleStr';
    } else if (task.pointsEarned != null) {
       final earnedStr = task.pointsEarned!.toStringAsFixed(task.pointsEarned! % 1 == 0 ? 0 : 1);
       gradeString = '$earnedStr (Points Earned)';
    }

    // Calculate priority score for display
    final priorityScore = PrioritizationService.calculatePriorityScore(task);
    final priorityLevel = PrioritizationService.getPriorityLevelDescription(priorityScore);

    return Scaffold(
      appBar: AppBar(
        title: Text(task.title),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined), // Use outlined icon for edit
            tooltip: 'Edit Task',
            onPressed: () {
              // Call the onEditTask callback, which should handle navigation
              // to AddTaskScreen in edit mode.
              onEditTask(task);
              // Optionally pop this screen if edit screen replaces it in navigation stack
              // Navigator.of(context).pop(); 
            },
          ),
        ],
      ),
      body: ListView( // Use ListView for potential scrolling
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
             elevation: 0.5, // Lower elevation
             margin: EdgeInsets.zero, // Remove margin for tighter look
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   if (courseName != null)
                     _buildInfoRow(context, Icons.book_outlined, 'Course', courseName),
                   if (task.dueDate != null)
                     _buildInfoRow(context, Icons.calendar_today_outlined, 'Due Date', DateFormat.yMMMEd().format(task.dueDate!)),
                   _buildInfoRow(context, Icons.check_circle_outline, 'Status', task.isComplete ? 'Complete' : 'Incomplete'),
                   _buildInfoRow(context, _getImportanceIcon(task.importance), 'Importance', _getImportanceText(task.importance)),
                   _buildInfoRow(context, Icons.priority_high, 'Priority', '$priorityLevel (Score: ${priorityScore.toStringAsFixed(0)})'),
                   const Divider(height: 24),
                   _buildInfoRow(context, Icons.grade_outlined, 'Grade', gradeString),
                   _buildInfoRow(context, Icons.timer_outlined, 'Time Logged', _formatDuration(task.totalTimeSpent)),
                   
                   // Optional: Add Description if available
                   // if (task.description != null && task.description!.isNotEmpty) ...
                 ],
               ),
             ),
           ),
           // Add other sections if needed, e.g., Time Log History
        ],
      ),
    );
  }
}
