import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/screens/task/widgets/empty_todo.dart';
import 'package:check_bird/screens/task/widgets/todo_list.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';

class ToDoListToday extends StatelessWidget {
  ToDoListToday({
    super.key,
    required this.today,
  });
  final TodoListController _controller = TodoListController();
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    // Check if Hive box is ready
    final box = _controller.getTodoListSafe();
    if (box == null) {
      // Hive not ready, show empty state
      return const EmptyToDo();
    }
    
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Todo> box, _) {
        final taskCount = _controller.countToDoForDay(today);
        return SingleChildScrollView(
            child: Column(children: [
          if (taskCount == 0) const EmptyToDo(),
          if (taskCount > 0)
            SizedBox(
              height: size.width * 0.3 * taskCount,
              child: TodoList(day: today, isToday: true),
            ),
        ]));
      },
    );
  }
}
