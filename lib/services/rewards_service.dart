import 'package:check_bird/models/reward/task_completion_record.dart';
import 'package:check_bird/models/reward/user_rewards.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Comprehensive rewards service managing coins, gems, XP, and task completions
/// Prevents reward farming by tracking completion history
class RewardsService {
  static final RewardsService _instance = RewardsService._();
  factory RewardsService() => _instance;
  RewardsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _userRewardsRef =>
      _firestore.collection('userRewards');
  CollectionReference get _completionRecordsRef =>
      _firestore.collection('taskCompletions');

  /// Get user's current reward stats
  Future<UserRewards> getUserRewards(String userId) async {
    try {
      final doc = await _userRewardsRef.doc(userId).get();
      if (!doc.exists) {
        // Initialize new user
        final initial = UserRewards(userId: userId);
        await _userRewardsRef.doc(userId).set(initial.toFirestore());
        return initial;
      }
      return UserRewards.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user rewards: $e');
      return UserRewards(userId: userId);
    }
  }

  /// Stream of user rewards for real-time updates
  Stream<UserRewards> getUserRewardsStream(String userId) {
    return _userRewardsRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return UserRewards(userId: userId);
      }
      return UserRewards.fromFirestore(doc);
    });
  }

  /// Check if user can earn rewards for this task completion
  /// Returns true only if this is a NEW completion (not farming)
  Future<bool> canEarnRewardsForTask({
    required String userId,
    required String taskId,
    required TodoType taskType,
  }) async {
    try {
      // Don't award rewards if taskId is empty or invalid
      if (taskId.isEmpty) {
        debugPrint('Cannot award rewards: taskId is empty');
        return false;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // For habits: Check if completed today already
      if (taskType == TodoType.habit) {
        final todayStart = Timestamp.fromDate(today);
        final todayEnd = Timestamp.fromDate(today.add(const Duration(days: 1)));

        final existingCompletions = await _completionRecordsRef
            .where('userId', isEqualTo: userId)
            .where('taskId', isEqualTo: taskId)
            .where('isHabit', isEqualTo: true)
            .where('completedAt', isGreaterThanOrEqualTo: todayStart)
            .where('completedAt', isLessThan: todayEnd)
            .limit(1)
            .get();

        return existingCompletions.docs.isEmpty;
      }

      // For tasks: Check if this exact task was completed today
      // This prevents uncomplete/recomplete farming
      final todayStart = Timestamp.fromDate(today);
      final existingCompletions = await _completionRecordsRef
          .where('userId', isEqualTo: userId)
          .where('taskId', isEqualTo: taskId)
          .where('isHabit', isEqualTo: false)
          .where('completedAt', isGreaterThanOrEqualTo: todayStart)
          .limit(1)
          .get();

      return existingCompletions.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking reward eligibility: $e');
      return false; // Safe default: don't award if uncertain
    }
  }

  /// Award rewards for completing a task/habit
  /// Returns the rewards earned, or null if no rewards awarded
  Future<Map<String, int>?> awardTaskCompletionRewards({
    required String userId,
    required String taskId,
    required String taskName,
    required TodoType taskType,
    bool isGroupTask = false,
  }) async {
    try {
      // Check eligibility first
      final canEarn = await canEarnRewardsForTask(
        userId: userId,
        taskId: taskId,
        taskType: taskType,
      );

      if (!canEarn) {
        debugPrint(
            'User $userId already earned rewards for task $taskId today');
        return null;
      }

      // Calculate rewards based on task type
      int coinsEarned = 0;
      int xpEarned = 0;

      if (taskType == TodoType.habit) {
        coinsEarned = 2; // Habits earn more (they're daily)
        xpEarned = 15;
      } else {
        coinsEarned = 5; // Tasks earn more coins (one-time)
        xpEarned = 25;
      }

      // Bonus for group tasks
      if (isGroupTask) {
        coinsEarned += 2;
        xpEarned += 10;
      }

      // Use Firestore transaction for atomic updates
      await _firestore.runTransaction((transaction) async {
        final userRewardsDoc = _userRewardsRef.doc(userId);
        final snapshot = await transaction.get(userRewardsDoc);

        UserRewards current;
        if (!snapshot.exists) {
          current = UserRewards(userId: userId);
        } else {
          current = UserRewards.fromFirestore(snapshot);
        }

        // Calculate new values
        final newCoins = current.coins + coinsEarned;
        final newXp = current.xp + xpEarned;
        final newLevel = UserRewards.calculateLevel(newXp);
        final newTasksCompleted = taskType == TodoType.task
            ? current.totalTasksCompleted + 1
            : current.totalTasksCompleted;
        final newHabitsCompleted = taskType == TodoType.habit
            ? current.totalHabitsCompleted + 1
            : current.totalHabitsCompleted;

        // Update user rewards
        transaction.set(
            userRewardsDoc,
            {
              'coins': newCoins,
              'xp': newXp,
              'level': newLevel,
              'totalTasksCompleted': newTasksCompleted,
              'totalHabitsCompleted': newHabitsCompleted,
              'lastRewardEarnedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        // Record completion
        final completionRecord = TaskCompletionRecord(
          id: _completionRecordsRef.doc().id,
          userId: userId,
          taskId: taskId,
          taskName: taskName,
          completedAt: Timestamp.now(),
          coinsEarned: coinsEarned,
          xpEarned: xpEarned,
          isHabit: taskType == TodoType.habit,
        );

        transaction.set(
          _completionRecordsRef.doc(completionRecord.id),
          completionRecord.toFirestore(),
        );
      });

      debugPrint('Awarded $coinsEarned coins and $xpEarned XP to user $userId');
      return {'coins': coinsEarned, 'xp': xpEarned};
    } catch (e) {
      debugPrint('Error awarding task completion rewards: $e');
      return null;
    }
  }

  /// Spend coins (for shop purchases)
  /// Returns true if successful, false if insufficient funds
  Future<bool> spendCoins({
    required String userId,
    required int amount,
  }) async {
    if (amount <= 0) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final userRewardsDoc = _userRewardsRef.doc(userId);
        final snapshot = await transaction.get(userRewardsDoc);

        if (!snapshot.exists) {
          return false;
        }

        final current = UserRewards.fromFirestore(snapshot);
        if (current.coins < amount) {
          return false; // Insufficient funds
        }

        transaction.update(userRewardsDoc, {
          'coins': current.coins - amount,
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error spending coins: $e');
      return false;
    }
  }

  /// Spend gems (for charity packs)
  /// Returns true if successful, false if insufficient funds
  Future<bool> spendGems({
    required String userId,
    required int amount,
  }) async {
    if (amount <= 0) return false;

    try {
      return await _firestore.runTransaction((transaction) async {
        final userRewardsDoc = _userRewardsRef.doc(userId);
        final snapshot = await transaction.get(userRewardsDoc);

        if (!snapshot.exists) {
          return false;
        }

        final current = UserRewards.fromFirestore(snapshot);
        if (current.gems < amount) {
          return false; // Insufficient funds
        }

        transaction.update(userRewardsDoc, {
          'gems': current.gems - amount,
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error spending gems: $e');
      return false;
    }
  }

  /// Add coins (admin/bonus rewards)
  Future<void> addCoins({
    required String userId,
    required int amount,
  }) async {
    if (amount == 0) return;

    try {
      await _userRewardsRef.doc(userId).set({
        'coins': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding coins: $e');
    }
  }

  /// Add gems (admin/bonus rewards/purchases)
  Future<void> addGems({
    required String userId,
    required int amount,
  }) async {
    if (amount == 0) return;

    try {
      await _userRewardsRef.doc(userId).set({
        'gems': FieldValue.increment(amount),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding gems: $e');
    }
  }

  /// Check daily login and update streak
  Future<Map<String, dynamic>?> checkDailyLogin(String userId) async {
    try {
      final result = await _firestore.runTransaction((transaction) async {
        final userRewardsDoc = _userRewardsRef.doc(userId);
        final snapshot = await transaction.get(userRewardsDoc);

        UserRewards current;
        if (!snapshot.exists) {
          current = UserRewards(userId: userId);
        } else {
          current = UserRewards.fromFirestore(snapshot);
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastLogin = current.lastLoginDate?.toDate();
        final lastLoginDay = lastLogin != null
            ? DateTime(lastLogin.year, lastLogin.month, lastLogin.day)
            : null;

        // Check if already logged in today
        if (lastLoginDay != null && lastLoginDay.isAtSameDate(today)) {
          return null; // Already logged in today
        }

        // Check if streak continues (logged in yesterday)
        final yesterday = today.subtract(const Duration(days: 1));
        final streakContinues =
            lastLoginDay != null && lastLoginDay.isAtSameDate(yesterday);

        int newStreak = streakContinues ? current.currentLoginStreak + 1 : 1;
        int newLongestStreak = newStreak > current.longestLoginStreak
            ? newStreak
            : current.longestLoginStreak;

        // Daily login rewards (increasing with streak)
        int bonusCoins = 5 + (newStreak ~/ 7) * 5; // +5 coins per week
        int bonusXp = 10 + (newStreak ~/ 7) * 10; // +10 XP per week

        transaction.set(
            userRewardsDoc,
            {
              'lastLoginDate': Timestamp.fromDate(now),
              'currentLoginStreak': newStreak,
              'longestLoginStreak': newLongestStreak,
              'coins': FieldValue.increment(bonusCoins),
              'xp': FieldValue.increment(bonusXp),
            },
            SetOptions(merge: true));

        return {
          'streak': newStreak,
          'bonusCoins': bonusCoins,
          'bonusXp': bonusXp,
          'isNewStreak': !streakContinues,
        };
      });

      return result;
    } catch (e) {
      debugPrint('Error checking daily login: $e');
      return null;
    }
  }

  /// Get completion history for a user
  Future<List<TaskCompletionRecord>> getCompletionHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final query = await _completionRecordsRef
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => TaskCompletionRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting completion history: $e');
      return [];
    }
  }
}

extension DateTimeComparison on DateTime {
  bool isAtSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
