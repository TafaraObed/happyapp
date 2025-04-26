import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/course.dart';
import 'package:intl/intl.dart'; // For formatting
import 'package:collection/collection.dart'; // For groupBy

class StatsScreen extends StatelessWidget {
  final List<Task> tasks;
  final List<Course> courses;

  const StatsScreen({super.key, required this.tasks, required this.courses});

  // Helper to get course name from ID
  String _getCourseName(String? courseId) {
    if (courseId == null) return 'General Tasks'; // Or handle differently
    try {
      return courses.firstWhere((c) => c.id == courseId).name;
    } catch (e) {
      return 'Unknown Course'; // Course might have been deleted
    }
  }

  // --- Calculation Logic ---

  // Calculate overall task completion rate
  double _calculateCompletionRate() {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.isComplete).length;
    return completedTasks / tasks.length;
  }

  // Calculate total time logged across all tasks
  Duration _calculateTotalTimeLogged() {
    return tasks.fold(Duration.zero, (sum, task) => sum + task.totalTimeSpent);
  }

  // Calculate grade averages per course, returning both calculated and manual grades.
  // The map value is a tuple: (calculated_average?, manual_grade?).
  Map<String?, ({double? calculated, double? manual})> _calculateCourseGradeAverages() {
    // Find manual grades first
    final manualGrades = { for (var c in courses) c.id : c.manualGradePercent };
    // Add entry for general tasks if any course has null manual grade (though unlikely)
    if (!manualGrades.containsKey(null) && courses.any((c) => c.manualGradePercent == null)) {
      // This logic might need refinement if general tasks can have manual grades somehow
    }

    // Group tasks by course ID (null course ID represents general tasks)
    final tasksByCourse = groupBy(tasks, (Task task) => task.courseId);
    final Map<String?, ({double? calculated, double? manual})> averages = {};

    // Ensure all courses (and general tasks if present) are in the map
    final allCourseIds = <String?>{...courses.map((c) => c.id), ...tasksByCourse.keys};

    for (final courseId in allCourseIds) {
      final courseTasks = tasksByCourse[courseId] ?? []; // Get tasks for this course ID
      double totalPointsEarned = 0;
      double totalPointsPossible = 0;
      int gradedTasksCount = 0;
      double? calculatedAverage;

      for (final task in courseTasks) {
        // Only include tasks where both pointsEarned and pointsPossible are set
        if (task.pointsEarned != null && task.pointsPossible != null && task.pointsPossible! > 0) {
          totalPointsEarned += task.pointsEarned!;
          totalPointsPossible += task.pointsPossible!;
          gradedTasksCount++;
        }
      }

      if (gradedTasksCount > 0 && totalPointsPossible > 0) {
        calculatedAverage = (totalPointsEarned / totalPointsPossible);
      } else {
        calculatedAverage = null; // No graded tasks or zero possible points
      }

      // Get the manual grade for this course ID
      final manualGrade = manualGrades[courseId];

      averages[courseId] = (calculated: calculatedAverage, manual: manualGrade);
    }

    return averages;
  }

  // --- End Calculation Logic ---

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    final completionRate = _calculateCompletionRate();
    final totalTimeLogged = _calculateTotalTimeLogged();
    final courseAverages = _calculateCourseGradeAverages(); // Calculate averages

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Format total time logged
    final hours = totalTimeLogged.inHours;
    final minutes = totalTimeLogged.inMinutes.remainder(60);
    final timeString = '${hours}h ${minutes}m';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.90),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Overall Stats Card ---
          Card(
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
             elevation: 2, // Subtle elevation
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Summary', style: textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completion Rate:', style: textTheme.bodyLarge),
                      Text(
                        NumberFormat.percentPattern().format(completionRate),
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tasks:', style: textTheme.bodyLarge),
                      Text(
                        tasks.length.toString(),
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Time Logged:', style: textTheme.bodyLarge),
                      Text(
                        timeString,
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Course Grade Averages Card ---
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Course Grade Averages', style: textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (courseAverages.isEmpty)
                    const Center(child: Text('No courses or graded tasks found.'))
                  else
                    // Build list of averages
                    ListView.separated(
                      shrinkWrap: true, // Important inside another ListView
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                      itemCount: courseAverages.length,
                      itemBuilder: (context, index) {
                        final courseId = courseAverages.keys.elementAt(index);
                        final gradeData = courseAverages[courseId]!;
                        final calculatedAverage = gradeData.calculated;
                        final manualGrade = gradeData.manual;
                        final courseName = _getCourseName(courseId);

                        // Determine which grade to display and the text
                        String gradeText;
                        bool isManual = false;
                        double? displayValue;

                        if (manualGrade != null) {
                          displayValue = manualGrade;
                          gradeText = '${NumberFormat("0.0%").format(manualGrade)} (Manual)';
                          isManual = true;
                        } else if (calculatedAverage != null) {
                          displayValue = calculatedAverage;
                          gradeText = NumberFormat("0.0%").format(calculatedAverage);
                        } else {
                          gradeText = 'N/A';
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero, // Remove default padding
                          title: Text(courseName, style: textTheme.bodyLarge),
                          trailing: Text(
                            gradeText, // Use the determined text
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              // Grey out N/A, maybe slightly different style for manual?
                              color: displayValue == null ? Colors.grey : null,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1),
                    ),
                ],
              ),
            ),
          ),
          // Add more stats cards later (e.g., time per course)
        ],
      ),
    );
  }
} 