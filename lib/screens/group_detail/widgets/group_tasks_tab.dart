import 'package:flutter/material.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/models/todo/todo_type.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:check_bird/screens/create_task/create_todo_screen.dart';

class GroupTasksTab extends StatefulWidget {
  const GroupTasksTab({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupTasksTab> createState() => _GroupTasksTabState();
}

class _GroupTasksTabState extends State<GroupTasksTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<Box<Todo>>(
        valueListenable: Hive.box<Todo>('todos').listenable(),
        builder: (context, box, _) {
          final groupTodos = box.values
              .where((todo) => todo.groupId == widget.groupId)
              .toList();

          if (groupTodos.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTasksList(groupTodos);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE3F2FD),
        foregroundColor: const Color(0xFF1976D2),
        elevation: 3,
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateTodoScreen(
                initialGroupId: widget.groupId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this group yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create accountability tasks that everyone in the group can see and celebrate when completed!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateTodoScreen(
                      initialGroupId: widget.groupId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(List<Todo> groupTodos) {
    // Separate completed and pending tasks
    final pendingTasks = groupTodos.where((todo) => !todo.isCompleted).toList();
    final completedTasks =
        groupTodos.where((todo) => todo.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingTasks.isNotEmpty) ...[
          _buildSectionHeader('Pending Tasks', pendingTasks.length),
          const SizedBox(height: 12),
          ...pendingTasks.map((todo) => _buildTaskItem(todo)),
          const SizedBox(height: 24),
        ],
        if (completedTasks.isNotEmpty) ...[
          _buildSectionHeader('Completed Tasks', completedTasks.length),
          const SizedBox(height: 12),
          ...completedTasks.map((todo) => _buildTaskItem(todo)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: todo.isCompleted,
                shape: const CircleBorder(),
                onChanged: (_) {
                  todo.toggleCompleted();
                },
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.todoName,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: todo.type == TodoType.habit
                              ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          todo.type == TodoType.habit ? 'Habit' : 'Task',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: todo.type == TodoType.habit
                                ? Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status and deadline
                  Row(
                    children: [
                      if (todo.isCompleted) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed today',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ] else if (todo.type == TodoType.task &&
                          todo.deadline != null) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat.MMMd().add_Hm().format(todo.deadline!)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
