import 'package:flutter/material.dart';

/// Achievement types for different categories
enum AchievementCategory {
  tasks,
  habits,
  streaks,
  social,
  shop,
  special,
}

/// Single achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;
  final int targetValue;
  final int coinsReward;
  final int gemsReward;
  final int xpReward;
  final bool isSecret;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.targetValue,
    this.coinsReward = 0,
    this.gemsReward = 0,
    this.xpReward = 0,
    this.isSecret = false,
  });

  /// All available achievements in the app
  static List<Achievement> get allAchievements => [
        // === TASK ACHIEVEMENTS ===
        const Achievement(
          id: 'first_task',
          name: 'First Step',
          description: 'Complete your first task',
          icon: Icons.check_circle,
          color: Colors.green,
          category: AchievementCategory.tasks,
          targetValue: 1,
          coinsReward: 5,
          xpReward: 25,
        ),
        const Achievement(
          id: 'task_10',
          name: 'Getting Started',
          description: 'Complete 10 tasks',
          icon: Icons.playlist_add_check,
          color: Colors.green,
          category: AchievementCategory.tasks,
          targetValue: 10,
          coinsReward: 10,
          xpReward: 50,
        ),
        const Achievement(
          id: 'task_50',
          name: 'Task Enthusiast',
          description: 'Complete 50 tasks',
          icon: Icons.task_alt,
          color: Colors.teal,
          category: AchievementCategory.tasks,
          targetValue: 50,
          coinsReward: 25,
          xpReward: 100,
        ),
        const Achievement(
          id: 'task_100',
          name: 'Task Master',
          description: 'Complete 100 tasks',
          icon: Icons.military_tech,
          color: Colors.blue,
          category: AchievementCategory.tasks,
          targetValue: 100,
          coinsReward: 50,
          gemsReward: 5,
          xpReward: 200,
        ),
        const Achievement(
          id: 'task_500',
          name: 'Task Legend',
          description: 'Complete 500 tasks',
          icon: Icons.emoji_events,
          color: Colors.purple,
          category: AchievementCategory.tasks,
          targetValue: 500,
          coinsReward: 100,
          gemsReward: 15,
          xpReward: 500,
        ),
        const Achievement(
          id: 'task_1000',
          name: 'Task God',
          description: 'Complete 1000 tasks',
          icon: Icons.stars,
          color: Colors.amber,
          category: AchievementCategory.tasks,
          targetValue: 1000,
          coinsReward: 200,
          gemsReward: 30,
          xpReward: 1000,
        ),

        // === HABIT ACHIEVEMENTS ===
        const Achievement(
          id: 'first_habit',
          name: 'Habit Formed',
          description: 'Complete your first habit',
          icon: Icons.repeat,
          color: Colors.blue,
          category: AchievementCategory.habits,
          targetValue: 1,
          coinsReward: 5,
          xpReward: 25,
        ),
        const Achievement(
          id: 'habit_25',
          name: 'Habit Builder',
          description: 'Complete 25 habits',
          icon: Icons.loop,
          color: Colors.blue,
          category: AchievementCategory.habits,
          targetValue: 25,
          coinsReward: 15,
          xpReward: 75,
        ),
        const Achievement(
          id: 'habit_100',
          name: 'Habit Champion',
          description: 'Complete 100 habits',
          icon: Icons.sync,
          color: Colors.indigo,
          category: AchievementCategory.habits,
          targetValue: 100,
          coinsReward: 50,
          gemsReward: 5,
          xpReward: 200,
        ),
        const Achievement(
          id: 'habit_365',
          name: 'Year of Habits',
          description: 'Complete 365 habits',
          icon: Icons.calendar_today,
          color: Colors.deepPurple,
          category: AchievementCategory.habits,
          targetValue: 365,
          coinsReward: 150,
          gemsReward: 20,
          xpReward: 750,
        ),

        // === STREAK ACHIEVEMENTS ===
        const Achievement(
          id: 'streak_3',
          name: 'On a Roll',
          description: 'Maintain a 3-day login streak',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          category: AchievementCategory.streaks,
          targetValue: 3,
          coinsReward: 10,
          xpReward: 30,
        ),
        const Achievement(
          id: 'streak_7',
          name: 'Week Warrior',
          description: 'Maintain a 7-day login streak',
          icon: Icons.whatshot,
          color: Colors.orange,
          category: AchievementCategory.streaks,
          targetValue: 7,
          coinsReward: 20,
          xpReward: 75,
        ),
        const Achievement(
          id: 'streak_14',
          name: 'Fortnight Fighter',
          description: 'Maintain a 14-day login streak',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
          category: AchievementCategory.streaks,
          targetValue: 14,
          coinsReward: 35,
          xpReward: 125,
        ),
        const Achievement(
          id: 'streak_30',
          name: 'Monthly Master',
          description: 'Maintain a 30-day login streak',
          icon: Icons.celebration,
          color: Colors.red,
          category: AchievementCategory.streaks,
          targetValue: 30,
          coinsReward: 75,
          gemsReward: 10,
          xpReward: 300,
        ),
        const Achievement(
          id: 'streak_100',
          name: 'Century Striker',
          description: 'Maintain a 100-day login streak',
          icon: Icons.auto_awesome,
          color: Colors.amber,
          category: AchievementCategory.streaks,
          targetValue: 100,
          coinsReward: 200,
          gemsReward: 25,
          xpReward: 1000,
        ),
        const Achievement(
          id: 'streak_365',
          name: 'Year of Dedication',
          description: 'Maintain a 365-day login streak',
          icon: Icons.diamond,
          color: Colors.pink,
          category: AchievementCategory.streaks,
          targetValue: 365,
          coinsReward: 500,
          gemsReward: 100,
          xpReward: 5000,
          isSecret: true,
        ),

        // === SOCIAL ACHIEVEMENTS ===
        const Achievement(
          id: 'join_group',
          name: 'Team Player',
          description: 'Join your first group',
          icon: Icons.group_add,
          color: Colors.cyan,
          category: AchievementCategory.social,
          targetValue: 1,
          coinsReward: 10,
          xpReward: 50,
        ),
        const Achievement(
          id: 'join_3_groups',
          name: 'Social Butterfly',
          description: 'Join 3 different groups',
          icon: Icons.groups,
          color: Colors.cyan,
          category: AchievementCategory.social,
          targetValue: 3,
          coinsReward: 25,
          xpReward: 100,
        ),
        const Achievement(
          id: 'group_task_10',
          name: 'Team Contributor',
          description: 'Complete 10 group tasks',
          icon: Icons.handshake,
          color: Colors.teal,
          category: AchievementCategory.social,
          targetValue: 10,
          coinsReward: 30,
          xpReward: 150,
        ),
        const Achievement(
          id: 'group_task_50',
          name: 'Group Champion',
          description: 'Complete 50 group tasks',
          icon: Icons.workspace_premium,
          color: Colors.indigo,
          category: AchievementCategory.social,
          targetValue: 50,
          coinsReward: 75,
          gemsReward: 10,
          xpReward: 400,
        ),

        // === SHOP ACHIEVEMENTS ===
        const Achievement(
          id: 'first_purchase',
          name: 'First Purchase',
          description: 'Buy your first shop item',
          icon: Icons.shopping_bag,
          color: Colors.pink,
          category: AchievementCategory.shop,
          targetValue: 1,
          coinsReward: 5,
          xpReward: 25,
        ),
        const Achievement(
          id: 'purchase_5',
          name: 'Shopping Spree',
          description: 'Buy 5 shop items',
          icon: Icons.shopping_cart,
          color: Colors.pink,
          category: AchievementCategory.shop,
          targetValue: 5,
          coinsReward: 25,
          xpReward: 100,
        ),
        const Achievement(
          id: 'collector',
          name: 'Collector',
          description: 'Own 10 shop items',
          icon: Icons.collections,
          color: Colors.purple,
          category: AchievementCategory.shop,
          targetValue: 10,
          coinsReward: 50,
          gemsReward: 5,
          xpReward: 250,
        ),

        // === SPECIAL ACHIEVEMENTS ===
        const Achievement(
          id: 'level_5',
          name: 'Rising Star',
          description: 'Reach level 5',
          icon: Icons.star,
          color: Colors.amber,
          category: AchievementCategory.special,
          targetValue: 5,
          coinsReward: 25,
          xpReward: 100,
        ),
        const Achievement(
          id: 'level_10',
          name: 'Experienced',
          description: 'Reach level 10',
          icon: Icons.star_half,
          color: Colors.amber,
          category: AchievementCategory.special,
          targetValue: 10,
          coinsReward: 50,
          gemsReward: 10,
          xpReward: 250,
        ),
        const Achievement(
          id: 'level_25',
          name: 'Veteran',
          description: 'Reach level 25',
          icon: Icons.stars,
          color: Colors.orange,
          category: AchievementCategory.special,
          targetValue: 25,
          coinsReward: 150,
          gemsReward: 25,
          xpReward: 750,
        ),
        const Achievement(
          id: 'productivity_master',
          name: 'Productivity Master',
          description: 'Reach a productivity score of 80%',
          icon: Icons.speed,
          color: Colors.green,
          category: AchievementCategory.special,
          targetValue: 80,
          coinsReward: 100,
          gemsReward: 15,
          xpReward: 500,
        ),
        const Achievement(
          id: 'early_bird',
          name: 'Early Bird',
          description: 'Complete a task before 7 AM',
          icon: Icons.wb_sunny,
          color: Colors.yellow,
          category: AchievementCategory.special,
          targetValue: 1,
          coinsReward: 15,
          xpReward: 50,
          isSecret: true,
        ),
        const Achievement(
          id: 'night_owl',
          name: 'Night Owl',
          description: 'Complete a task after 11 PM',
          icon: Icons.nightlight,
          color: Colors.indigo,
          category: AchievementCategory.special,
          targetValue: 1,
          coinsReward: 15,
          xpReward: 50,
          isSecret: true,
        ),
        const Achievement(
          id: 'perfect_week',
          name: 'Perfect Week',
          description: 'Complete at least 1 task every day for a week',
          icon: Icons.calendar_month,
          color: Colors.teal,
          category: AchievementCategory.special,
          targetValue: 7,
          coinsReward: 50,
          gemsReward: 5,
          xpReward: 200,
        ),
      ];

  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getByCategory(AchievementCategory category) {
    return allAchievements.where((a) => a.category == category).toList();
  }
}

/// User's progress towards an achievement
class UserAchievementProgress {
  final String achievementId;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool rewardsClaimed;

  const UserAchievementProgress({
    required this.achievementId,
    required this.currentProgress,
    this.isUnlocked = false,
    this.unlockedAt,
    this.rewardsClaimed = false,
  });

  factory UserAchievementProgress.fromMap(Map<String, dynamic> data) {
    return UserAchievementProgress(
      achievementId: data['achievementId'] ?? '',
      currentProgress: data['currentProgress'] ?? 0,
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt']?.toDate(),
      rewardsClaimed: data['rewardsClaimed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt,
      'rewardsClaimed': rewardsClaimed,
    };
  }

  UserAchievementProgress copyWith({
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? rewardsClaimed,
  }) {
    return UserAchievementProgress(
      achievementId: achievementId,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }

  double get progressPercentage {
    final achievement = Achievement.getById(achievementId);
    if (achievement == null) return 0;
    return (currentProgress / achievement.targetValue).clamp(0.0, 1.0);
  }
}
