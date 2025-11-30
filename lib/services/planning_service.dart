import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:check_bird/models/planning/daily_plan.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';
import 'package:check_bird/services/notification.dart';
import 'package:check_bird/services/rewards_service.dart';

/// Service for daily planning and time blocking
class PlanningService extends ChangeNotifier {
  static final PlanningService _instance = PlanningService._internal();
  factory PlanningService() => _instance;
  PlanningService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RewardsService _rewardsService = RewardsService();

  String? get _userId => _auth.currentUser?.uid;

  DailyPlan? _todaysPlan;
  List<DailyPlan> _recentPlans = [];
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Streak tracking
  int _eveningReviewStreak = 0;
  int _longestEveningReviewStreak = 0;
  DateTime? _lastEveningReviewDate;

  DailyPlan? get todaysPlan => _todaysPlan;
  List<DailyPlan> get recentPlans => _recentPlans;
  bool get hasTodaysPlan => _todaysPlan?.hasMorningPlan ?? false;
  bool get isInitialized => _isInitialized;
  int get eveningReviewStreak => _eveningReviewStreak;
  int get longestEveningReviewStreak => _longestEveningReviewStreak;
  DateTime? get lastEveningReviewDate => _lastEveningReviewDate;

  /// Initialize service
  Future<void> initialize() async {
    // Prevent multiple concurrent initializations
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      await _loadTodaysPlan();
      await _loadStreakData();
      // Load recent plans in background, don't block
      _loadRecentPlans();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error in PlanningService.initialize: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Load streak data from local storage
  Future<void> _loadStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _eveningReviewStreak = prefs.getInt('evening_review_streak') ?? 0;
      _longestEveningReviewStreak =
          prefs.getInt('longest_evening_review_streak') ?? 0;
      final lastDateStr = prefs.getString('last_evening_review_date');
      if (lastDateStr != null) {
        _lastEveningReviewDate = DateTime.tryParse(lastDateStr);
      }

      // Validate streak - check if it should be reset
      _validateStreak();
    } catch (e) {
      debugPrint('Error loading streak data: $e');
    }
  }

  /// Validate and possibly reset streak if days were missed
  void _validateStreak() {
    if (_lastEveningReviewDate == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReviewDay = DateTime(
      _lastEveningReviewDate!.year,
      _lastEveningReviewDate!.month,
      _lastEveningReviewDate!.day,
    );

    final daysSinceLastReview = today.difference(lastReviewDay).inDays;

    // If more than 1 day has passed without review, reset streak
    if (daysSinceLastReview > 1) {
      _eveningReviewStreak = 0;
      _saveStreakData();
    }
  }

  /// Save streak data to local storage
  Future<void> _saveStreakData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('evening_review_streak', _eveningReviewStreak);
      await prefs.setInt(
          'longest_evening_review_streak', _longestEveningReviewStreak);
      if (_lastEveningReviewDate != null) {
        await prefs.setString('last_evening_review_date',
            _lastEveningReviewDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving streak data: $e');
    }
  }

  /// Load today's plan
  Future<void> _loadTodaysPlan() async {
    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('daily_plan_$dateKey');

      if (jsonString != null) {
        _todaysPlan = DailyPlan.fromJson(json.decode(jsonString));
      } else {
        _todaysPlan = DailyPlan.createForToday();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading today\'s plan: $e');
      _todaysPlan = DailyPlan.createForToday();
    }
  }

  /// Save today's plan
  Future<void> _saveTodaysPlan() async {
    if (_todaysPlan == null) return;

    final dateKey = _getDateKey(_todaysPlan!.date);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'daily_plan_$dateKey', json.encode(_todaysPlan!.toJson()));

      // Sync to Firestore in background (don't await)
      if (_userId != null) {
        _firestore
            .collection('users')
            .doc(_userId)
            .collection('daily_plans')
            .doc(dateKey)
            .set(_todaysPlan!.toJson())
            .catchError((e) => debugPrint('Firestore sync error: $e'));
      }
    } catch (e) {
      debugPrint('Error saving today\'s plan: $e');
    }
  }

  /// Load recent plans (last 7 days)
  Future<void> _loadRecentPlans() async {
    _recentPlans = [];

    final today = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final date = today.subtract(Duration(days: i));
      final plan = await getPlanForDate(date);
      if (plan != null) {
        _recentPlans.add(plan);
      }
    }

    notifyListeners();
  }

  /// Get plan for specific date
  Future<DailyPlan?> getPlanForDate(DateTime date) async {
    final dateKey = _getDateKey(date);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('daily_plan_$dateKey');

      if (jsonString != null) {
        return DailyPlan.fromJson(json.decode(jsonString));
      }

      // Try Firestore
      if (_userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('daily_plans')
            .doc(dateKey)
            .get();

        if (doc.exists) {
          return DailyPlan.fromJson(doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('Error loading plan for date: $e');
    }

    return null;
  }

  /// Set morning intention
  Future<void> setMorningIntention(String intention) async {
    _todaysPlan = _todaysPlan?.copyWith(morningIntention: intention) ??
        DailyPlan.createForToday().copyWith(morningIntention: intention);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Set top priorities (max 3)
  Future<void> setTopPriorities(List<String> priorities) async {
    final limited = priorities.take(3).toList();
    _todaysPlan = _todaysPlan?.copyWith(topPriorities: limited) ??
        DailyPlan.createForToday().copyWith(topPriorities: limited);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Add a priority
  Future<void> addPriority(String priority) async {
    final current = _todaysPlan?.topPriorities ?? [];
    if (current.length < 3) {
      await setTopPriorities([...current, priority]);
    }
  }

  /// Remove a priority
  Future<void> removePriority(int index) async {
    final current = List<String>.from(_todaysPlan?.topPriorities ?? []);
    if (index < current.length) {
      current.removeAt(index);
      await setTopPriorities(current);
    }
  }

  /// Set energy level
  Future<void> setEnergyLevel(int level) async {
    _todaysPlan = _todaysPlan?.copyWith(energyLevel: level.clamp(1, 5)) ??
        DailyPlan.createForToday().copyWith(energyLevel: level.clamp(1, 5));
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Set focus area
  Future<void> setFocusArea(String? focusArea) async {
    _todaysPlan = _todaysPlan?.copyWith(focusArea: focusArea) ??
        DailyPlan.createForToday().copyWith(focusArea: focusArea);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Add time block
  Future<void> addTimeBlock(TimeBlock block) async {
    final blocks = List<TimeBlock>.from(_todaysPlan?.timeBlocks ?? []);
    blocks.add(block);

    // Sort by start time
    blocks.sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    _todaysPlan = _todaysPlan?.copyWith(timeBlocks: blocks) ??
        DailyPlan.createForToday().copyWith(timeBlocks: blocks);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Update time block
  Future<void> updateTimeBlock(String blockId, TimeBlock updatedBlock) async {
    final blocks = List<TimeBlock>.from(_todaysPlan?.timeBlocks ?? []);
    final index = blocks.indexWhere((b) => b.id == blockId);

    if (index != -1) {
      blocks[index] = updatedBlock;
      _todaysPlan = _todaysPlan?.copyWith(timeBlocks: blocks);
      await _saveTodaysPlan();
      notifyListeners();
    }
  }

  /// Remove time block
  Future<void> removeTimeBlock(String blockId) async {
    final blocks = List<TimeBlock>.from(_todaysPlan?.timeBlocks ?? []);
    blocks.removeWhere((b) => b.id == blockId);

    _todaysPlan = _todaysPlan?.copyWith(timeBlocks: blocks);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Complete time block
  Future<void> completeTimeBlock(String blockId) async {
    final blocks = List<TimeBlock>.from(_todaysPlan?.timeBlocks ?? []);
    final index = blocks.indexWhere((b) => b.id == blockId);

    if (index != -1) {
      blocks[index] = blocks[index].copyWith(completed: true);
      _todaysPlan = _todaysPlan?.copyWith(timeBlocks: blocks);
      await _saveTodaysPlan();
      notifyListeners();
    }
  }

  /// Add gratitude item
  Future<void> addGratitudeItem(String item) async {
    final items = List<String>.from(_todaysPlan?.gratitudeItems ?? []);
    items.add(item);

    _todaysPlan = _todaysPlan?.copyWith(gratitudeItems: items) ??
        DailyPlan.createForToday().copyWith(gratitudeItems: items);
    await _saveTodaysPlan();
    notifyListeners();
  }

  /// Set evening reflection and update streak
  /// Returns a map with reward info: {coins, xp, streak, isNewStreak, milestoneReached}
  Future<Map<String, dynamic>> setEveningReflection(
      String reflection, int rating) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isFirstReviewToday = !(_todaysPlan?.hasEveningReview ?? false);

    _todaysPlan = _todaysPlan?.copyWith(
          eveningReflection: reflection,
          dayRating: rating.clamp(1, 5),
          completed: true,
        ) ??
        DailyPlan.createForToday().copyWith(
          eveningReflection: reflection,
          dayRating: rating.clamp(1, 5),
          completed: true,
        );
    await _saveTodaysPlan();

    // Update streak tracking
    int coinsEarned = 0;
    int xpEarned = 0;
    bool isNewStreak = false;
    String? milestoneReached;

    if (isFirstReviewToday) {
      // Calculate if this continues or starts a new streak
      if (_lastEveningReviewDate != null) {
        final lastReviewDay = DateTime(
          _lastEveningReviewDate!.year,
          _lastEveningReviewDate!.month,
          _lastEveningReviewDate!.day,
        );
        final yesterday = today.subtract(const Duration(days: 1));

        if (lastReviewDay.isAtSameMomentAs(yesterday)) {
          // Streak continues!
          _eveningReviewStreak++;
        } else if (!lastReviewDay.isAtSameMomentAs(today)) {
          // Streak broken, starting new one
          _eveningReviewStreak = 1;
          isNewStreak = true;
        }
        // If same day, don't change streak (already reviewed today)
      } else {
        // First ever review
        _eveningReviewStreak = 1;
        isNewStreak = true;
      }

      _lastEveningReviewDate = now;

      // Update longest streak
      if (_eveningReviewStreak > _longestEveningReviewStreak) {
        _longestEveningReviewStreak = _eveningReviewStreak;
      }

      await _saveStreakData();

      // Calculate rewards
      coinsEarned = 3 + (_eveningReviewStreak ~/ 3); // +1 coin every 3 days
      xpEarned = 15 + (_eveningReviewStreak ~/ 2) * 5; // +5 XP every 2 days

      // Milestone bonuses
      final milestones = {
        3: 'streak_3',
        7: 'streak_7',
        14: 'streak_14',
        30: 'streak_30'
      };
      for (final entry in milestones.entries) {
        if (_eveningReviewStreak == entry.key) {
          milestoneReached = entry.value;
          coinsEarned += entry.key; // Bonus coins equal to streak number
          xpEarned += entry.key * 5; // Bonus XP
          break;
        }
      }

      // Award rewards through RewardsService
      if (_userId != null) {
        await _rewardsService.addCoins(userId: _userId!, amount: coinsEarned);
        await _rewardsService.addXP(userId: _userId!, amount: xpEarned);
      }
    }

    notifyListeners();

    return {
      'coins': coinsEarned,
      'xp': xpEarned,
      'streak': _eveningReviewStreak,
      'isNewStreak': isNewStreak,
      'milestoneReached': milestoneReached,
      'longestStreak': _longestEveningReviewStreak,
    };
  }

  /// Get suggested time blocks based on typical schedule
  List<TimeBlock> getSuggestedTimeBlocks() {
    final suggestions = <TimeBlock>[];
    final now = TimeOfDay.now();

    // Morning routine
    if (now.hour < 9) {
      suggestions.add(TimeBlock(
        id: 'suggest_morning',
        startTime: const TimeOfDay(hour: 7, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 0),
        title: 'Morning Routine',
        type: TimeBlockType.personal,
      ));
    }

    // Deep work block
    suggestions.add(TimeBlock(
      id: 'suggest_deepwork',
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
      title: 'Deep Work',
      type: TimeBlockType.focus,
    ));

    // Lunch
    suggestions.add(TimeBlock(
      id: 'suggest_lunch',
      startTime: const TimeOfDay(hour: 12, minute: 0),
      endTime: const TimeOfDay(hour: 13, minute: 0),
      title: 'Lunch Break',
      type: TimeBlockType.meal,
    ));

    // Afternoon work
    suggestions.add(TimeBlock(
      id: 'suggest_afternoon',
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
      title: 'Meetings & Tasks',
      type: TimeBlockType.work,
    ));

    // Exercise
    suggestions.add(TimeBlock(
      id: 'suggest_exercise',
      startTime: const TimeOfDay(hour: 17, minute: 0),
      endTime: const TimeOfDay(hour: 18, minute: 0),
      title: 'Exercise',
      type: TimeBlockType.exercise,
    ));

    return suggestions;
  }

  /// Get weekly stats
  Future<Map<String, dynamic>> getWeeklyStats() async {
    int totalPlanningDays = 0;
    int totalReviewDays = 0;
    double avgRating = 0;
    int totalTimeBlocks = 0;
    int completedTimeBlocks = 0;

    for (final plan in _recentPlans) {
      if (plan.hasMorningPlan) totalPlanningDays++;
      if (plan.hasEveningReview) {
        totalReviewDays++;
        avgRating += plan.dayRating;
      }
      totalTimeBlocks += plan.timeBlocks.length;
      completedTimeBlocks += plan.timeBlocks.where((b) => b.completed).length;
    }

    if (totalReviewDays > 0) {
      avgRating /= totalReviewDays;
    }

    return {
      'planningDays': totalPlanningDays,
      'reviewDays': totalReviewDays,
      'avgRating': avgRating,
      'totalTimeBlocks': totalTimeBlocks,
      'completedTimeBlocks': completedTimeBlocks,
      'completionRate': totalTimeBlocks > 0
          ? (completedTimeBlocks / totalTimeBlocks * 100).round()
          : 0,
    };
  }

  /// Get productivity insights
  List<String> getProductivityInsights() {
    final insights = <String>[];

    // Analyze morning plan completion
    final morningPlanRate = _recentPlans.isEmpty
        ? 0
        : _recentPlans.where((p) => p.hasMorningPlan).length /
            _recentPlans.length;

    if (morningPlanRate < 0.5) {
      insights.add(
          '💡 Try planning your day each morning - it can boost productivity by 25%!');
    }

    // Analyze energy levels
    final avgEnergy = _recentPlans.isEmpty
        ? 3.0
        : _recentPlans.map((p) => p.energyLevel).reduce((a, b) => a + b) /
            _recentPlans.length;

    if (avgEnergy < 3) {
      insights.add(
          '⚡ Your energy has been low. Consider more breaks and better sleep!');
    }

    // Analyze time block completion
    for (final plan in _recentPlans.take(3)) {
      final completion = plan.timeBlocks.isEmpty
          ? 1.0
          : plan.timeBlocks.where((b) => b.completed).length /
              plan.timeBlocks.length;

      if (completion < 0.5) {
        insights.add(
            '📊 Time block completion has been low. Try scheduling fewer, more focused blocks.');
        break;
      }
    }

    if (insights.isEmpty) {
      insights
          .add('🌟 Great job! You\'re maintaining excellent planning habits!');
    }

    return insights;
  }

  /// Create tasks from priorities
  Future<void> createTasksFromPriorities(List<String> priorities) async {
    final controller = TodoListController();

    // Ensure Hive box is open
    final boxReady = await controller.ensureBoxOpen();
    if (!boxReady) {
      debugPrint('PlanningService: Cannot create tasks - Hive not ready');
      return;
    }

    final today = DateTime.now();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59);

    for (final priority in priorities) {
      if (priority.trim().isEmpty) continue;

      final task = Todo.task(
        todoName: priority,
        todoDescription: 'Created from Daily Planning priorities',
        deadline: endOfDay,
        textColor: 0xFFFFFFFF,
        backgroundColor: 0xFF6750A4, // Primary color
      );

      await controller.addTodo(task);
    }

    debugPrint('Created ${priorities.length} tasks from priorities');
  }

  /// Schedule notifications for time blocks
  Future<void> scheduleTimeBlockNotifications() async {
    final plan = _todaysPlan;
    if (plan == null) return;

    final notificationService = NotificationService();
    final today = DateTime.now();

    for (final block in plan.timeBlocks) {
      // Create DateTime for the block start time
      final blockStart = DateTime(
        today.year,
        today.month,
        today.day,
        block.startTime.hour,
        block.startTime.minute,
      );

      // Only schedule if it's in the future
      if (blockStart.isAfter(today)) {
        final notificationId = 'timeblock_${block.id}'.hashCode.abs() % 100000;

        await notificationService.createScheduleNotification(
          notificationId,
          '⏰ Time Block Starting',
          '${block.title} - Time to focus!',
          blockStart,
          payload: 'timeblock:${block.id}',
        );

        debugPrint('Scheduled notification for ${block.title} at $blockStart');
      }
    }
  }

  /// Cancel all time block notifications
  Future<void> cancelTimeBlockNotifications() async {
    final plan = _todaysPlan;
    if (plan == null) return;

    final notificationService = NotificationService();

    for (final block in plan.timeBlocks) {
      final notificationId = 'timeblock_${block.id}'.hashCode.abs() % 100000;
      await notificationService.cancelScheduledNotifications(notificationId);
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get mood/rating data for the last N days (for trend visualization)
  /// Returns a list of {date, rating} maps, ordered oldest to newest
  List<Map<String, dynamic>> getMoodTrend({int days = 7}) {
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Include today's plan if it has a review
    if (_todaysPlan != null && _todaysPlan!.hasEveningReview) {
      trend.add({
        'date': _todaysPlan!.date,
        'rating': _todaysPlan!.dayRating,
        'hasReview': true,
      });
    } else {
      trend.add({
        'date': now,
        'rating': 0,
        'hasReview': false,
      });
    }

    // Add recent plans
    for (final plan in _recentPlans.take(days - 1)) {
      trend.add({
        'date': plan.date,
        'rating': plan.hasEveningReview ? plan.dayRating : 0,
        'hasReview': plan.hasEveningReview,
      });
    }

    // Sort oldest to newest
    trend.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return trend;
  }

  /// Get average mood for recent days (only counting days with reviews)
  double getAverageMood({int days = 7}) {
    final trend = getMoodTrend(days: days);
    final reviewedDays = trend.where((d) => d['hasReview'] == true).toList();

    if (reviewedDays.isEmpty) return 0;

    final sum =
        reviewedDays.fold<int>(0, (sum, d) => sum + (d['rating'] as int));
    return sum / reviewedDays.length;
  }

  /// Get a random gratitude item from recent reviews (for positivity boost)
  String? getRandomGratitudeItem() {
    final allGratitude = <String>[];

    // Add today's gratitude
    if (_todaysPlan != null) {
      allGratitude.addAll(_todaysPlan!.gratitudeItems);
    }

    // Add recent gratitude items
    for (final plan in _recentPlans.take(7)) {
      allGratitude.addAll(plan.gratitudeItems);
    }

    if (allGratitude.isEmpty) return null;

    // Return a random item
    allGratitude.shuffle();
    return allGratitude.first;
  }

  /// Get all gratitude items from recent reviews
  List<String> getRecentGratitudeItems({int limit = 10}) {
    final allGratitude = <String>[];

    if (_todaysPlan != null) {
      allGratitude.addAll(_todaysPlan!.gratitudeItems);
    }

    for (final plan in _recentPlans) {
      allGratitude.addAll(plan.gratitudeItems);
      if (allGratitude.length >= limit) break;
    }

    return allGratitude.take(limit).toList();
  }

  /// Get energy suggestion based on recent mood trends
  String? getEnergySuggestion() {
    final avgMood = getAverageMood(days: 5);

    if (avgMood == 0) return null; // No data

    if (avgMood <= 2) {
      return '💙 Your recent days have been tough. Consider lighter tasks and more self-care today.';
    } else if (avgMood <= 3) {
      return '💡 You\'ve been in a moderate zone. Mix some easy wins with your priorities today.';
    } else if (avgMood >= 4) {
      return '🔥 You\'ve been on a roll! Great time to tackle challenging goals.';
    }

    return null;
  }

  /// Check if there's notable mood improvement or decline
  String? getMoodTrendInsight() {
    final trend = getMoodTrend(days: 5);
    final reviewedDays = trend.where((d) => d['hasReview'] == true).toList();

    if (reviewedDays.length < 3) return null;

    // Compare first half average with second half average
    final halfPoint = reviewedDays.length ~/ 2;
    final firstHalf = reviewedDays.take(halfPoint);
    final secondHalf = reviewedDays.skip(halfPoint);

    final firstAvg =
        firstHalf.fold<int>(0, (sum, d) => sum + (d['rating'] as int)) /
            halfPoint;
    final secondAvg =
        secondHalf.fold<int>(0, (sum, d) => sum + (d['rating'] as int)) /
            (reviewedDays.length - halfPoint);

    if (secondAvg - firstAvg >= 1) {
      return '📈 Your mood is trending up! Keep doing what you\'re doing.';
    } else if (firstAvg - secondAvg >= 1) {
      return '📉 Your mood has dipped recently. What could help you feel better?';
    }

    return null;
  }
}
