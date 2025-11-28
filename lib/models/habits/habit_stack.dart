import 'package:flutter/material.dart';

/// A single habit within a stack
class StackedHabit {
  final String id;
  final String name;
  final String? description;
  final int orderIndex;
  final Duration estimatedDuration;
  final String? emoji;
  final bool completed;
  final DateTime? completedAt;

  const StackedHabit({
    required this.id,
    required this.name,
    this.description,
    required this.orderIndex,
    this.estimatedDuration = const Duration(minutes: 5),
    this.emoji,
    this.completed = false,
    this.completedAt,
  });

  StackedHabit copyWith({
    String? id,
    String? name,
    String? description,
    int? orderIndex,
    Duration? estimatedDuration,
    String? emoji,
    bool? completed,
    DateTime? completedAt,
  }) {
    return StackedHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      emoji: emoji ?? this.emoji,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'orderIndex': orderIndex,
        'estimatedMinutes': estimatedDuration.inMinutes,
        'emoji': emoji,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory StackedHabit.fromJson(Map<String, dynamic> json) {
    return StackedHabit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      orderIndex: json['orderIndex'] ?? 0,
      estimatedDuration: Duration(minutes: json['estimatedMinutes'] ?? 5),
      emoji: json['emoji'],
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

/// A stack/chain of habits
class HabitStack {
  final String id;
  final String name;
  final String? description;
  final TriggerType triggerType;
  final TimeOfDay? scheduledTime;
  final String? triggerEvent;
  final List<StackedHabit> habits;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final List<String> completionHistory; // Date strings when completed

  const HabitStack({
    required this.id,
    required this.name,
    this.description,
    this.triggerType = TriggerType.time,
    this.scheduledTime,
    this.triggerEvent,
    this.habits = const [],
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.completionHistory = const [],
  });

  Duration get totalEstimatedTime {
    return habits.fold(
      Duration.zero,
      (total, habit) => total + habit.estimatedDuration,
    );
  }

  int get completedCount => habits.where((h) => h.completed).length;

  double get completionProgress =>
      habits.isEmpty ? 0 : completedCount / habits.length;

  bool get isCompletedToday {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return completionHistory.contains(todayKey);
  }

  String get triggerDescription {
    switch (triggerType) {
      case TriggerType.time:
        if (scheduledTime != null) {
          return 'At ${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}';
        }
        return 'Scheduled time';
      case TriggerType.afterWaking:
        return 'After waking up';
      case TriggerType.beforeSleep:
        return 'Before sleep';
      case TriggerType.afterMeal:
        return 'After eating';
      case TriggerType.afterExercise:
        return 'After exercise';
      case TriggerType.custom:
        return triggerEvent ?? 'Custom trigger';
    }
  }

  HabitStack copyWith({
    String? id,
    String? name,
    String? description,
    TriggerType? triggerType,
    TimeOfDay? scheduledTime,
    String? triggerEvent,
    List<StackedHabit>? habits,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    DateTime? createdAt,
    List<String>? completionHistory,
  }) {
    return HabitStack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      triggerType: triggerType ?? this.triggerType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      triggerEvent: triggerEvent ?? this.triggerEvent,
      habits: habits ?? this.habits,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt ?? this.createdAt,
      completionHistory: completionHistory ?? this.completionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'triggerType': triggerType.name,
        'scheduledHour': scheduledTime?.hour,
        'scheduledMinute': scheduledTime?.minute,
        'triggerEvent': triggerEvent,
        'habits': habits.map((h) => h.toJson()).toList(),
        'isActive': isActive,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'createdAt': createdAt.toIso8601String(),
        'completionHistory': completionHistory,
      };

  factory HabitStack.fromJson(Map<String, dynamic> json) {
    return HabitStack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      triggerType: TriggerType.values.firstWhere(
        (e) => e.name == json['triggerType'],
        orElse: () => TriggerType.time,
      ),
      scheduledTime: json['scheduledHour'] != null
          ? TimeOfDay(
              hour: json['scheduledHour'],
              minute: json['scheduledMinute'] ?? 0,
            )
          : null,
      triggerEvent: json['triggerEvent'],
      habits: (json['habits'] as List? ?? [])
          .map((h) => StackedHabit.fromJson(h))
          .toList(),
      isActive: json['isActive'] ?? true,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      completionHistory: List<String>.from(json['completionHistory'] ?? []),
    );
  }
}

enum TriggerType {
  time,
  afterWaking,
  beforeSleep,
  afterMeal,
  afterExercise,
  custom,
}

/// Pre-built habit stack templates
class HabitStackTemplate {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final TriggerType triggerType;
  final TimeOfDay? suggestedTime;
  final List<StackedHabit> habits;

  const HabitStackTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.triggerType,
    this.suggestedTime,
    required this.habits,
  });

