import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/screens/task/widgets/todo_item.dart';
import 'package:check_bird/screens/task/widgets/todo_item_remove.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';

class TodoList extends StatelessWidget {
  TodoList({
    super.key,
    this.day,
    this.isToday = false,
    this.isMore = false,
  });
  final TodoListController _controller = TodoListController();
  final DateTime? day;
  final bool isToday;
  final bool isMore;

  @override
  Widget build(BuildContext context) {
    // Check if Hive box is ready
    final box = _controller.getTodoListSafe();
    if (box == null) {
      // Hive not ready, show empty container
      return const SizedBox.shrink();
    }

    if (day == null) {
      return ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todos = box.values.toList();
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return TodoItem(todo: todos[index]);
            },
          );
        },
      );
    } else if (isToday) {
      return ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todos = _controller.getToDoForDay(day!);
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return ToDoItemRemove(todos: todos, index: index);
            },
          );
        },
      );
    } else if (isMore) {
      return ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todos = _controller.getTaskExcept3Day(day!);
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return ToDoItemRemove(todos: todos, index: index);
            },
          );
        },
      );
    } else {
      return ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todos = _controller.getTaskForDay(day!);
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              return ToDoItemRemove(todos: todos, index: index);
            },
          );
        },
      );
    }
  }
}
