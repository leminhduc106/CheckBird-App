import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:check_bird/screens/create_task/create_todo_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:check_bird/widgets/reward_toast_overlay.dart';
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
    final isGroupTask = todo.groupId != null;
    return AnimatedOpacity(
      opacity: todo.isCompleted ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      if (isGroupTask)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_rounded,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Group task',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            onChanged: (_) async {
                              final userId = Authentication.user?.uid;
                              if (userId == null) {
                                debugPrint('❌ No user ID found');
                                return;
                              }

                              final wasCompleted = todo.isCompleted;
                              debugPrint(
                                  '📋 Task toggle: "${todo.todoName}" (ID: ${todo.id}, Type: ${todo.type}, WasCompleted: $wasCompleted)');
                              todo.toggleCompleted();

                              // Only award rewards when marking as complete (not when uncompleting)
                              if (!wasCompleted && todo.isCompleted) {
                                if (todo.id == null || todo.id!.isEmpty) {
                                  debugPrint(
                                      '❌ Task ID is missing for: ${todo.todoName}');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error: Task ID is missing. Please recreate this task.',
                                        ),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                debugPrint(
                                    '🎁 Attempting to award rewards for task: ${todo.id}');
                                final rewards = await RewardsService()
                                    .awardTaskCompletionRewards(
                                  userId: userId,
                                  taskId: todo.id!,
                                  taskName: todo.todoName,
                                  taskType: todo.type,
                                  isGroupTask: isGroupTask,
                                );

                                if (rewards != null) {
                                  final coins = rewards['coins'] ?? 0;
                                  final xp = rewards['xp'] ?? 0;
                                  debugPrint(
                                      '✅ Rewards awarded! +$coins coins, +$xp XP');

                                  // Show reward toast using global controller
                                  RewardToastController().showReward(
                                    coins: coins,
                                    xp: xp,
                                    isGroupTask: isGroupTask,
                                  );
                                } else if (context.mounted) {
                                  // No rewards earned (already completed today)
                                  debugPrint(
                                      '⚠️ No rewards: Already completed today or error');

                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.info_outline,
                                              color: Colors.white),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              todo.type == TodoType.habit
                                                  ? 'Habit already completed today!'
                                                  : 'Task already completed today!',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 3),
                                      backgroundColor: Colors.orange.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
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
