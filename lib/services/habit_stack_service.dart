import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:check_bird/models/habits/habit_stack.dart';

/// Service for managing habit stacks
class HabitStackService extends ChangeNotifier {
  static final HabitStackService _instance = HabitStackService._internal();
  factory HabitStackService() => _instance;
  HabitStackService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  List<HabitStack> _stacks = [];
  List<HabitStack> get stacks => _stacks;
  List<HabitStack> get activeStacks =>
      _stacks.where((s) => s.isActive).toList();

  /// Initialize service
  Future<void> initialize() async {
    await _loadStacks();
  }

  /// Load stacks from storage
  Future<void> _loadStacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('habit_stacks');

      if (jsonString != null) {
        final List<dynamic> list = json.decode(jsonString);
        _stacks = list.map((s) => HabitStack.fromJson(s)).toList();
      }

      // Reset today's completions for new day
      await _resetDailyProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading habit stacks: $e');
    }
  }

  /// Save stacks to storage
  Future<void> _saveStacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _stacks.map((s) => s.toJson()).toList();
      await prefs.setString('habit_stacks', json.encode(jsonList));

      // Sync to Firestore
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).set({
          'habitStacks': jsonList,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving habit stacks: $e');
    }
  }

  /// Reset daily progress if new day
  Future<void> _resetDailyProgress() async {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString('habit_stack_last_reset');

    if (lastResetDate != todayKey) {
      // New day - reset all habit completions
      _stacks = _stacks.map((stack) {
        final resetHabits = stack.habits
            .map((h) => h.copyWith(
                  completed: false,
                  completedAt: null,
                ))
            .toList();
        return stack.copyWith(habits: resetHabits);
      }).toList();

      await prefs.setString('habit_stack_last_reset', todayKey);
      await _saveStacks();
    }
  }

  /// Create a new stack
  Future<HabitStack> createStack({
    required String name,
    String? description,
    TriggerType triggerType = TriggerType.time,
    TimeOfDay? scheduledTime,
    String? triggerEvent,
  }) async {
    final stack = HabitStack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      triggerType: triggerType,
      scheduledTime: scheduledTime,
      triggerEvent: triggerEvent,
      createdAt: DateTime.now(),
    );

    _stacks.add(stack);
    await _saveStacks();
    notifyListeners();
    return stack;
  }

  /// Create stack from template
  Future<HabitStack> createFromTemplate(HabitStackTemplate template) async {
    final stack = template.toHabitStack();
    _stacks.add(stack);
    await _saveStacks();
    notifyListeners();
    return stack;
  }

  /// Update a stack
  Future<void> updateStack(HabitStack updatedStack) async {
    final index = _stacks.indexWhere((s) => s.id == updatedStack.id);
    if (index != -1) {
      _stacks[index] = updatedStack;
      await _saveStacks();
      notifyListeners();
    }
  }

  /// Delete a stack
  Future<void> deleteStack(String stackId) async {
    _stacks.removeWhere((s) => s.id == stackId);
    await _saveStacks();
    notifyListeners();
  }

  /// Add habit to stack
  Future<void> addHabitToStack({
    required String stackId,
    required String name,
    String? description,
    String? emoji,
    Duration estimatedDuration = const Duration(minutes: 5),
  }) async {
    final stackIndex = _stacks.indexWhere((s) => s.id == stackId);
    if (stackIndex == -1) return;

    final stack = _stacks[stackIndex];
    final newHabit = StackedHabit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      emoji: emoji,
      orderIndex: stack.habits.length,
      estimatedDuration: estimatedDuration,
    );

    final updatedHabits = List<StackedHabit>.from(stack.habits)..add(newHabit);
    _stacks[stackIndex] = stack.copyWith(habits: updatedHabits);
    await _saveStacks();
    notifyListeners();
  }

  /// Remove habit from stack
  Future<void> removeHabitFromStack({
    required String stackId,
    required String habitId,
  }) async {
    final stackIndex = _stacks.indexWhere((s) => s.id == stackId);
    if (stackIndex == -1) return;

    final stack = _stacks[stackIndex];
    final updatedHabits = List<StackedHabit>.from(stack.habits)
      ..removeWhere((h) => h.id == habitId);

    // Re-index remaining habits
    for (int i = 0; i < updatedHabits.length; i++) {
      updatedHabits[i] = updatedHabits[i].copyWith(orderIndex: i);
    }

    _stacks[stackIndex] = stack.copyWith(habits: updatedHabits);
    await _saveStacks();
    notifyListeners();
  }

  /// Reorder habits within stack
  Future<void> reorderHabits({
    required String stackId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final stackIndex = _stacks.indexWhere((s) => s.id == stackId);
    if (stackIndex == -1) return;

    final stack = _stacks[stackIndex];
    final habits = List<StackedHabit>.from(stack.habits);

    if (newIndex > oldIndex) newIndex--;

    final habit = habits.removeAt(oldIndex);
    habits.insert(newIndex, habit);

    // Update order indices
    for (int i = 0; i < habits.length; i++) {
      habits[i] = habits[i].copyWith(orderIndex: i);
    }

    _stacks[stackIndex] = stack.copyWith(habits: habits);
    await _saveStacks();
    notifyListeners();
  }

  /// Complete a habit in stack
  Future<void> completeHabit({
    required String stackId,
    required String habitId,
  }) async {
    final stackIndex = _stacks.indexWhere((s) => s.id == stackId);
    if (stackIndex == -1) return;

    final stack = _stacks[stackIndex];
    final habitIndex = stack.habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final updatedHabits = List<StackedHabit>.from(stack.habits);
    updatedHabits[habitIndex] = updatedHabits[habitIndex].copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );

    var updatedStack = stack.copyWith(habits: updatedHabits);

    // Check if all habits completed
    if (updatedHabits.every((h) => h.completed)) {
      final todayKey = _getDateKey(DateTime.now());
      final history = List<String>.from(stack.completionHistory);

      if (!history.contains(todayKey)) {
        history.add(todayKey);

        // Update streak
        int newStreak = _calculateStreak(history);
        int longestStreak =
            newStreak > stack.longestStreak ? newStreak : stack.longestStreak;

        updatedStack = updatedStack.copyWith(
          completionHistory: history,
          currentStreak: newStreak,
          longestStreak: longestStreak,
        );
      }
    }

    _stacks[stackIndex] = updatedStack;
    await _saveStacks();
    notifyListeners();
  }

  /// Uncomplete a habit
  Future<void> uncompleteHabit({
    required String stackId,
    required String habitId,
  }) async {
    final stackIndex = _stacks.indexWhere((s) => s.id == stackId);
    if (stackIndex == -1) return;

    final stack = _stacks[stackIndex];
    final habitIndex = stack.habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final updatedHabits = List<StackedHabit>.from(stack.habits);
    updatedHabits[habitIndex] = updatedHabits[habitIndex].copyWith(
      completed: false,
      completedAt: null,
    );

    _stacks[stackIndex] = stack.copyWith(habits: updatedHabits);
    await _saveStacks();
    notifyListeners();
  }

  /// Get next habit to complete in stack
  StackedHabit? getNextHabit(String stackId) {
    final stack = _stacks.firstWhere(
      (s) => s.id == stackId,
      orElse: () => throw Exception('Stack not found'),
    );

    for (final habit in stack.habits) {
      if (!habit.completed) return habit;
    }
    return null;
  }

  /// Calculate streak from history
  int _calculateStreak(List<String> history) {
    if (history.isEmpty) return 0;

    final sortedDates = history.map((s) => DateTime.parse(s)).toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (sortedDates.first != todayOnly &&
        sortedDates.first != todayOnly.subtract(const Duration(days: 1))) {
      return 0; // Streak broken
    }

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i - 1].difference(sortedDates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get stacks for specific time
  List<HabitStack> getStacksForTime(TimeOfDay time) {
    return activeStacks.where((stack) {
      if (stack.triggerType != TriggerType.time) return false;
      if (stack.scheduledTime == null) return false;

      final scheduled = stack.scheduledTime!;
      return scheduled.hour == time.hour &&
          (scheduled.minute - time.minute).abs() <= 15;
    }).toList();
  }

  /// Get stacks for trigger type
  List<HabitStack> getStacksForTrigger(TriggerType trigger) {
    return activeStacks.where((s) => s.triggerType == trigger).toList();
  }

  /// Get completion stats
  Map<String, dynamic> getStats() {
    int totalCompleted = 0;
    int totalHabits = 0;
    int maxStreak = 0;

    for (final stack in _stacks) {
      totalHabits += stack.habits.length;
      totalCompleted += stack.completedCount;
      if (stack.longestStreak > maxStreak) {
        maxStreak = stack.longestStreak;
      }
    }

    return {
      'totalStacks': _stacks.length,
      'activeStacks': activeStacks.length,
      'totalHabits': totalHabits,
      'completedToday': totalCompleted,
      'longestStreak': maxStreak,
      'completionRate':
          totalHabits > 0 ? (totalCompleted / totalHabits * 100).round() : 0,
    };
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
