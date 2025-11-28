import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:check_bird/models/priority/task_priority.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage task priorities
/// Uses a separate mapping to avoid modifying the core Todo Hive structure
class PriorityService {
  static final PriorityService _instance = PriorityService._internal();
  factory PriorityService() => _instance;
  PriorityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local cache of priorities
  final Map<String, TaskPriority> _priorityCache = {};

  // Stream controller for priority updates
  final _priorityController =
      StreamController<Map<String, TaskPriority>>.broadcast();
  Stream<Map<String, TaskPriority>> get priorityStream =>
      _priorityController.stream;

  String? get _userId => _auth.currentUser?.uid;

  /// Initialize the service and load cached priorities
  Future<void> initialize() async {
    await _loadFromLocal();
    if (_userId != null) {
      await _syncFromFirestore();
    }
  }

  /// Load priorities from local storage
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('task_priorities');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        _priorityCache.clear();
        jsonMap.forEach((key, value) {
          _priorityCache[key] = TaskPriority.values.firstWhere(
            (p) => p.name == value,
            orElse: () => TaskPriority.p4,
          );
        });
        _priorityController.add(Map.from(_priorityCache));
      }
    } catch (e) {
      print('Error loading priorities from local: $e');
    }
  }

  /// Save priorities to local storage
  Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> jsonMap = {};
      _priorityCache.forEach((key, value) {
        jsonMap[key] = value.name;
      });
      await prefs.setString('task_priorities', json.encode(jsonMap));
    } catch (e) {
      print('Error saving priorities to local: $e');
    }
  }

  /// Sync priorities from Firestore
  Future<void> _syncFromFirestore() async {
    if (_userId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('task_priorities')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final priorities = data['priorities'] as Map<String, dynamic>?;
        if (priorities != null) {
          priorities.forEach((key, value) {
            _priorityCache[key] = TaskPriority.values.firstWhere(
              (p) => p.name == value,
              orElse: () => TaskPriority.p4,
            );
          });
          _priorityController.add(Map.from(_priorityCache));
          await _saveToLocal();
        }
      }
    } catch (e) {
      print('Error syncing priorities from Firestore: $e');
    }
  }

  /// Save priorities to Firestore
  Future<void> _syncToFirestore() async {
    if (_userId == null) return;

    try {
      final Map<String, String> priorities = {};
      _priorityCache.forEach((key, value) {
        priorities[key] = value.name;
      });

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('task_priorities')
          .set({
        'priorities': priorities,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing priorities to Firestore: $e');
    }
  }

  /// Get priority for a task
  TaskPriority getPriority(String taskId) {
    return _priorityCache[taskId] ?? TaskPriority.p4;
  }

  /// Get priority for a Todo object
  TaskPriority getPriorityForTodo(Todo todo) {
    if (todo.id == null) return TaskPriority.p4;
    return getPriority(todo.id!);
  }

  /// Set priority for a task
  Future<void> setPriority(String taskId, TaskPriority priority) async {
    _priorityCache[taskId] = priority;
    _priorityController.add(Map.from(_priorityCache));
    await _saveToLocal();
    await _syncToFirestore();
  }

  /// Set priority for a Todo object
  Future<void> setPriorityForTodo(Todo todo, TaskPriority priority) async {
    if (todo.id == null) return;
    await setPriority(todo.id!, priority);
  }

  /// Remove priority mapping when task is deleted
  Future<void> removePriority(String taskId) async {
    _priorityCache.remove(taskId);
    _priorityController.add(Map.from(_priorityCache));
    await _saveToLocal();
    await _syncToFirestore();
  }

  /// Sort todos by priority
  List<Todo> sortByPriority(List<Todo> todos, {bool ascending = true}) {
    final sortedTodos = List<Todo>.from(todos);
    sortedTodos.sort((a, b) {
      final priorityA = getPriorityForTodo(a);
      final priorityB = getPriorityForTodo(b);
      final comparison = priorityA.sortWeight.compareTo(priorityB.sortWeight);
      return ascending ? comparison : -comparison;
    });
    return sortedTodos;
  }

  /// Filter todos by priority
  List<Todo> filterByPriority(List<Todo> todos, PriorityFilter filter) {
    return todos.where((todo) {
      final priority = getPriorityForTodo(todo);
      return filter.shouldShow(priority);
    }).toList();
  }

  /// Get todos filtered and sorted by priority
  List<Todo> getFilteredAndSorted(
    List<Todo> todos, {
    PriorityFilter? filter,
    bool sortByPriority = true,
    bool showOverdueFirst = true,
  }) {
    var result = List<Todo>.from(todos);

    // Apply filter if provided
    if (filter != null) {
      result = filterByPriority(result, filter);
    }

    // Sort by priority
    if (sortByPriority) {
      result = sortByPriority ? this.sortByPriority(result) : result;
    }

    // Show overdue tasks first
    if (showOverdueFirst) {
      final now = DateTime.now();
      final overdue = <Todo>[];
      final notOverdue = <Todo>[];

      for (final todo in result) {
        if (todo.deadline != null && todo.deadline!.isBefore(now)) {
          overdue.add(todo);
        } else {
          notOverdue.add(todo);
        }
      }

      result = [...overdue, ...notOverdue];
    }

    return result;
  }

  /// Get count of tasks by priority
  Map<TaskPriority, int> getTaskCountByPriority(List<Todo> todos) {
    final counts = <TaskPriority, int>{
      TaskPriority.p1: 0,
      TaskPriority.p2: 0,
      TaskPriority.p3: 0,
      TaskPriority.p4: 0,
    };

    for (final todo in todos) {
      final priority = getPriorityForTodo(todo);
      counts[priority] = (counts[priority] ?? 0) + 1;
    }

    return counts;
  }

  /// Get urgent tasks (P1)
  List<Todo> getUrgentTasks(List<Todo> todos) {
    return todos.where((todo) {
      return getPriorityForTodo(todo) == TaskPriority.p1;
    }).toList();
  }

  /// Get high priority tasks (P1 + P2)
  List<Todo> getHighPriorityTasks(List<Todo> todos) {
    return todos.where((todo) {
      final priority = getPriorityForTodo(todo);
      return priority == TaskPriority.p1 || priority == TaskPriority.p2;
    }).toList();
  }

  /// Parse priority from natural language text
  /// Returns the priority and the cleaned text
  (TaskPriority, String) parsePriorityFromText(String text) {
    final lowerText = text.toLowerCase();

    // Check for explicit priority markers
    final priorityPatterns = [
      (
        RegExp(r'\b(p1|priority\s*1|urgent|!!!)\b', caseSensitive: false),
        TaskPriority.p1
      ),
      (
        RegExp(r'\b(p2|priority\s*2|high|important|!!)\b',
            caseSensitive: false),
        TaskPriority.p2
      ),
      (
        RegExp(r'\b(p3|priority\s*3|medium|normal|!)\b', caseSensitive: false),
        TaskPriority.p3
      ),
      (
        RegExp(r'\b(p4|priority\s*4|low)\b', caseSensitive: false),
        TaskPriority.p4
      ),
    ];

    for (final (pattern, priority) in priorityPatterns) {
      if (pattern.hasMatch(lowerText)) {
        // Remove the priority marker from text
        final cleanedText = text.replaceAll(pattern, '').trim();
        return (priority, cleanedText);
      }
    }

    // Default to P4 if no priority specified
    return (TaskPriority.p4, text);
  }

  /// Dispose the service
  void dispose() {
    _priorityController.close();
  }
}
