import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/course.dart';
import 'package:intl/intl.dart'; // For formatting
import 'package:collection/collection.dart'; // For groupBy
import 'package:provider/provider.dart'; // <<< Add provider import
import '../providers/tasks_provider.dart'; // <<< Add tasks provider import
import '../models/schedule_entry.dart'; // <<< Import DayOfWeek

class StatsScreen extends StatelessWidget {
  // final List<Task> tasks; // <<< Remove tasks parameter
  final List<Course> courses;

  const StatsScreen({super.key, /* required this.tasks,*/ required this.courses}); // <<< Remove required

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
  double _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.isComplete).length;
    return completedTasks / tasks.length;
  }

  // Calculate total time logged across all tasks
  Duration _calculateTotalTimeLogged(List<Task> tasks) {
    return tasks.fold(Duration.zero, (sum, task) => sum + task.totalTimeSpent);
  }

  // Calculate grade averages per course
  Map<String, Tuple<double?, double?>> _calculateGradeAverages(List<Task> tasks) {
    final manualGrades = { for (var c in courses) c.id : c.manualGradePercent };
    final tasksByCourse = groupBy(tasks, (Task task) => task.courseId);
    final Map<String, Tuple<double?, double?>> averages = {};

    // Include all courses, even if they have no tasks
    final allCourseIds = <String>{...courses.map((c) => c.id)}; // Start with all course IDs
    allCourseIds.addAll(tasksByCourse.keys.whereType<String>()); // Add keys from tasks (excluding null)

    for (final courseId in allCourseIds) {
      final courseTasks = tasksByCourse[courseId] ?? [];
      double? calculatedAverage;
      // Calculate average only if there are graded tasks
      final gradedTasks = courseTasks.where((t) => t.pointsPossible != null && t.pointsPossible! > 0 && t.pointsEarned != null).toList();
      if (gradedTasks.isNotEmpty) {
         double totalPointsEarned = gradedTasks.fold(0, (sum, t) => sum + t.pointsEarned!);
         double totalPointsPossible = gradedTasks.fold(0, (sum, t) => sum + t.pointsPossible!);
         calculatedAverage = (totalPointsPossible > 0) ? totalPointsEarned / totalPointsPossible : null;
      }
      final manualGrade = manualGrades[courseId];
      averages[courseId] = Tuple(calculatedAverage, manualGrade);
    }
    // Optionally handle general tasks (courseId == null) separately if needed
    // final generalTasks = tasksByCourse[null] ?? []; ...

    return averages;
  }

  // Calculate total time logged per day of the week
  Map<DayOfWeek, Duration> _calculateTimeLoggedPerDay(List<Task> tasks) {
    final Map<DayOfWeek, Duration> timePerDay = {};
    for (final task in tasks) {
      for (final log in task.timeLog) {
         final day = DayOfWeek.values[log.startTime.weekday - 1]; // Monday is 1 -> index 0
         timePerDay[day] = (timePerDay[day] ?? Duration.zero) + log.duration;
      }
    }
     // Ensure all days are present in the map, even if zero
     for (final day in DayOfWeek.values) {
        timePerDay.putIfAbsent(day, () => Duration.zero);
     }
    return timePerDay;
  }

  // --- End Calculation Logic ---

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get tasks from Provider
    final tasks = Provider.of<TasksProvider>(context).tasks;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Call calculation methods with the tasks list from provider
    final completionRate = _calculateCompletionRate(tasks);
    final totalTimeLogged = _calculateTotalTimeLogged(tasks);
    final timePerDay = _calculateTimeLoggedPerDay(tasks);
    final gradeAverages = _calculateGradeAverages(tasks);

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
                  if (gradeAverages.isEmpty)
                    const Center(child: Text('No courses or graded tasks found.'))
                  else
                    // Build list of averages
                    ListView.separated(
                      shrinkWrap: true, // Important inside another ListView
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
                      itemCount: gradeAverages.length,
                      itemBuilder: (context, index) {
                        final courseId = gradeAverages.keys.elementAt(index);
                        final gradeData = gradeAverages[courseId]!;
                        final calculatedAverage = gradeData.item1;
                        final manualGrade = gradeData.item2;
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

// Helper Tuple class (keep as is)
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple(this.item1, this.item2);
} 