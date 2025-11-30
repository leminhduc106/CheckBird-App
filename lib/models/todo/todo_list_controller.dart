import 'package:check_bird/models/todo/todo_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:check_bird/services/notification.dart';
import 'todo.dart';

class TodoListController {
  // Singleton pattern to ensure consistent state
  static final TodoListController _instance = TodoListController._internal();
  factory TodoListController() => _instance;
  TodoListController._internal();

  // Track initialization state
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  Future<void> openBox() async {
    if (_isInitialized && Hive.isBoxOpen('todos')) {
      return; // Already initialized
    }

    try {
      await Hive.openBox<Todo>('todos');
      _isInitialized = true;
      await _ensureAllTodosHaveIds();
      debugPrint('TodoListController: Hive box opened successfully');
    } catch (e) {
      debugPrint('TodoListController: Failed to open Hive box: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Ensure the box is open, opening it if necessary
  Future<bool> ensureBoxOpen() async {
    if (Hive.isBoxOpen('todos')) {
      _isInitialized = true;
      return true;
    }

    try {
      await openBox();
      return true;
    } catch (e) {
      debugPrint('TodoListController: ensureBoxOpen failed: $e');
      return false;
    }
  }

  /// Migration function: Assigns UUIDs to todos that don't have IDs
  Future<void> _ensureAllTodosHaveIds() async {
    final box = getTodoList();
    bool needsSave = false;

    for (var todo in box.values) {
      if (todo.id == null || todo.id!.isEmpty) {
        todo.id = const Uuid().v1();
        await todo.save();
        needsSave = true;
        debugPrint(
            'Migration: Assigned ID ${todo.id} to todo: ${todo.todoName}');
      }
    }

    if (needsSave) {
      debugPrint('Migration complete: All todos now have IDs');
    }
  }

  /// Reschedule all pending notifications on app startup
  /// This is important for notifications to work after device reboot
  Future<void> rescheduleAllNotifications() async {
    final now = DateTime.now();
    final todos = getTodoList().values.toList();
    int scheduledCount = 0;

    for (final todo in todos) {
      if (todo.type == TodoType.task &&
          todo.notification != null &&
          todo.notificationId != null) {
        // Only reschedule if notification time is in the future
        if (todo.notification!.isAfter(now)) {
          final title = todo.todoName;
          final body =
              "Deadline: ${DateFormat('yyyy-MM-dd kk:mm').format(todo.deadline!)}";

          await NotificationService().createScheduleNotification(
            todo.notificationId!,
            title,
            body,
            todo.notification!,
            payload: todo.id,
          );
          scheduledCount++;
        } else {
          // Clear past notification info
          todo.notification = null;
          todo.notificationId = null;
          await todo.save();
        }
      }
    }

    debugPrint(
        'TodoListController: Rescheduled $scheduledCount notifications on startup');
  }

  Future<void> syncTodoList() async {
    // TODO: sync all todo to firebase using their own `sync` function
  }

  Future<void> closeBox() async {
    if (Hive.isBoxOpen('todos')) {
      await Hive.box('todos').close();
      _isInitialized = false;
    }
  }

  Box<Todo> getTodoList() {
    // use ValueListenableBuilder to listen to this
    // Check if box is open first (important for web compatibility)
    if (!Hive.isBoxOpen('todos')) {
      throw StateError('Hive box "todos" is not open. Call openBox() first.');
    }
    return Hive.box<Todo>('todos');
  }

  /// Safely get todo list, returns null if box isn't open
  Box<Todo>? getTodoListSafe() {
    if (!Hive.isBoxOpen('todos') || !_isInitialized) {
      return null;
    }
    return Hive.box<Todo>('todos');
  }

  Future<void> addTodo(Todo todo) async {
    var todoList = getTodoList();
    String id = const Uuid().v1();
    DateTime now = DateTime.now();
    // hive key and to-do id is the same
    todo.id = id;
    todo.createdDate = now;
    todo.lastModified = now;

    await todoList.add(todo);

    debugPrint('TodoListController: Adding todo "${todo.todoName}"');
    debugPrint('  - Type: ${todo.type}');
    debugPrint('  - Deadline: ${todo.deadline}');
    debugPrint('  - Notification: ${todo.notification}');

    if (todo.type == TodoType.task && todo.notification != null) {
      todo.notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      String title = '📋 ${todo.todoName}';
      String body = todo.deadline != null
          ? "Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(todo.deadline!)}"
          : "Task reminder";

      debugPrint('  - Scheduling notification id: ${todo.notificationId}');
      debugPrint('  - Notification time: ${todo.notification}');

      await NotificationService().createScheduleNotification(
        todo.notificationId!,
        title,
        body,
        todo.notification!,
        payload: todo.id,
      );

      // Save the todo with updated notificationId
      await todo.save();

      debugPrint(
          'TodoListController: Successfully scheduled notification for task "${todo.todoName}"');

      // Debug: Print all pending notifications
      await NotificationService().debugPendingNotifications();
    } else {
      debugPrint(
          '  - No notification scheduled (notification: ${todo.notification})');
    }
  }

  List<Todo> getAllHabit() {
    List<Todo> todolist = [];
    for (int i = 0; i < getTodoList().length; i++) {
      if (getTodoList().values.toList()[i].getType() == TodoType.habit) {
        todolist.add(getTodoList().values.toList()[i]);
      }
    }
    return todolist;
  }

  List<Todo> getHabitForWeekDays(int select) {
    List<Todo> todolist = [];
    for (int i = 0; i < getTodoList().length; i++) {
      if (getTodoList().values.toList()[i].getType() == TodoType.habit) {
        if (getTodoList().values.toList()[i].getNewWeekdays()[select] == true) {
          todolist.add(getTodoList().values.toList()[i]);
        }
      }
    }
    return todolist;
  }

  List<Todo> getHabitForMultiDays(List<bool> days) {
    List<Todo> todolist = getAllHabit();
    for (int i = 0; i < todolist.length; i++) {
      bool check = true;
      for (int j = 0; j < days.length; j++) {
        if (days[j] == true && todolist[i].getNewWeekdays()[j] == days[j]) {
          check = false;
          break;
        }
      }
      if (check) {
        todolist.removeAt(i);
        i--;
      }
    }
    return todolist;
  }

  List<Todo> getTaskForDay(DateTime day) {
    List<Todo> todolist = [];

    for (int i = 0; i < getTodoList().length; i++) {
      if (getTodoList().values.toList()[i].getType() == TodoType.task) {
        if (getTodoList().values.toList()[i].getDueTime().isSameDate(day)) {
          todolist.add(getTodoList().values.toList()[i]);
        }
      }
    }
    return todolist;
  }

  List<Todo> getToDoForDay(DateTime day) {
    List<Todo> todolist = [];
    todolist = getTaskForDay(day);
    List<Todo> temp = getHabitForWeekDays(day.weekday - 1);
    for (int i = 0; i < temp.length; i++) {
      todolist.add(temp[i]);
    }

    return todolist;
  }

  int countToDoForDay(DateTime day) {
    List<Todo> todoList = getToDoForDay(day);
    return todoList.length;
  }

  int countTaskForDay(DateTime day) {
    List<Todo> todoList = getTaskForDay(day);
    return todoList.length;
  }

  List<Todo> getTaskExcept3Day(DateTime day) {
    List<Todo> todolist = [];
    DateTime after3day = day.add(const Duration(days: 3));
    for (int i = 0; i < getTodoList().length; i++) {
      if (getTodoList().values.toList()[i].getType() == TodoType.task &&
          getTodoList().values.toList()[i].getDueTime().compareTo(after3day) ==
              1) {
        todolist.add(getTodoList().values.toList()[i]);
      }
    }
    return todolist;
  }

  int countTaskExcept3Day(DateTime day) {
    List<Todo> todoList = getTaskExcept3Day(day);
    return todoList.length;
  }

  void removeAllTodo() {
    var todoList = getTodoList();
    todoList.clear();
  }
}
