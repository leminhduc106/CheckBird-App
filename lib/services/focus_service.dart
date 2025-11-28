import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:check_bird/models/focus/focus_session.dart';

/// Service to manage focus sessions (Pomodoro technique)
class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // State
  FocusSession? _currentSession;
  FocusSettings _settings = const FocusSettings();
  FocusStats _todayStats = FocusStats(date: DateTime.now());
  int _completedSessionsToday = 0;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  // Getters
  FocusSession? get currentSession => _currentSession;
  FocusSettings get settings => _settings;
  FocusStats get todayStats => _todayStats;
  Duration get remainingTime => _remainingTime;
  bool get isRunning => _timer != null && _currentSession != null;
  int get completedSessionsToday => _completedSessionsToday;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadTodayStats();
  }

  /// Load settings from local storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('focus_settings');
      if (jsonString != null) {
        _settings = FocusSettings.fromJson(json.decode(jsonString));
      }
    } catch (e) {
      debugPrint('Error loading focus settings: $e');
    }
  }

  /// Save settings to local storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('focus_settings', json.encode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving focus settings: $e');
    }
  }

  /// Update settings
  Future<void> updateSettings(FocusSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// Load today's stats
  Future<void> _loadTodayStats() async {
    final today = DateTime.now();
    final dateKey = _getDateKey(today);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('focus_stats_$dateKey');
      if (jsonString != null) {
        _todayStats = FocusStats.fromJson(json.decode(jsonString));
        _completedSessionsToday = _todayStats.pomodorosCompleted;
      } else {
        _todayStats = FocusStats(date: today);
        _completedSessionsToday = 0;
      }
    } catch (e) {
      debugPrint('Error loading today stats: $e');
      _todayStats = FocusStats(date: today);
    }

    notifyListeners();
  }

  /// Save today's stats
  Future<void> _saveTodayStats() async {
    final dateKey = _getDateKey(_todayStats.date);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'focus_stats_$dateKey', json.encode(_todayStats.toJson()));

      // Also sync to Firestore
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('focus_stats')
            .doc(dateKey)
            .set(_todayStats.toJson());
      }
    } catch (e) {
      debugPrint('Error saving today stats: $e');
    }
  }

  /// Start a focus session
  void startFocusSession({String? taskId, String? taskName}) {
    _startSession(
      type: SessionType.focus,
      minutes: _settings.focusDuration,
      taskId: taskId,
      taskName: taskName,
    );
  }

  /// Start a short break
  void startShortBreak() {
    _startSession(
      type: SessionType.shortBreak,
      minutes: _settings.shortBreakDuration,
    );
  }

  /// Start a long break
  void startLongBreak() {
    _startSession(
      type: SessionType.longBreak,
      minutes: _settings.longBreakDuration,
    );
  }

  void _startSession({
    required SessionType type,
    required int minutes,
    String? taskId,
    String? taskName,
  }) {
    // Cancel any existing session
    _timer?.cancel();

    final session = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      type: type,
      plannedMinutes: minutes,
      taskId: taskId,
      taskName: taskName,
    );

    _currentSession = session;
    _remainingTime = Duration(minutes: minutes);

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);

    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_remainingTime.inSeconds <= 0) {
      _completeSession();
      return;
    }

    _remainingTime -= const Duration(seconds: 1);
    notifyListeners();
  }

  /// Complete current session
  Future<void> _completeSession() async {
    _timer?.cancel();
    _timer = null;

    if (_currentSession == null) return;

    final completedSession = _currentSession!.copyWith(
      endTime: DateTime.now(),
      actualMinutes: _currentSession!.plannedMinutes,
      completed: true,
    );

    // Update stats
    if (completedSession.type == SessionType.focus) {
      _completedSessionsToday++;
      _todayStats = _todayStats.copyWith(
        totalFocusMinutes:
            _todayStats.totalFocusMinutes + completedSession.plannedMinutes,
        sessionsCompleted: _todayStats.sessionsCompleted + 1,
        pomodorosCompleted: _completedSessionsToday,
        totalXpEarned: _todayStats.totalXpEarned + completedSession.xpReward,
        totalCoinsEarned:
            _todayStats.totalCoinsEarned + completedSession.coinReward,
      );
      await _saveTodayStats();
      await _saveSessionToFirestore(completedSession);
    }

    _currentSession = null;
    _remainingTime = Duration.zero;

    notifyListeners();
  }

  /// Pause current session (actually stops it)
  void pauseSession() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Resume paused session
  void resumeSession() {
    if (_currentSession != null && _remainingTime.inSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
      notifyListeners();
    }
  }

  /// Cancel current session (give up)
  Future<void> cancelSession() async {
    _timer?.cancel();
    _timer = null;

    if (_currentSession != null && _currentSession!.type == SessionType.focus) {
      final actualMinutes =
          _currentSession!.plannedMinutes - (_remainingTime.inMinutes);

      final interruptedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        actualMinutes: actualMinutes,
        interrupted: true,
      );

      // Still count partial focus time
      if (actualMinutes > 0) {
        _todayStats = _todayStats.copyWith(
          totalFocusMinutes: _todayStats.totalFocusMinutes + actualMinutes,
          sessionsInterrupted: _todayStats.sessionsInterrupted + 1,
        );
        await _saveTodayStats();
      }

      await _saveSessionToFirestore(interruptedSession);
    }

    _currentSession = null;
    _remainingTime = Duration.zero;
    notifyListeners();
  }

  /// Add extra time to current session
  void addExtraTime(int minutes) {
    if (_currentSession != null) {
      _remainingTime += Duration(minutes: minutes);
      notifyListeners();
    }
  }

  /// Get the next session type based on completed pomodoros
  SessionType getNextSessionType() {
    if (_currentSession?.type == SessionType.focus) {
      // After focus, take a break
      if (_completedSessionsToday > 0 &&
          _completedSessionsToday % _settings.sessionsBeforeLongBreak == 0) {
        return SessionType.longBreak;
      }
      return SessionType.shortBreak;
    }
    return SessionType.focus;
  }

  /// Save session to Firestore
  Future<void> _saveSessionToFirestore(FocusSession session) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('focus_sessions')
          .doc(session.id)
          .set(session.toJson());
    } catch (e) {
      debugPrint('Error saving focus session: $e');
    }
  }

  /// Get focus history for date range
  Future<List<FocusSession>> getSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (_userId == null) return [];

    try {
      var query = _firestore
          .collection('users')
          .doc(_userId)
          .collection('focus_sessions')
          .orderBy('startTime', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('startTime',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('startTime',
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FocusSession.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting session history: $e');
      return [];
    }
  }

  /// Get focus stats for a specific date
  Future<FocusStats?> getStatsForDate(DateTime date) async {
    final dateKey = _getDateKey(date);

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('focus_stats_$dateKey');
      if (jsonString != null) {
        return FocusStats.fromJson(json.decode(jsonString));
      }

      // Try Firestore
      if (_userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('focus_stats')
            .doc(dateKey)
            .get();

        if (doc.exists) {
          return FocusStats.fromJson(doc.data()!);
        }
      }
    } catch (e) {
      debugPrint('Error getting stats for date: $e');
    }

    return null;
  }

  /// Get weekly focus summary
  Future<Map<String, int>> getWeeklyFocusMinutes() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final result = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final stats = await getStatsForDate(date);
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
      result[dayName] = stats?.totalFocusMinutes ?? 0;
    }

    return result;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
