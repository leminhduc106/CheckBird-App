import 'package:flutter/material.dart';

/// Mood levels for daily tracking
enum MoodLevel {
  terrible,
  bad,
  okay,
  good,
  great,
}

extension MoodLevelExtension on MoodLevel {
  String get emoji {
    switch (this) {
      case MoodLevel.terrible:
        return '😢';
      case MoodLevel.bad:
        return '😔';
      case MoodLevel.okay:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.great:
        return '😄';
    }
  }

  String get label {
    switch (this) {
      case MoodLevel.terrible:
        return 'Terrible';
      case MoodLevel.bad:
        return 'Bad';
      case MoodLevel.okay:
        return 'Okay';
      case MoodLevel.good:
        return 'Good';
      case MoodLevel.great:
        return 'Great';
    }
  }

  Color get color {
    switch (this) {
      case MoodLevel.terrible:
        return const Color(0xFFE53935);
      case MoodLevel.bad:
        return const Color(0xFFFF7043);
      case MoodLevel.okay:
        return const Color(0xFFFFCA28);
      case MoodLevel.good:
        return const Color(0xFF66BB6A);
      case MoodLevel.great:
        return const Color(0xFF42A5F5);
    }
  }

  int get value {
    switch (this) {
      case MoodLevel.terrible:
        return 1;
      case MoodLevel.bad:
        return 2;
      case MoodLevel.okay:
        return 3;
      case MoodLevel.good:
        return 4;
      case MoodLevel.great:
        return 5;
    }
  }

  static MoodLevel fromValue(int value) {
    switch (value) {
      case 1:
        return MoodLevel.terrible;
      case 2:
        return MoodLevel.bad;
      case 3:
        return MoodLevel.okay;
      case 4:
        return MoodLevel.good;
      case 5:
        return MoodLevel.great;
      default:
        return MoodLevel.okay;
    }
  }
}

/// Energy levels for daily tracking
enum EnergyLevel {
  exhausted,
  tired,
  normal,
  energetic,
  supercharged,
}

extension EnergyLevelExtension on EnergyLevel {
  String get emoji {
    switch (this) {
      case EnergyLevel.exhausted:
        return '🪫';
      case EnergyLevel.tired:
        return '😴';
      case EnergyLevel.normal:
        return '⚡';
      case EnergyLevel.energetic:
        return '💪';
      case EnergyLevel.supercharged:
        return '🔥';
    }
  }

  String get label {
    switch (this) {
      case EnergyLevel.exhausted:
        return 'Exhausted';
      case EnergyLevel.tired:
        return 'Tired';
      case EnergyLevel.normal:
        return 'Normal';
      case EnergyLevel.energetic:
        return 'Energetic';
      case EnergyLevel.supercharged:
        return 'Supercharged';
    }
  }

  Color get color {
    switch (this) {
      case EnergyLevel.exhausted:
        return const Color(0xFF78909C);
      case EnergyLevel.tired:
        return const Color(0xFFB0BEC5);
      case EnergyLevel.normal:
        return const Color(0xFFFFB74D);
      case EnergyLevel.energetic:
        return const Color(0xFFFF9800);
      case EnergyLevel.supercharged:
        return const Color(0xFFFF5722);
    }
  }

  int get value {
    switch (this) {
      case EnergyLevel.exhausted:
        return 1;
      case EnergyLevel.tired:
        return 2;
      case EnergyLevel.normal:
        return 3;
      case EnergyLevel.energetic:
        return 4;
      case EnergyLevel.supercharged:
        return 5;
    }
  }

  static EnergyLevel fromValue(int value) {
    switch (value) {
      case 1:
        return EnergyLevel.exhausted;
      case 2:
        return EnergyLevel.tired;
      case 3:
        return EnergyLevel.normal;
      case 4:
        return EnergyLevel.energetic;
      case 5:
        return EnergyLevel.supercharged;
      default:
        return EnergyLevel.normal;
    }
  }
}

