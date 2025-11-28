import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:check_bird/models/mood/mood_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage mood tracking
class MoodService {
  static final MoodService _instance = MoodService._internal();
  factory MoodService() => _instance;
  MoodService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Cache
  final Map<String, MoodEntry> _entriesCache = {};
  final _moodController = StreamController<List<MoodEntry>>.broadcast();
  Stream<List<MoodEntry>> get moodStream => _moodController.stream;

  /// Initialize and load cached entries
  Future<void> initialize() async {
    await _loadFromLocal();
    if (_userId != null) {
      await _syncFromFirestore();
    }
  }

  /// Load entries from local storage
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('mood_entries');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _entriesCache.clear();
        for (final item in jsonList) {
          final entry = MoodEntry.fromJson(item);
          _entriesCache[entry.id] = entry;
        }
        _notifyListeners();
      }
    } catch (e) {
      print('Error loading mood entries from local: $e');
    }
  }

  /// Save entries to local storage
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _entriesCache.values.map((e) => e.toJson()).toList();
      await prefs.setString('mood_entries', json.encode(jsonList));
    } catch (e) {
      print('Error saving mood entries to local: $e');
    }
  }

  /// Sync entries from Firestore
  Future<void> _syncFromFirestore() async {
    if (_userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('mood_entries')
          .orderBy('date', descending: true)
          .limit(90) // Last 90 days
          .get();

      for (final doc in snapshot.docs) {
        final entry = MoodEntry.fromJson(doc.data());
        _entriesCache[entry.id] = entry;
      }
      _notifyListeners();
      await _saveToLocal();
    } catch (e) {
      print('Error syncing mood entries from Firestore: $e');
    }
  }

  void _notifyListeners() {
    final entries = _entriesCache.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _moodController.add(entries);
  }

  /// Get today's mood entry if exists
  MoodEntry? getTodayEntry() {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);

    return _entriesCache.values.cast<MoodEntry?>().firstWhere(
          (e) => e != null && _getDateKey(e.date) == todayKey,
          orElse: () => null,
        );
  }

  /// Check if mood was logged today
  bool hasLoggedToday() {
    return getTodayEntry() != null;
  }

  /// Log mood for today
  Future<MoodEntry> logMood({
    required MoodLevel mood,
    required EnergyLevel energy,
    String? note,
    List<String> factors = const [],
  }) async {
    final now = DateTime.now();
    final id = _getDateKey(now);

    // Get productivity stats for today
    final tasksCompleted = await _getTodayTasksCompleted();
    final habitsCompleted = await _getTodayHabitsCompleted();
    final focusMinutes = await _getTodayFocusMinutes();

    final entry = MoodEntry(
      id: id,
      date: now,
      mood: mood,
      energy: energy,
      note: note,
      factors: factors,
      tasksCompleted: tasksCompleted,
      habitsCompleted: habitsCompleted,
      focusMinutes: focusMinutes,
    );

    _entriesCache[id] = entry;
    _notifyListeners();
    await _saveToLocal();
    await _saveToFirestore(entry);

    return entry;
  }

  /// Update today's mood entry
  Future<MoodEntry?> updateTodayMood({
    MoodLevel? mood,
    EnergyLevel? energy,
    String? note,
    List<String>? factors,
  }) async {
    final todayEntry = getTodayEntry();
    if (todayEntry == null) return null;

    final updatedEntry = todayEntry.copyWith(
      mood: mood,
      energy: energy,
      note: note,
      factors: factors,
    );

    _entriesCache[updatedEntry.id] = updatedEntry;
    _notifyListeners();
    await _saveToLocal();
    await _saveToFirestore(updatedEntry);

    return updatedEntry;
  }

  /// Save entry to Firestore
  Future<void> _saveToFirestore(MoodEntry entry) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('mood_entries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      print('Error saving mood entry to Firestore: $e');
    }
  }

  /// Get entries for a date range
  List<MoodEntry> getEntriesForRange(DateTime start, DateTime end) {
    return _entriesCache.values
        .where((e) =>
            e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get entries for the last N days
  List<MoodEntry> getLastNDays(int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - days);
    return getEntriesForRange(start, now);
  }

  /// Get weekly summary
  MoodWeeklySummary getWeeklySummary({DateTime? weekStart}) {
    final start = weekStart ?? _getWeekStart(DateTime.now());
    final end = start.add(const Duration(days: 7));
    final entries = getEntriesForRange(start, end);

    if (entries.isEmpty) {
      return MoodWeeklySummary(
        weekStart: start,
        averageMood: 0,
        averageEnergy: 0,
        totalEntries: 0,
        factorFrequency: {},
        totalTasksCompleted: 0,
        totalHabitsCompleted: 0,
        totalFocusMinutes: 0,
      );
    }

    final avgMood = entries.map((e) => e.mood.value).reduce((a, b) => a + b) /
        entries.length;
    final avgEnergy =
        entries.map((e) => e.energy.value).reduce((a, b) => a + b) /
            entries.length;

    final factorFreq = <String, int>{};
    for (final entry in entries) {
      for (final factor in entry.factors) {
        factorFreq[factor] = (factorFreq[factor] ?? 0) + 1;
      }
    }

    return MoodWeeklySummary(
      weekStart: start,
      averageMood: avgMood,
      averageEnergy: avgEnergy,
      totalEntries: entries.length,
      factorFrequency: factorFreq,
      totalTasksCompleted:
          entries.map((e) => e.tasksCompleted).fold(0, (a, b) => a + b),
      totalHabitsCompleted:
          entries.map((e) => e.habitsCompleted).fold(0, (a, b) => a + b),
      totalFocusMinutes:
          entries.map((e) => e.focusMinutes).fold(0, (a, b) => a + b),
    );
  }

  /// Get mood-productivity correlation insights
  List<String> getMoodInsights() {
    final entries = getLastNDays(30);
    if (entries.length < 7) {
      return ['Log your mood for at least 7 days to see insights!'];
    }

    final insights = <String>[];

    // Average mood
    final avgMood = entries.map((e) => e.mood.value).reduce((a, b) => a + b) /
        entries.length;
    if (avgMood >= 4) {
      insights.add(
          '🌟 Your average mood this month is ${avgMood.toStringAsFixed(1)}/5 - Keep it up!');
    } else if (avgMood < 3) {
      insights.add(
          '💙 Your average mood is ${avgMood.toStringAsFixed(1)}/5 - Consider focusing on self-care');
    }

    // Mood-productivity correlation
    final highMoodEntries = entries.where((e) => e.mood.value >= 4).toList();
    final lowMoodEntries = entries.where((e) => e.mood.value <= 2).toList();

    if (highMoodEntries.isNotEmpty && lowMoodEntries.isNotEmpty) {
      final highMoodTasks = highMoodEntries
              .map((e) => e.tasksCompleted)
              .fold(0, (a, b) => a + b) /
          highMoodEntries.length;
      final lowMoodTasks =
          lowMoodEntries.map((e) => e.tasksCompleted).fold(0, (a, b) => a + b) /
              lowMoodEntries.length;

      if (highMoodTasks > lowMoodTasks * 1.3) {
        insights.add(
            '📈 You complete ${((highMoodTasks / lowMoodTasks - 1) * 100).round()}% more tasks on good mood days!');
      }
    }

    // Factor correlations
    final allFactors = <String, List<int>>{};
    for (final entry in entries) {
      for (final factor in entry.factors) {
        allFactors.putIfAbsent(factor, () => []);
        allFactors[factor]!.add(entry.mood.value);
      }
    }

    // Find best factors for mood
    final factorAvgMood = allFactors
        .map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final sortedFactors = factorAvgMood.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedFactors.isNotEmpty) {
      final bestFactor = MoodFactor.getById(sortedFactors.first.key);
      if (bestFactor != null && bestFactor.isPositive) {
        insights.add(
            '${bestFactor.emoji} ${bestFactor.label} is associated with your best moods!');
      }
    }

    // Energy insights
    final avgEnergy =
        entries.map((e) => e.energy.value).reduce((a, b) => a + b) /
            entries.length;
    if (avgEnergy < 3) {
      insights.add('⚡ Your energy levels have been low - try to get more rest');
    }

    return insights.isEmpty
        ? ['Keep logging to unlock personalized insights!']
        : insights;
  }

  /// Get mood streak (consecutive days of logging)
  int getMoodLogStreak() {
    final entries = _entriesCache.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final entry in entries) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      final expectedDate =
          DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (entryDate == expectedDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (entryDate.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }

  // Helper methods
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - weekday + 1);
  }

  // TODO: Integrate with actual task/habit/focus services
  Future<int> _getTodayTasksCompleted() async {
    // This would integrate with the actual task service
    return 0;
  }

  Future<int> _getTodayHabitsCompleted() async {
    // This would integrate with the actual habit service
    return 0;
  }

  Future<int> _getTodayFocusMinutes() async {
    // This would integrate with the focus timer service
    return 0;
  }

  void dispose() {
    _moodController.close();
  }
}
