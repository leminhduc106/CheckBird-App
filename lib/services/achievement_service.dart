import 'package:check_bird/models/achievement/achievement.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for managing achievements
class AchievementService {
  static final AchievementService _instance = AchievementService._();
  factory AchievementService() => _instance;
  AchievementService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardsService _rewardsService = RewardsService();

  CollectionReference _userAchievementsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  /// Get all user achievement progress
  Future<Map<String, UserAchievementProgress>> getUserAchievements(
      String userId) async {
    try {
      final querySnapshot = await _userAchievementsRef(userId).get();
      final progressMap = <String, UserAchievementProgress>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['achievementId'] = doc.id;
        progressMap[doc.id] = UserAchievementProgress.fromMap(data);
      }

      // Initialize missing achievements with 0 progress
      for (final achievement in Achievement.allAchievements) {
        if (!progressMap.containsKey(achievement.id)) {
          progressMap[achievement.id] = UserAchievementProgress(
            achievementId: achievement.id,
            currentProgress: 0,
          );
        }
      }

      return progressMap;
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      return {};
    }
  }

  /// Stream user achievements for real-time updates
  Stream<Map<String, UserAchievementProgress>> getUserAchievementsStream(
      String userId) {
    return _userAchievementsRef(userId).snapshots().map((snapshot) {
      final progressMap = <String, UserAchievementProgress>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['achievementId'] = doc.id;
        progressMap[doc.id] = UserAchievementProgress.fromMap(data);
      }

      // Initialize missing achievements with 0 progress
      for (final achievement in Achievement.allAchievements) {
        if (!progressMap.containsKey(achievement.id)) {
          progressMap[achievement.id] = UserAchievementProgress(
            achievementId: achievement.id,
            currentProgress: 0,
          );
        }
      }

      return progressMap;
    });
  }

  /// Update achievement progress
  Future<List<Achievement>> updateProgress({
    required String userId,
    required String achievementId,
    required int newProgress,
  }) async {
    try {
      final achievement = Achievement.getById(achievementId);
      if (achievement == null) return [];

      final docRef = _userAchievementsRef(userId).doc(achievementId);
      final doc = await docRef.get();

      UserAchievementProgress currentProgress;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['achievementId'] = achievementId;
        currentProgress = UserAchievementProgress.fromMap(data);
      } else {
        currentProgress = UserAchievementProgress(
          achievementId: achievementId,
          currentProgress: 0,
        );
      }

      // Don't update if already unlocked
      if (currentProgress.isUnlocked) return [];

      final isNowUnlocked = newProgress >= achievement.targetValue;

      await docRef.set({
        'currentProgress': newProgress,
        'isUnlocked': isNowUnlocked,
        'unlockedAt': isNowUnlocked ? FieldValue.serverTimestamp() : null,
        'rewardsClaimed': false,
      });

      if (isNowUnlocked) {
        return [achievement];
      }

      return [];
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
      return [];
    }
  }

  /// Increment achievement progress by a value
  Future<List<Achievement>> incrementProgress({
    required String userId,
    required String achievementId,
    int incrementBy = 1,
  }) async {
    try {
      final docRef = _userAchievementsRef(userId).doc(achievementId);
      final doc = await docRef.get();

      int currentValue = 0;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isUnlocked'] == true) return [];
        currentValue = data['currentProgress'] ?? 0;
      }

      return await updateProgress(
        userId: userId,
        achievementId: achievementId,
        newProgress: currentValue + incrementBy,
      );
    } catch (e) {
      debugPrint('Error incrementing achievement progress: $e');
      return [];
    }
  }

  /// Check and update all task-related achievements
  Future<List<Achievement>> checkTaskAchievements({
    required String userId,
    required int totalTasksCompleted,
    required bool isGroupTask,
    required DateTime completedAt,
  }) async {
    final unlockedAchievements = <Achievement>[];

    // Task count achievements
    final taskAchievements = [
      ('first_task', 1),
      ('task_10', 10),
      ('task_50', 50),
      ('task_100', 100),
      ('task_500', 500),
      ('task_1000', 1000),
    ];

    for (final (id, target) in taskAchievements) {
      if (totalTasksCompleted >= target) {
        final unlocked = await updateProgress(
          userId: userId,
          achievementId: id,
          newProgress: totalTasksCompleted,
        );
        unlockedAchievements.addAll(unlocked);
      }
    }

    // Group task achievements
    if (isGroupTask) {
      final unlocked = await incrementProgress(
        userId: userId,
        achievementId: 'group_task_10',
      );
      unlockedAchievements.addAll(unlocked);

      final unlocked2 = await incrementProgress(
        userId: userId,
        achievementId: 'group_task_50',
      );
      unlockedAchievements.addAll(unlocked2);
    }

    // Time-based achievements
    final hour = completedAt.hour;
    if (hour < 7) {
      final unlocked = await updateProgress(
        userId: userId,
        achievementId: 'early_bird',
        newProgress: 1,
      );
      unlockedAchievements.addAll(unlocked);
    }
    if (hour >= 23) {
      final unlocked = await updateProgress(
        userId: userId,
        achievementId: 'night_owl',
        newProgress: 1,
      );
      unlockedAchievements.addAll(unlocked);
    }

    return unlockedAchievements;
  }

  /// Check and update all habit-related achievements
  Future<List<Achievement>> checkHabitAchievements({
    required String userId,
    required int totalHabitsCompleted,
  }) async {
    final unlockedAchievements = <Achievement>[];

    final habitAchievements = [
      ('first_habit', 1),
      ('habit_25', 25),
      ('habit_100', 100),
      ('habit_365', 365),
    ];

    for (final (id, target) in habitAchievements) {
      if (totalHabitsCompleted >= target) {
        final unlocked = await updateProgress(
          userId: userId,
          achievementId: id,
          newProgress: totalHabitsCompleted,
        );
        unlockedAchievements.addAll(unlocked);
      }
    }

    return unlockedAchievements;
  }

  /// Check and update streak achievements
  Future<List<Achievement>> checkStreakAchievements({
    required String userId,
    required int currentStreak,
  }) async {
    final unlockedAchievements = <Achievement>[];

    final streakAchievements = [
      ('streak_3', 3),
      ('streak_7', 7),
      ('streak_14', 14),
      ('streak_30', 30),
      ('streak_100', 100),
      ('streak_365', 365),
    ];

    for (final (id, target) in streakAchievements) {
      if (currentStreak >= target) {
        final unlocked = await updateProgress(
          userId: userId,
          achievementId: id,
          newProgress: currentStreak,
        );
        unlockedAchievements.addAll(unlocked);
      }
    }

    return unlockedAchievements;
  }

  /// Check level achievements
  Future<List<Achievement>> checkLevelAchievements({
    required String userId,
    required int level,
  }) async {
    final unlockedAchievements = <Achievement>[];

    final levelAchievements = [
      ('level_5', 5),
      ('level_10', 10),
      ('level_25', 25),
    ];

    for (final (id, target) in levelAchievements) {
      if (level >= target) {
        final unlocked = await updateProgress(
          userId: userId,
          achievementId: id,
          newProgress: level,
        );
        unlockedAchievements.addAll(unlocked);
      }
    }

    return unlockedAchievements;
  }

  /// Claim rewards for an unlocked achievement
  Future<bool> claimRewards({
    required String userId,
    required String achievementId,
  }) async {
    try {
      final achievement = Achievement.getById(achievementId);
      if (achievement == null) return false;

      final docRef = _userAchievementsRef(userId).doc(achievementId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      if (data['isUnlocked'] != true || data['rewardsClaimed'] == true) {
        return false;
      }

      // Award the rewards
      if (achievement.coinsReward > 0) {
        await _rewardsService.addCoins(
          userId: userId,
          amount: achievement.coinsReward,
        );
      }
      if (achievement.gemsReward > 0) {
        await _rewardsService.addGems(
          userId: userId,
          amount: achievement.gemsReward,
        );
      }
      if (achievement.xpReward > 0) {
        await _rewardsService.addXP(
          userId: userId,
          amount: achievement.xpReward,
        );
      }

      // Mark as claimed
      await docRef.update({'rewardsClaimed': true});

      return true;
    } catch (e) {
      debugPrint('Error claiming achievement rewards: $e');
      return false;
    }
  }

  /// Get count of unlocked achievements
  Future<int> getUnlockedCount(String userId) async {
    try {
      final querySnapshot = await _userAchievementsRef(userId)
          .where('isUnlocked', isEqualTo: true)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get unclaimed achievement rewards
  Future<List<Achievement>> getUnclaimedAchievements(String userId) async {
    try {
      final querySnapshot = await _userAchievementsRef(userId)
          .where('isUnlocked', isEqualTo: true)
          .where('rewardsClaimed', isEqualTo: false)
          .get();

      return querySnapshot.docs
          .map((doc) => Achievement.getById(doc.id))
          .whereType<Achievement>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