/// Daily mood entry
class MoodEntry {
  final String id;
  final DateTime date;
  final MoodLevel mood;
  final EnergyLevel energy;
  final String? note;
  final List<String> factors; // What affected mood: sleep, exercise, work, etc.
  final int tasksCompleted;
  final int habitsCompleted;
  final int focusMinutes;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.energy,
    this.note,
    this.factors = const [],
    this.tasksCompleted = 0,
    this.habitsCompleted = 0,
    this.focusMinutes = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood.value,
      'energy': energy.value,
      'note': note,
      'factors': factors,
      'tasksCompleted': tasksCompleted,
      'habitsCompleted': habitsCompleted,
      'focusMinutes': focusMinutes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: MoodLevelExtension.fromValue(json['mood'] as int),
      energy: EnergyLevelExtension.fromValue(json['energy'] as int),
      note: json['note'] as String?,
      factors: List<String>.from(json['factors'] ?? []),
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      habitsCompleted: json['habitsCompleted'] as int? ?? 0,
      focusMinutes: json['focusMinutes'] as int? ?? 0,
    );
  }

  MoodEntry copyWith({
    MoodLevel? mood,
    EnergyLevel? energy,
    String? note,
    List<String>? factors,
    int? tasksCompleted,
    int? habitsCompleted,
    int? focusMinutes,
  }) {
    return MoodEntry(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      note: note ?? this.note,
      factors: factors ?? this.factors,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      focusMinutes: focusMinutes ?? this.focusMinutes,
    );
  }
}

/// Mood factors that can affect daily mood
class MoodFactor {
  final String id;
  final String label;
  final String emoji;
  final bool isPositive;

  const MoodFactor({
    required this.id,
    required this.label,
    required this.emoji,
    this.isPositive = true,
  });

  static const List<MoodFactor> allFactors = [
    // Positive factors
    MoodFactor(
        id: 'good_sleep', label: 'Good Sleep', emoji: '😴', isPositive: true),
    MoodFactor(
        id: 'exercise', label: 'Exercise', emoji: '🏃', isPositive: true),
    MoodFactor(
        id: 'healthy_food',
        label: 'Healthy Food',
        emoji: '🥗',
        isPositive: true),
    MoodFactor(
        id: 'social', label: 'Social Time', emoji: '👥', isPositive: true),
    MoodFactor(
        id: 'nature', label: 'Time in Nature', emoji: '🌳', isPositive: true),
    MoodFactor(
        id: 'meditation', label: 'Meditation', emoji: '🧘', isPositive: true),
    MoodFactor(
        id: 'achievement', label: 'Achievement', emoji: '🏆', isPositive: true),
    MoodFactor(id: 'hobby', label: 'Hobby Time', emoji: '🎨', isPositive: true),

    // Negative factors
    MoodFactor(
        id: 'poor_sleep', label: 'Poor Sleep', emoji: '😵', isPositive: false),
    MoodFactor(id: 'stress', label: 'Stress', emoji: '😰', isPositive: false),
    MoodFactor(
        id: 'work_pressure',
        label: 'Work Pressure',
        emoji: '💼',
        isPositive: false),
    MoodFactor(
        id: 'health_issue',
        label: 'Health Issue',
        emoji: '🤒',
        isPositive: false),
    MoodFactor(
        id: 'conflict', label: 'Conflict', emoji: '😤', isPositive: false),
    MoodFactor(id: 'anxiety', label: 'Anxiety', emoji: '😟', isPositive: false),
    MoodFactor(
        id: 'loneliness', label: 'Loneliness', emoji: '😢', isPositive: false),
    MoodFactor(id: 'fatigue', label: 'Fatigue', emoji: '🥱', isPositive: false),
  ];

  static MoodFactor? getById(String id) {
    try {
      return allFactors.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Weekly mood summary
class MoodWeeklySummary {
  final DateTime weekStart;
  final double averageMood;
  final double averageEnergy;
  final int totalEntries;
  final Map<String, int> factorFrequency;
  final int totalTasksCompleted;
  final int totalHabitsCompleted;
  final int totalFocusMinutes;

  MoodWeeklySummary({
    required this.weekStart,
    required this.averageMood,
    required this.averageEnergy,
    required this.totalEntries,
    required this.factorFrequency,
    required this.totalTasksCompleted,
    required this.totalHabitsCompleted,
    required this.totalFocusMinutes,
  });

  String get moodTrend {
    if (averageMood >= 4.5) return 'Excellent';
    if (averageMood >= 3.5) return 'Good';
    if (averageMood >= 2.5) return 'Fair';
    if (averageMood >= 1.5) return 'Low';
    return 'Very Low';
  }

  List<String> get topPositiveFactors {
    final positive = factorFrequency.entries
        .where((e) => MoodFactor.getById(e.key)?.isPositive == true)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return positive.take(3).map((e) => e.key).toList();
  }

  List<String> get topNegativeFactors {
    final negative = factorFrequency.entries
        .where((e) => MoodFactor.getById(e.key)?.isPositive == false)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return negative.take(3).map((e) => e.key).toList();
  }
}