  HabitStack toHabitStack() {
    return HabitStack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      triggerType: triggerType,
      scheduledTime: suggestedTime,
      habits: habits
          .map((h) => h.copyWith(
                id: '${DateTime.now().millisecondsSinceEpoch}_${h.orderIndex}',
              ))
          .toList(),
      createdAt: DateTime.now(),
    );
  }

  static List<HabitStackTemplate> get templates => [
        HabitStackTemplate(
          id: 'morning_routine',
          name: 'Morning Routine',
          description: 'Start your day right',
          emoji: '🌅',
          triggerType: TriggerType.afterWaking,
          suggestedTime: const TimeOfDay(hour: 7, minute: 0),
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Make bed',
              emoji: '🛏️',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 2),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Drink water',
              emoji: '💧',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 1),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Stretch / Light exercise',
              emoji: '🧘',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 10),
            ),
            const StackedHabit(
              id: 'temp_4',
              name: 'Journal / Plan day',
              emoji: '📝',
              orderIndex: 3,
              estimatedDuration: Duration(minutes: 10),
            ),
          ],
        ),
        HabitStackTemplate(
          id: 'evening_wind_down',
          name: 'Evening Wind-Down',
          description: 'Prepare for restful sleep',
          emoji: '🌙',
          triggerType: TriggerType.beforeSleep,
          suggestedTime: const TimeOfDay(hour: 21, minute: 0),
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Put devices away',
              emoji: '📵',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 1),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Review tomorrow\'s tasks',
              emoji: '📋',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Gratitude journal',
              emoji: '🙏',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_4',
              name: 'Read a book',
              emoji: '📚',
              orderIndex: 3,
              estimatedDuration: Duration(minutes: 20),
            ),
          ],
        ),
        HabitStackTemplate(
          id: 'deep_work_prep',
          name: 'Deep Work Prep',
          description: 'Set up for focused work',
          emoji: '🧠',
          triggerType: TriggerType.time,
          suggestedTime: const TimeOfDay(hour: 9, minute: 0),
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Clear desk',
              emoji: '🧹',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 3),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Close unnecessary tabs/apps',
              emoji: '🔇',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 2),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Set today\'s focus goal',
              emoji: '🎯',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 3),
            ),
            const StackedHabit(
              id: 'temp_4',
              name: 'Start focus timer',
              emoji: '⏱️',
              orderIndex: 3,
              estimatedDuration: Duration(minutes: 1),
            ),
          ],
        ),
        HabitStackTemplate(
          id: 'post_workout',
          name: 'Post-Workout Recovery',
          description: 'Maximize your workout gains',
          emoji: '💪',
          triggerType: TriggerType.afterExercise,
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Cool-down stretches',
              emoji: '🧘‍♂️',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Protein shake / snack',
              emoji: '🥤',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Log workout',
              emoji: '📊',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 2),
            ),
            const StackedHabit(
              id: 'temp_4',
              name: 'Shower & refresh',
              emoji: '🚿',
              orderIndex: 3,
              estimatedDuration: Duration(minutes: 15),
            ),
          ],
        ),
        HabitStackTemplate(
          id: 'mindfulness',
          name: 'Mindfulness Break',
          description: 'Reset and recharge',
          emoji: '🧘',
          triggerType: TriggerType.time,
          suggestedTime: const TimeOfDay(hour: 14, minute: 0),
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Step away from screen',
              emoji: '👋',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 1),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Deep breathing (5 breaths)',
              emoji: '🌬️',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 2),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Quick meditation',
              emoji: '🧘',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_4',
              name: 'Drink water',
              emoji: '💧',
              orderIndex: 3,
              estimatedDuration: Duration(minutes: 1),
            ),
          ],
        ),
        HabitStackTemplate(
          id: 'learning',
          name: 'Daily Learning',
          description: 'Continuous growth mindset',
          emoji: '📚',
          triggerType: TriggerType.time,
          suggestedTime: const TimeOfDay(hour: 19, minute: 0),
          habits: [
            const StackedHabit(
              id: 'temp_1',
              name: 'Read for 15 minutes',
              emoji: '📖',
              orderIndex: 0,
              estimatedDuration: Duration(minutes: 15),
            ),
            const StackedHabit(
              id: 'temp_2',
              name: 'Take notes / highlights',
              emoji: '✍️',
              orderIndex: 1,
              estimatedDuration: Duration(minutes: 5),
            ),
            const StackedHabit(
              id: 'temp_3',
              name: 'Review flashcards / practice',
              emoji: '🎴',
              orderIndex: 2,
              estimatedDuration: Duration(minutes: 10),
            ),
          ],
        ),
      ];
}
