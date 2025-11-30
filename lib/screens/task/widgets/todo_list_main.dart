import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/screens/task/widgets/empty_todo.dart';
import 'package:check_bird/screens/task/widgets/show_date.dart';
import 'package:check_bird/screens/task/widgets/todo_list.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:check_bird/models/todo/todo_list_controller.dart';

class ToDoListMain extends StatelessWidget {
  ToDoListMain({
    super.key,
    required this.today,
  });
  final TodoListController _controller = TodoListController();
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final tomorrow = today.add(const Duration(days: 1));
    final after2day = today.add(const Duration(days: 2));
    final Size size = MediaQuery.of(context).size;

    // Check if Hive box is ready
    final box = _controller.getTodoListSafe();
    if (box == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todayCount = _controller.countToDoForDay(today);
          final tomorrowCount = _controller.countTaskForDay(tomorrow);
          final after2dayCount = _controller.countTaskForDay(after2day);
          final moreCount = _controller.countTaskExcept3Day(today);

          return SingleChildScrollView(
              child: Column(children: [
            const SizedBox(height: 10),
            const ShowDate(text: "Today"),
            if (todayCount == 0) const EmptyToDo(),
            if (todayCount > 0)
              SizedBox(
                height: size.width * 0.3 * todayCount,
                child: TodoList(day: today, isToday: true),
              ),
            const ShowDate(text: "Tomorrow"),
            if (tomorrowCount == 0) const EmptyToDo(),
            if (tomorrowCount > 0)
              SizedBox(
                height: size.width * 0.3 * tomorrowCount,
                child: TodoList(day: tomorrow),
              ),
            const ShowDate(text: "After Tomorrow"),
            if (after2dayCount == 0) const EmptyToDo(),
            if (after2dayCount > 0)
              SizedBox(
                height: size.width * 0.3 * after2dayCount,
                child: TodoList(day: after2day),
              ),
            const ShowDate(text: "More"),
            if (moreCount > 0)
              SizedBox(
                height: size.width * 0.3 * moreCount,
                child: TodoList(day: today, isMore: true),
              ),
          ]));
        });
  }
}
