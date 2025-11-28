import 'package:check_bird/models/quest/weekly_quest.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Service for managing weekly quests
class QuestService {
  static final QuestService _instance = QuestService._();
  factory QuestService() => _instance;
  QuestService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardsService _rewardsService = RewardsService();

  CollectionReference _userQuestsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('quests');

  /// Get the start of the current week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// Get current week's quests
  Future<List<WeeklyQuest>> getCurrentQuests() async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    return WeeklyQuest.generateQuestsForWeek(weekStart);
  }

  /// Get user's progress on current quests
  Future<Map<String, QuestProgress>> getUserQuestProgress(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';

      final doc = await _userQuestsRef(userId).doc(weekKey).get();

      if (!doc.exists) {
        return {};
      }

      final data = doc.data() as Map<String, dynamic>;
      final progressMap = <String, QuestProgress>{};

      for (final entry
          in (data['quests'] as Map<String, dynamic>? ?? {}).entries) {
        progressMap[entry.key] = QuestProgress.fromMap(entry.value);
      }

      return progressMap;
    } catch (e) {
      debugPrint('Error getting quest progress: $e');
      return {};
    }
  }

  /// Stream user's quest progress
  Stream<Map<String, QuestProgress>> getUserQuestProgressStream(String userId) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';

    return _userQuestsRef(userId).doc(weekKey).snapshots().map((doc) {
      if (!doc.exists) {
        return <String, QuestProgress>{};
      }

      final data = doc.data() as Map<String, dynamic>;
      final progressMap = <String, QuestProgress>{};

      for (final entry
          in (data['quests'] as Map<String, dynamic>? ?? {}).entries) {
        progressMap[entry.key] = QuestProgress.fromMap(entry.value);
      }

      return progressMap;
    });
  }

  /// Update quest progress
  Future<bool> updateQuestProgress({
    required String userId,
    required QuestType questType,
    int incrementBy = 1,
  }) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      final quests = await getCurrentQuests();

      // Find quests that match this type
      final matchingQuests = quests.where((q) => q.type == questType).toList();
      if (matchingQuests.isEmpty) return false;

      final docRef = _userQuestsRef(userId).doc(weekKey);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Map<String, dynamic> questsData = {};
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          questsData = Map<String, dynamic>.from(data['quests'] ?? {});
        }

        for (final quest in matchingQuests) {
          final currentData = questsData[quest.id] as Map<String, dynamic>?;
          final currentProgress = currentData?['currentProgress'] ?? 0;
          final isAlreadyCompleted = currentData?['isCompleted'] ?? false;

          if (isAlreadyCompleted) continue;

          final newProgress = currentProgress + incrementBy;
          final isNowCompleted = newProgress >= quest.targetValue;

          questsData[quest.id] = {
            'questId': quest.id,
            'currentProgress': newProgress,
            'isCompleted': isNowCompleted,
            'completedAt': isNowCompleted ? FieldValue.serverTimestamp() : null,
            'rewardsClaimed': false,
          };
        }

        transaction.set(
            docRef,
            {
              'weekKey': weekKey,
              'weekStart': weekStart.toIso8601String(),
              'quests': questsData,
            },
            SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
      return false;
    }
  }

  /// Record task completion for quest tracking
  Future<void> recordTaskCompletion({
    required String userId,
    required bool isHabit,
    required bool isGroupTask,
    required DateTime completedAt,
  }) async {
    // Update task/habit quests
    if (isHabit) {
      await updateQuestProgress(
        userId: userId,
        questType: QuestType.completeHabits,
      );
    } else {
      await updateQuestProgress(
        userId: userId,
        questType: QuestType.completeTasks,
      );
    }

    // Update group task quests
    if (isGroupTask) {
      await updateQuestProgress(
        userId: userId,
        questType: QuestType.groupTasks,
      );
    }

    // Check for early bird quest
    if (completedAt.hour < 8) {
      await updateQuestProgress(
        userId: userId,
        questType: QuestType.earlyBird,
      );
    }

    // Check for night owl quest
    if (completedAt.hour >= 22) {
      await updateQuestProgress(
        userId: userId,
        questType: QuestType.nightOwl,
      );
    }

    // Update perfect day tracking
    await _updatePerfectDayProgress(userId, completedAt);
  }

  /// Update perfect day progress (at least 1 task per day)
  Future<void> _updatePerfectDayProgress(String userId, DateTime date) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      final dayKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final docRef = _userQuestsRef(userId).doc(weekKey);
      final doc = await docRef.get();

      Set<String> completedDays = {};
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final daysData = data['perfectDays'] as List<dynamic>? ?? [];
        completedDays = daysData.map((d) => d.toString()).toSet();
      }

      if (!completedDays.contains(dayKey)) {
        completedDays.add(dayKey);

        // Update the document with the new day
        await docRef.set({
          'perfectDays': completedDays.toList(),
        }, SetOptions(merge: true));

        // Update perfect day quests
        final currentQuests = await getCurrentQuests();
        final perfectDayQuests =
            currentQuests.where((q) => q.type == QuestType.perfectDay).toList();

        for (final quest in perfectDayQuests) {
          await _firestore.runTransaction((transaction) async {
            final freshDoc = await transaction.get(docRef);
            final data = freshDoc.data() as Map<String, dynamic>? ?? {};
            final questsData = Map<String, dynamic>.from(data['quests'] ?? {});

            final currentData = questsData[quest.id] as Map<String, dynamic>?;
            final isAlreadyCompleted = currentData?['isCompleted'] ?? false;

            if (!isAlreadyCompleted) {
              final newProgress = completedDays.length;
              final isNowCompleted = newProgress >= quest.targetValue;

              questsData[quest.id] = {
                'questId': quest.id,
                'currentProgress': newProgress,
                'isCompleted': isNowCompleted,
                'completedAt':
                    isNowCompleted ? FieldValue.serverTimestamp() : null,
                'rewardsClaimed': false,
              };

              transaction.update(docRef, {'quests': questsData});
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating perfect day progress: $e');
    }
  }

  /// Record login for streak quests
  Future<void> recordLogin({
    required String userId,
    required int currentStreak,
  }) async {
    await updateQuestProgress(
      userId: userId,
      questType: QuestType.loginStreak,
      incrementBy: 0, // We'll handle streak differently
    );

    // Update login streak quest directly with current streak value
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      final quests = await getCurrentQuests();
      final streakQuests =
          quests.where((q) => q.type == QuestType.loginStreak).toList();

      if (streakQuests.isEmpty) return;

      final docRef = _userQuestsRef(userId).doc(weekKey);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Map<String, dynamic> questsData = {};
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          questsData = Map<String, dynamic>.from(data['quests'] ?? {});
        }

        for (final quest in streakQuests) {
          final currentData = questsData[quest.id] as Map<String, dynamic>?;
          final isAlreadyCompleted = currentData?['isCompleted'] ?? false;

          if (!isAlreadyCompleted) {
            final isNowCompleted = currentStreak >= quest.targetValue;

            questsData[quest.id] = {
              'questId': quest.id,
              'currentProgress': currentStreak.clamp(0, quest.targetValue),
              'isCompleted': isNowCompleted,
              'completedAt':
                  isNowCompleted ? FieldValue.serverTimestamp() : null,
              'rewardsClaimed': false,
            };
          }
        }

        transaction.set(
            docRef,
            {
              'weekKey': weekKey,
              'weekStart': weekStart.toIso8601String(),
              'quests': questsData,
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error recording login for quests: $e');
    }
  }

  /// Claim rewards for a completed quest
  Future<bool> claimQuestRewards({
    required String userId,
    required String questId,
  }) async {
    try {
      final quests = await getCurrentQuests();
      final quest = quests.firstWhere(
        (q) => q.id == questId,
        orElse: () => throw Exception('Quest not found'),
      );

      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekKey = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
      final docRef = _userQuestsRef(userId).doc(weekKey);

      final doc = await docRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final questsData = data['quests'] as Map<String, dynamic>? ?? {};
      final questProgress = questsData[questId] as Map<String, dynamic>?;

      if (questProgress == null ||
          questProgress['isCompleted'] != true ||
          questProgress['rewardsClaimed'] == true) {
        return false;
      }

      // Award rewards
      if (quest.coinsReward > 0) {
        await _rewardsService.addCoins(
          userId: userId,
          amount: quest.coinsReward,
        );
      }
      if (quest.gemsReward > 0) {
        await _rewardsService.addGems(
          userId: userId,
          amount: quest.gemsReward,
        );
      }
      if (quest.xpReward > 0) {
        await _rewardsService.addXP(
          userId: userId,
          amount: quest.xpReward,
        );
      }

      // Mark as claimed
      await docRef.update({
        'quests.$questId.rewardsClaimed': true,
      });

      return true;
    } catch (e) {
      debugPrint('Error claiming quest rewards: $e');
      return false;
    }
  }

  /// Get time remaining until quests reset
  Duration getTimeUntilReset() {
    final now = DateTime.now();
    final nextMonday = _getWeekStart(now.add(const Duration(days: 7)));
    return nextMonday.difference(now);
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(startOfYear).inDays;
    return (daysDiff / 7).ceil() + 1;
  }
}
