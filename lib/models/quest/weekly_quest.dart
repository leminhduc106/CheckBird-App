import 'package:flutter/material.dart';

/// Quest difficulty levels
enum QuestDifficulty {
  easy,
  medium,
  hard,
  legendary,
}

/// Quest types for different objectives
enum QuestType {
  completeTasks,
  completeHabits,
  loginStreak,
  groupTasks,
  earlyBird,
  nightOwl,
  perfectDay,
  shopPurchase,
  socialInteraction,
}

/// A weekly quest/challenge
class WeeklyQuest {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final QuestType type;
  final QuestDifficulty difficulty;
  final int targetValue;
  final int coinsReward;
  final int gemsReward;
  final int xpReward;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.difficulty,
    required this.targetValue,
    this.coinsReward = 0,
    this.gemsReward = 0,
    this.xpReward = 0,
    required this.weekStart,
    required this.weekEnd,
  });

  factory WeeklyQuest.fromMap(Map<String, dynamic> data) {
    return WeeklyQuest(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: _iconFromString(data['icon'] ?? 'star'),
      color: Color(data['color'] ?? 0xFF6200EA),
      type: QuestType.values[data['type'] ?? 0],
      difficulty: QuestDifficulty.values[data['difficulty'] ?? 0],
      targetValue: data['targetValue'] ?? 1,
      coinsReward: data['coinsReward'] ?? 0,
      gemsReward: data['gemsReward'] ?? 0,
      xpReward: data['xpReward'] ?? 0,
      weekStart: DateTime.parse(data['weekStart']),
      weekEnd: DateTime.parse(data['weekEnd']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': _iconToString(icon),
      'color': color.value,
      'type': type.index,
      'difficulty': difficulty.index,
      'targetValue': targetValue,
      'coinsReward': coinsReward,
      'gemsReward': gemsReward,
      'xpReward': xpReward,
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
    };
  }

  static IconData _iconFromString(String name) {
    final iconMap = {
      'check_circle': Icons.check_circle,
      'repeat': Icons.repeat,
      'local_fire_department': Icons.local_fire_department,
      'groups': Icons.groups,
      'wb_sunny': Icons.wb_sunny,
      'nightlight': Icons.nightlight,
      'calendar_today': Icons.calendar_today,
      'shopping_bag': Icons.shopping_bag,
      'forum': Icons.forum,
      'star': Icons.star,
      'emoji_events': Icons.emoji_events,
      'military_tech': Icons.military_tech,
    };
    return iconMap[name] ?? Icons.star;
  }

  static String _iconToString(IconData icon) {
    final iconMap = {
      Icons.check_circle: 'check_circle',
      Icons.repeat: 'repeat',
      Icons.local_fire_department: 'local_fire_department',
      Icons.groups: 'groups',
      Icons.wb_sunny: 'wb_sunny',
      Icons.nightlight: 'nightlight',
      Icons.calendar_today: 'calendar_today',
      Icons.shopping_bag: 'shopping_bag',
      Icons.forum: 'forum',
      Icons.star: 'star',
      Icons.emoji_events: 'emoji_events',
      Icons.military_tech: 'military_tech',
    };
    return iconMap[icon] ?? 'star';
  }

  String get difficultyName {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 'Easy';
      case QuestDifficulty.medium:
        return 'Medium';
      case QuestDifficulty.hard:
        return 'Hard';
      case QuestDifficulty.legendary:
        return 'Legendary';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.medium:
        return Colors.blue;
      case QuestDifficulty.hard:
        return Colors.orange;
      case QuestDifficulty.legendary:
        return Colors.purple;
    }
  }

  /// Generate predefined quests based on week number
  static List<WeeklyQuest> generateQuestsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekNumber =
        (weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays / 7)
            .floor();

    // Rotate quest pools based on week number
    final questPools = [
      // Pool 1: Task focused
      [
        WeeklyQuest(
          id: 'complete_7_tasks',
          title: 'Task Week',
          description: 'Complete 7 tasks this week',
          icon: Icons.check_circle,
          color: Colors.green,
          type: QuestType.completeTasks,
          difficulty: QuestDifficulty.easy,
          targetValue: 7,
          coinsReward: 20,
          xpReward: 100,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'complete_20_tasks',
          title: 'Task Master',
          description: 'Complete 20 tasks this week',
          icon: Icons.military_tech,
          color: Colors.teal,
          type: QuestType.completeTasks,
          difficulty: QuestDifficulty.hard,
          targetValue: 20,
          coinsReward: 50,
          gemsReward: 5,
          xpReward: 250,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'complete_5_habits',
          title: 'Habit Builder',
          description: 'Complete habits 5 times this week',
          icon: Icons.repeat,
          color: Colors.blue,
          type: QuestType.completeHabits,
          difficulty: QuestDifficulty.easy,
          targetValue: 5,
          coinsReward: 15,
          xpReward: 75,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
      ],
      // Pool 2: Streak focused
      [
        WeeklyQuest(
          id: 'login_streak_7',
          title: 'Dedication Week',
          description: 'Login every day this week (7-day streak)',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          type: QuestType.loginStreak,
          difficulty: QuestDifficulty.medium,
          targetValue: 7,
          coinsReward: 35,
          xpReward: 150,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'perfect_day_3',
          title: 'Consistent Champion',
          description: 'Have 3 days where you complete at least 3 tasks',
          icon: Icons.calendar_today,
          color: Colors.indigo,
          type: QuestType.perfectDay,
          difficulty: QuestDifficulty.medium,
          targetValue: 3,
          coinsReward: 30,
          xpReward: 125,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'early_bird_2',
          title: 'Early Riser',
          description: 'Complete 2 tasks before 8 AM',
          icon: Icons.wb_sunny,
          color: Colors.amber,
          type: QuestType.earlyBird,
          difficulty: QuestDifficulty.hard,
          targetValue: 2,
          coinsReward: 40,
          gemsReward: 3,
          xpReward: 200,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
      ],
      // Pool 3: Social focused
      [
        WeeklyQuest(
          id: 'group_tasks_5',
          title: 'Team Player',
          description: 'Complete 5 group tasks this week',
          icon: Icons.groups,
          color: Colors.cyan,
          type: QuestType.groupTasks,
          difficulty: QuestDifficulty.medium,
          targetValue: 5,
          coinsReward: 25,
          xpReward: 125,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'complete_14_habits',
          title: 'Habit Champion',
          description: 'Complete habits 14 times this week (2/day)',
          icon: Icons.emoji_events,
          color: Colors.deepPurple,
          type: QuestType.completeHabits,
          difficulty: QuestDifficulty.hard,
          targetValue: 14,
          coinsReward: 45,
          gemsReward: 5,
          xpReward: 225,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'night_owl_2',
          title: 'Night Achiever',
          description: 'Complete 2 tasks after 10 PM',
          icon: Icons.nightlight,
          color: Colors.deepPurple,
          type: QuestType.nightOwl,
          difficulty: QuestDifficulty.medium,
          targetValue: 2,
          coinsReward: 25,
          xpReward: 100,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
      ],
      // Pool 4: Mixed challenges
      [
        WeeklyQuest(
          id: 'complete_15_tasks',
          title: 'Productivity Sprint',
          description: 'Complete 15 tasks this week',
          icon: Icons.rocket_launch,
          color: Colors.red,
          type: QuestType.completeTasks,
          difficulty: QuestDifficulty.medium,
          targetValue: 15,
          coinsReward: 40,
          xpReward: 175,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'group_tasks_10',
          title: 'Group Champion',
          description: 'Complete 10 group tasks this week',
          icon: Icons.handshake,
          color: Colors.teal,
          type: QuestType.groupTasks,
          difficulty: QuestDifficulty.legendary,
          targetValue: 10,
          coinsReward: 75,
          gemsReward: 10,
          xpReward: 400,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
        WeeklyQuest(
          id: 'perfect_week',
          title: 'Perfect Week',
          description: 'Complete at least 1 task every day for 7 days',
          icon: Icons.star,
          color: Colors.amber,
          type: QuestType.perfectDay,
          difficulty: QuestDifficulty.legendary,
          targetValue: 7,
          coinsReward: 100,
          gemsReward: 15,
          xpReward: 500,
          weekStart: weekStart,
          weekEnd: weekEnd,
        ),
      ],
    ];

    // Select quest pool based on week number (rotate through pools)
    final poolIndex = weekNumber % questPools.length;
    return questPools[poolIndex];
  }
}

/// User's progress on a quest
class QuestProgress {
  final String questId;
  final int currentProgress;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool rewardsClaimed;

  const QuestProgress({
    required this.questId,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.completedAt,
    this.rewardsClaimed = false,
  });

  factory QuestProgress.fromMap(Map<String, dynamic> data) {
    return QuestProgress(
      questId: data['questId'] ?? '',
      currentProgress: data['currentProgress'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt']?.toDate(),
      rewardsClaimed: data['rewardsClaimed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questId': questId,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'rewardsClaimed': rewardsClaimed,
    };
  }

  QuestProgress copyWith({
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
    bool? rewardsClaimed,
  }) {
    return QuestProgress(
      questId: questId,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }

  double getProgressPercentage(int targetValue) {
    if (targetValue <= 0) return 0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }
}
