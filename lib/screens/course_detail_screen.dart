import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/schedule_entry.dart'; // Needed for formatting
import '../models/task.dart';
import '../providers/tasks_provider.dart';
import 'add_course_screen.dart'; // To navigate for editing

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  final Function(Course) onEditCourse; // Callback to trigger editing

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.onEditCourse,
  });

   // Helper to build info rows (Icon, Label, Value)
   Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
     final textTheme = Theme.of(context).textTheme;
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start, // Align top for long values
         children: [
           Padding(
             padding: const EdgeInsets.only(top: 2.0), // Adjust icon alignment
             child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
           ),
           const SizedBox(width: 16),
           Text(label, style: textTheme.bodyLarge),
           const SizedBox(width: 16),
           // Use Flexible/Expanded for value to allow wrapping
           Expanded(
             child: Text(
               value.isEmpty ? '-' : value,
               style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyMedium?.color),
               textAlign: TextAlign.end,
             ),
           ),
         ],
       ),
     );
   }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Format schedule
    final scheduleString = course.schedule.isEmpty
      ? 'Not Scheduled'
      : course.schedule.map((e) => e.format(context)).join('\n'); // Join with newline for vertical list

    // Format grade
    String gradeString = 'Not Set';
    if (course.manualGradePercent != null) {
      gradeString = '${NumberFormat("0.0").format(course.manualGradePercent! * 100)}% (Manual)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        backgroundColor: course.colorValue.withOpacity(0.1), // Use course color in AppBar
        foregroundColor: course.colorValue, // Tint AppBar icons/text
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Course',
            onPressed: () {
              onEditCourse(course);
              // Optionally pop this screen if edit screen replaces it
              // Navigator.of(context).pop(); 
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
           Card(
             elevation: 0.5,
             margin: EdgeInsets.zero,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             color: course.colorValue.withOpacity(0.05),
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: course.colorValue)),
                   const SizedBox(height: 16),
                   _buildInfoRow(context, Icons.person_outline, 'Professor', course.professor ?? '-'),
                   _buildInfoRow(context, Icons.room_outlined, 'Room', course.room ?? '-'),
                   _buildInfoRow(context, Icons.grade_outlined, 'Grade', gradeString),
                   const Divider(height: 24),
                   _buildInfoRow(context, Icons.schedule_outlined, 'Schedule', scheduleString),
                    const Divider(height: 24),
                   _buildInfoRow(context, Icons.link_outlined, 'Materials', course.materialsLink ?? '-'),
                   _buildInfoRow(context, Icons.notes_outlined, 'Notes', course.notesLink ?? '-'),
                 ],
               ),
             ),
           ),
           // Tasks section
           Card(
             elevation: 0.5,
             margin: const EdgeInsets.only(top: 16.0),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             color: course.colorValue.withOpacity(0.05),
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     'Tasks & Assignments',
                     style: textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: course.colorValue,
                     ),
                   ),
                   const SizedBox(height: 16),
                   _buildTasksList(context),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, tasksProvider, child) {
        if (tasksProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter tasks for this course and sort by due date
        final courseTasks = tasksProvider.tasks
            .where((task) => task.courseId == course.id)
            .toList()
          ..sort((a, b) {
            // Sort by completion status first (incomplete first)
            if (a.isComplete != b.isComplete) {
              return a.isComplete ? 1 : -1;
            }
            // Then sort by due date
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

        if (courseTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No tasks or assignments yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courseTasks.length,
          itemBuilder: (context, index) {
            final task = courseTasks[index];
            return _buildTaskItem(context, task);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Format due date
    final dueDateStr = task.dueDate != null
        ? DateFormat('MMM d, y').format(task.dueDate!)
        : 'No due date';

    // Determine importance color
    Color importanceColor;
    switch (task.importance) {
      case 3:
        importanceColor = Colors.red;
        break;
      case 2:
        importanceColor = Colors.orange;
        break;
      case 1:
        importanceColor = Colors.blue;
        break;
      default:
        importanceColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: importanceColor,
              ),
            ),
            Expanded(
              child: Text(
                task.title,
                style: textTheme.titleMedium?.copyWith(
                  decoration: task.isComplete ? TextDecoration.lineThrough : null,
                  color: task.isComplete
                      ? textTheme.bodyMedium?.color?.withOpacity(0.7)
                      : textTheme.titleMedium?.color,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            dueDateStr,
            style: textTheme.bodyMedium?.copyWith(
              color: task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.isComplete
                  ? Colors.red
                  : textTheme.bodyMedium?.color,
            ),
          ),
        ),
        trailing: task.isComplete
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : Icon(
                Icons.circle_outlined,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
      ),
    );
  }
}
