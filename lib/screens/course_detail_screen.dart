import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/schedule_entry.dart'; // Needed for formatting
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
             elevation: 1.5,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             color: course.colorValue.withOpacity(0.05), // Subtle background color
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
           // TODO: Add section to display associated tasks?
        ],
      ),
    );
  }
} 