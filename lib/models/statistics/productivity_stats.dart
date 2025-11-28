import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive productivity statistics model
class ProductivityStats {
  final String userId;
  final int totalTasksCompleted;
  final int totalHabitsCompleted;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> tasksByDayOfWeek; // 'Monday': 5, 'Tuesday': 3, etc.
  final Map<String, int> tasksByHour; // '09': 10, '14': 5, etc.
  final Map<String, int> weeklyCompletions; // '2024-W01': 15, etc.
  final Map<String, int> monthlyCompletions; // '2024-01': 45, etc.
  final double averageTasksPerDay;
  final double completionRate; // completed / total created
  final String mostProductiveDay;
  final String mostProductiveHour;
  final int totalCoinsEarned;
  final int totalXpEarned;
  final DateTime? lastUpdated;

  ProductivityStats({
    required this.userId,
    this.totalTasksCompleted = 0,
    this.totalHabitsCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.tasksByDayOfWeek = const {},
    this.tasksByHour = const {},
    this.weeklyCompletions = const {},
    this.monthlyCompletions = const {},
    this.averageTasksPerDay = 0.0,
    this.completionRate = 0.0,
    this.mostProductiveDay = 'Unknown',
    this.mostProductiveHour = 'Unknown',
    this.totalCoinsEarned = 0,
    this.totalXpEarned = 0,
    this.lastUpdated,
  });

  factory ProductivityStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductivityStats(
      userId: doc.id,
      totalTasksCompleted: data['totalTasksCompleted'] ?? 0,
      totalHabitsCompleted: data['totalHabitsCompleted'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      tasksByDayOfWeek: Map<String, int>.from(data['tasksByDayOfWeek'] ?? {}),
      tasksByHour: Map<String, int>.from(data['tasksByHour'] ?? {}),
      weeklyCompletions: Map<String, int>.from(data['weeklyCompletions'] ?? {}),
      monthlyCompletions:
          Map<String, int>.from(data['monthlyCompletions'] ?? {}),
      averageTasksPerDay: (data['averageTasksPerDay'] ?? 0.0).toDouble(),
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      mostProductiveDay: data['mostProductiveDay'] ?? 'Unknown',
      mostProductiveHour: data['mostProductiveHour'] ?? 'Unknown',
      totalCoinsEarned: data['totalCoinsEarned'] ?? 0,
      totalXpEarned: data['totalXpEarned'] ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalTasksCompleted': totalTasksCompleted,
      'totalHabitsCompleted': totalHabitsCompleted,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'tasksByDayOfWeek': tasksByDayOfWeek,
      'tasksByHour': tasksByHour,
      'weeklyCompletions': weeklyCompletions,
      'monthlyCompletions': monthlyCompletions,
      'averageTasksPerDay': averageTasksPerDay,
      'completionRate': completionRate,
      'mostProductiveDay': mostProductiveDay,
      'mostProductiveHour': mostProductiveHour,
      'totalCoinsEarned': totalCoinsEarned,
      'totalXpEarned': totalXpEarned,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Get productivity score (0-100)
  int get productivityScore {
    double score = 0;

    // Completion rate contribution (30%)
    score += completionRate * 30;

    // Streak contribution (25%)
    score += (currentStreak / 30.0).clamp(0, 1) * 25;

    // Consistency contribution (25%) - based on tasks per day
    score += (averageTasksPerDay / 5.0).clamp(0, 1) * 25;

    // Activity contribution (20%) - based on total completions
    final activityScore =
        ((totalTasksCompleted + totalHabitsCompleted) / 100.0).clamp(0, 1);
    score += activityScore * 20;

    return score.round().clamp(0, 100);
  }

  /// Get score level name
  String get scoreLevel {
    final score = productivityScore;
    if (score >= 90) return 'Legendary';
    if (score >= 75) return 'Expert';
    if (score >= 60) return 'Advanced';
    if (score >= 40) return 'Intermediate';
    if (score >= 20) return 'Beginner';
    return 'Novice';
  }

  /// Copy with new values
  ProductivityStats copyWith({
    int? totalTasksCompleted,
    int? totalHabitsCompleted,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? tasksByDayOfWeek,
    Map<String, int>? tasksByHour,
    Map<String, int>? weeklyCompletions,
    Map<String, int>? monthlyCompletions,
    double? averageTasksPerDay,
    double? completionRate,
    String? mostProductiveDay,
    String? mostProductiveHour,
    int? totalCoinsEarned,
    int? totalXpEarned,
  }) {
    return ProductivityStats(
      userId: userId,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      tasksByDayOfWeek: tasksByDayOfWeek ?? this.tasksByDayOfWeek,
      tasksByHour: tasksByHour ?? this.tasksByHour,
      weeklyCompletions: weeklyCompletions ?? this.weeklyCompletions,
      monthlyCompletions: monthlyCompletions ?? this.monthlyCompletions,
      averageTasksPerDay: averageTasksPerDay ?? this.averageTasksPerDay,
      completionRate: completionRate ?? this.completionRate,
      mostProductiveDay: mostProductiveDay ?? this.mostProductiveDay,
      mostProductiveHour: mostProductiveHour ?? this.mostProductiveHour,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      lastUpdated: DateTime.now(),
    );
  }
}
