import 'package:flutter/material.dart';
import '../models/task.dart';
import 'dart:math';

/// Service for calculating task priority scores and providing prioritization logic.
class PrioritizationService {
  /// Calculates a priority score for a task based on importance and due date.
  /// Higher score = higher priority.
  static double calculatePriorityScore(Task task) {
    double score = 0;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    // --- Importance Component ---
    // Default to medium (2) if not set
    int importanceValue = task.importance ?? 2; // 1=Low, 2=Medium, 3=High
    score += importanceValue * 10; // Weight importance (e.g., High = 30 points)

    // --- Urgency Component ---
    if (task.dueDate != null) {
      final dueDateOnly = DateUtils.dateOnly(task.dueDate!);
      int daysUntilDue = dueDateOnly.difference(today).inDays;

      if (daysUntilDue < 0) { // Overdue
        score += 100; // Big boost for overdue
        score += (daysUntilDue * -1); // More overdue = slightly higher score
      } else if (daysUntilDue == 0) { // Due Today
        score += 50; // Significant boost for today
      } else if (daysUntilDue <= 7) { // Due within a week
        score += (7 - daysUntilDue) * 5; // Closer = higher score (max 35 points)
      } else {
        // Due further out - lower score based on distance
        score += max(0, 5 - (daysUntilDue / 7).floor()); // Small score for distant tasks
      }
    } else {
      // No due date - lower base priority unless explicitly marked important
      score -= 5; // Penalize tasks without due dates slightly
    }

    // --- Completion Status Component ---
    // Completed tasks get lower priority
    if (task.isComplete) {
      score -= 50; // Significant reduction for completed tasks
    }

    // Ensure score isn't negative
    return max(0, score);
  }

  /// Sorts a list of tasks by priority (highest priority first).
  static List<Task> sortByPriority(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) {
      double scoreA = calculatePriorityScore(a);
      double scoreB = calculatePriorityScore(b);
      return scoreB.compareTo(scoreA); // Higher score first
    });
    return sortedTasks;
  }

  /// Gets a priority level description based on the score.
  static String getPriorityLevelDescription(double score) {
    if (score >= 100) return 'Critical';
    if (score >= 50) return 'High';
    if (score >= 30) return 'Medium';
    return 'Low';
  }
}
