import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/cupertino.dart'; // Import for CupertinoPageRoute
import '../models/course.dart';
import '../widgets/tap_scale_container.dart';
import 'package:intl/intl.dart';
import 'course_detail_screen.dart'; // Import the new detail screen
import 'package:vibration/vibration.dart';  // Add vibration import

// Changed to StatelessWidget and accepts data/callbacks
class CourseListScreen extends StatelessWidget {
  final List<Course> courses;
  final VoidCallback onAdd;
  final Function(Course) onEdit;
  final Function(String) onDelete;

  const CourseListScreen({
    super.key,
    required this.courses,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  void _onCourseTap(BuildContext context, Course course) async {
    // Vibrate when course is tapped
    // Use a very short duration for sharper feedback
    await Vibration.vibrate(duration: 20); 
    
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => CourseDetailScreen(
          course: course,
          onEditCourse: onEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get surface color for transparent AppBar
    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        // Make AppBar slightly transparent
        backgroundColor: surfaceColor.withOpacity(0.90),
        elevation: 0,
        // Consider adding surfaceTintColor: Colors.transparent if needed 
        // to prevent M3 tinting when scrolling behind
        surfaceTintColor: Colors.transparent, 
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final scheduleString = course.schedule
                  .map((entry) => entry.format(context))
                  .join(', ');

              // Build subtitle string
              List<String> subtitleParts = [scheduleString];
              if (course.manualGradePercent != null) {
                final gradeString = NumberFormat("0.0%").format(course.manualGradePercent!);
                subtitleParts.add('Grade: $gradeString (Manual)');
              }
              final subtitle = subtitleParts.join('  •  ');

              return TapScaleContainer(
                onTap: () => _onCourseTap(context, course),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: course.colorValue, radius: 15),
                    title: Text(course.name),
                    subtitle: Text(subtitle),
                    trailing: Builder(
                      builder: (BuildContext context) {
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit(course);
                            } else if (value == 'delete') {
                              onDelete(course.id);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))
                        ),
                          ],
                        );
                      },
                    ),
                  ),
                )
                 .animate()
                 .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                 .slideX(begin: 0.2, duration: 400.ms, delay: (100 * index).ms, curve: Curves.easeOutCubic),
              );
            },
          ),
          IgnorePointer(
            ignoring: courses.isNotEmpty,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: courses.isEmpty ? 1.0 : 0.0,
              child: const Center(child: Text('No courses added yet. Tap + to add one!')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms),
    );
  }
}
