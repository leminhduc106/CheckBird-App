import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:check_bird/screens/create_task/create_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoItem extends StatelessWidget {
  const TodoItem({super.key, required this.todo, this.isCheck = true});
  final Todo todo;
  final bool isCheck;

  String get habitDays {
    final days = todo.weekdays;
    String result = '';
    for (var i = 0; i < days!.length; i++) {
      if (days[i]) {
        if (i == 6) {
          result += 'sun-';
        } else {
          result += '${i + 2}-';
        }
      }
    }
    result = result.substring(0, result.length - 1);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: todo.isCompleted ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Card(
          elevation: todo.isCompleted ? 0 : 1,
          color: Color(todo.backgroundColor),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateTodoScreen(todo: todo),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: todo.isCompleted
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Type indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: todo.type == TodoType.habit
                              ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              todo.type == TodoType.habit
                                  ? Icons.repeat_rounded
                                  : Icons.task_alt_rounded,
                              size: 16,
                              color: todo.type == TodoType.habit
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todo.type == TodoType.habit ? "Habit" : "Task",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: todo.type == TodoType.habit
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Time/Date indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              todo.type == TodoType.habit
                                  ? Icons.calendar_view_week_rounded
                                  : Icons.access_time_rounded,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              todo.type == TodoType.habit
                                  ? habitDays
                                  : DateFormat.Hm().format(todo.deadline!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCheck) ...[
                        const SizedBox(width: 12),
                        // Checkbox
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: todo.isCompleted,
                            shape: const CircleBorder(),
                            onChanged: (_) {
                              todo.toggleCompleted();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Todo title
                  Text(
                    todo.todoName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(todo.textColor),
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Color(todo.textColor).withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
