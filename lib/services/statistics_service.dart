import 'package:check_bird/models/statistics/productivity_stats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Service for tracking and calculating productivity statistics
class StatisticsService {
  static final StatisticsService _instance = StatisticsService._();
  factory StatisticsService() => _instance;
  StatisticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _statsRef =>
      _firestore.collection('productivityStats');
  CollectionReference get _completionRecordsRef =>
      _firestore.collection('taskCompletions');

  /// Get user's productivity stats
  Future<ProductivityStats> getUserStats(String userId) async {
    try {
      final doc = await _statsRef.doc(userId).get();
      if (doc.exists) {
        return ProductivityStats.fromFirestore(doc);
      }
      // Initialize new stats
      final initial = ProductivityStats(userId: userId);
      await _statsRef.doc(userId).set(initial.toFirestore());
      return initial;
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return ProductivityStats(userId: userId);
    }
  }

  /// Stream user's productivity stats for real-time updates
  Stream<ProductivityStats> getUserStatsStream(String userId) {
    return _statsRef.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return ProductivityStats.fromFirestore(doc);
      }
      return ProductivityStats(userId: userId);
    });
  }

  /// Update stats after task completion
  Future<void> recordTaskCompletion({
    required String userId,
    required bool isHabit,
    required int coinsEarned,
    required int xpEarned,
  }) async {
    try {
      final now = DateTime.now();
      final dayOfWeek = DateFormat('EEEE').format(now);
      final hour = now.hour.toString().padLeft(2, '0');
      final weekKey = _getWeekKey(now);
      final monthKey = DateFormat('yyyy-MM').format(now);

      await _firestore.runTransaction((transaction) async {
        final docRef = _statsRef.doc(userId);
        final doc = await transaction.get(docRef);

        ProductivityStats stats;
        if (doc.exists) {
          stats = ProductivityStats.fromFirestore(doc);
        } else {
          stats = ProductivityStats(userId: userId);
        }

        // Update counters
        final newTasksByDay = Map<String, int>.from(stats.tasksByDayOfWeek);
        newTasksByDay[dayOfWeek] = (newTasksByDay[dayOfWeek] ?? 0) + 1;

        final newTasksByHour = Map<String, int>.from(stats.tasksByHour);
        newTasksByHour[hour] = (newTasksByHour[hour] ?? 0) + 1;

        final newWeeklyCompletions =
            Map<String, int>.from(stats.weeklyCompletions);
        newWeeklyCompletions[weekKey] =
            (newWeeklyCompletions[weekKey] ?? 0) + 1;

        final newMonthlyCompletions =
            Map<String, int>.from(stats.monthlyCompletions);
        newMonthlyCompletions[monthKey] =
            (newMonthlyCompletions[monthKey] ?? 0) + 1;

        // Calculate most productive day and hour
        final mostProductiveDay = _getMostProductiveKey(newTasksByDay);
        final mostProductiveHour = _getMostProductiveKey(newTasksByHour);

        // Calculate average tasks per day
        final totalDays = newWeeklyCompletions.length * 7;
        final totalCompletions =
            stats.totalTasksCompleted + stats.totalHabitsCompleted + 1;
        final avgPerDay = totalDays > 0 ? totalCompletions / totalDays : 0.0;

        final updatedStats = ProductivityStats(
          userId: userId,
          totalTasksCompleted: isHabit
              ? stats.totalTasksCompleted
              : stats.totalTasksCompleted + 1,
          totalHabitsCompleted: isHabit
              ? stats.totalHabitsCompleted + 1
              : stats.totalHabitsCompleted,
          currentStreak: stats.currentStreak,
          longestStreak: stats.longestStreak,
          tasksByDayOfWeek: newTasksByDay,
          tasksByHour: newTasksByHour,
          weeklyCompletions: newWeeklyCompletions,
          monthlyCompletions: newMonthlyCompletions,
          averageTasksPerDay: avgPerDay,
          completionRate: stats.completionRate,
          mostProductiveDay: mostProductiveDay,
          mostProductiveHour: _formatHour(mostProductiveHour),
          totalCoinsEarned: stats.totalCoinsEarned + coinsEarned,
          totalXpEarned: stats.totalXpEarned + xpEarned,
        );

        transaction.set(docRef, updatedStats.toFirestore());
      });
    } catch (e) {
      debugPrint('Error recording task completion stats: $e');
    }
  }

  /// Get weekly comparison data (this week vs last week)
  Future<Map<String, dynamic>> getWeeklyComparison(String userId) async {
    try {
      final stats = await getUserStats(userId);
      final now = DateTime.now();

      final thisWeekKey = _getWeekKey(now);
      final lastWeekKey = _getWeekKey(now.subtract(const Duration(days: 7)));

      final thisWeekCount = stats.weeklyCompletions[thisWeekKey] ?? 0;
      final lastWeekCount = stats.weeklyCompletions[lastWeekKey] ?? 0;

      final change = lastWeekCount > 0
          ? ((thisWeekCount - lastWeekCount) / lastWeekCount * 100).round()
          : thisWeekCount > 0
              ? 100
              : 0;

      return {
        'thisWeek': thisWeekCount,
        'lastWeek': lastWeekCount,
        'changePercent': change,
        'isImproved': thisWeekCount >= lastWeekCount,
      };
    } catch (e) {
      debugPrint('Error getting weekly comparison: $e');
      return {
        'thisWeek': 0,
        'lastWeek': 0,
        'changePercent': 0,
        'isImproved': true,
      };
    }
  }

  /// Get daily completion data for the last 7 days
  Future<List<Map<String, dynamic>>> getLast7DaysCompletions(
      String userId) async {
    try {
      final now = DateTime.now();
      final results = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final query = await _completionRecordsRef
            .where('userId', isEqualTo: userId)
            .where('completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        results.add({
          'date': date,
          'dayName': DateFormat('E').format(date),
          'count': query.docs.length,
        });
      }

      return results;
    } catch (e) {
      debugPrint('Error getting last 7 days completions: $e');
      return [];
    }
  }

  /// Get productivity insights based on stats
  Future<List<String>> getProductivityInsights(String userId) async {
    final stats = await getUserStats(userId);
    final insights = <String>[];

    // Most productive day insight
    if (stats.mostProductiveDay != 'Unknown') {
      insights.add(
          '🌟 Your most productive day is ${stats.mostProductiveDay}. Keep crushing it!');
    }

    // Most productive hour insight
    if (stats.mostProductiveHour != 'Unknown') {
      insights
          .add('⏰ You\'re most productive around ${stats.mostProductiveHour}.');
    }

    // Streak insight
    if (stats.currentStreak >= 7) {
      insights.add(
          '🔥 Amazing! You\'ve maintained a ${stats.currentStreak}-day streak!');
    } else if (stats.currentStreak >= 3) {
      insights.add(
          '💪 Nice ${stats.currentStreak}-day streak! Keep the momentum going!');
    }

    // Completion milestone insights
    if (stats.totalTasksCompleted >= 100) {
      insights.add(
          '🏆 You\'ve completed over ${stats.totalTasksCompleted} tasks! You\'re a task master!');
    } else if (stats.totalTasksCompleted >= 50) {
      insights.add(
          '📈 ${stats.totalTasksCompleted} tasks completed! Halfway to 100!');
    }

    // Score insight
    final score = stats.productivityScore;
    if (score >= 80) {
      insights.add('🚀 Your productivity score is $score%! You\'re on fire!');
    } else if (score >= 50) {
      insights.add('📊 Productivity score: $score%. Room to grow!');
    }

    // Default insight if none
    if (insights.isEmpty) {
      insights.add('💡 Complete more tasks to unlock productivity insights!');
    }

    return insights.take(3).toList();
  }

  // Helper methods
  String _getWeekKey(DateTime date) {
    final weekNumber =
        ((date.difference(DateTime(date.year, 1, 1)).inDays) / 7).ceil() + 1;
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  String _getMostProductiveKey(Map<String, int> data) {
    if (data.isEmpty) return 'Unknown';
    return data.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _formatHour(String hour) {
    if (hour == 'Unknown') return hour;
    try {
      final hourInt = int.parse(hour);
      if (hourInt == 0) return '12 AM';
      if (hourInt == 12) return '12 PM';
      if (hourInt > 12) return '${hourInt - 12} PM';
      return '$hourInt AM';
    } catch (e) {
      return hour;
    }
  }
}
