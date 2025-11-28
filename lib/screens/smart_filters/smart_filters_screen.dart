import 'package:flutter/material.dart';
import 'package:check_bird/models/priority/task_priority.dart';
import 'package:check_bird/models/todo/todo.dart';
import 'package:check_bird/services/priority_service.dart';
import 'package:check_bird/widgets/priority_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Smart Filters Screen - View tasks organized by priority and other criteria
class SmartFiltersScreen extends StatefulWidget {
  const SmartFiltersScreen({super.key});

  @override
  State<SmartFiltersScreen> createState() => _SmartFiltersScreenState();
}

class _SmartFiltersScreenState extends State<SmartFiltersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PriorityService _priorityService = PriorityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Views'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '🎯 Focus'),
            Tab(text: '🔥 Urgent'),
            Tab(text: '📅 Today'),
            Tab(text: '📆 Upcoming'),
            Tab(text: '✅ Completed'),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Todo>('todos').listenable(),
        builder: (context, Box<Todo> box, _) {
          final allTodos = box.values.toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _FocusView(todos: allTodos, priorityService: _priorityService),
              _UrgentView(todos: allTodos, priorityService: _priorityService),
              _TodayView(todos: allTodos, priorityService: _priorityService),
              _UpcomingView(todos: allTodos, priorityService: _priorityService),
              _CompletedView(
                  todos: allTodos, priorityService: _priorityService),
            ],
          );
        },
      ),
    );
  }
}

/// Focus View - High priority uncompleted tasks
class _FocusView extends StatelessWidget {
  final List<Todo> todos;
  final PriorityService priorityService;

  const _FocusView({
    required this.todos,
    required this.priorityService,
  });

  @override
  Widget build(BuildContext context) {
    final focusTasks = todos.where((todo) {
      if (todo.isCompleted) return false;
      final priority = priorityService.getPriorityForTodo(todo);
      return priority == TaskPriority.p1 || priority == TaskPriority.p2;
    }).toList();

    // Sort by priority
    focusTasks.sort((a, b) {
      final priorityA = priorityService.getPriorityForTodo(a);
      final priorityB = priorityService.getPriorityForTodo(b);
      return priorityA.sortWeight.compareTo(priorityB.sortWeight);
    });

    if (focusTasks.isEmpty) {
      return _EmptyState(
        icon: Icons.center_focus_strong,
        title: 'All Caught Up!',
        subtitle:
            'No high-priority tasks at the moment.\nSet tasks to P1 or P2 to see them here.',
      );
    }

    return Column(
      children: [
        _buildHeader(context, focusTasks.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: focusTasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(
                todo: focusTasks[index],
                priorityService: priorityService,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Mode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count high-priority ${count == 1 ? 'task' : 'tasks'} need your attention',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Urgent View - Only P1 tasks
class _UrgentView extends StatelessWidget {
  final List<Todo> todos;
  final PriorityService priorityService;

  const _UrgentView({
    required this.todos,
    required this.priorityService,
  });

  @override
  Widget build(BuildContext context) {
    final urgentTasks = todos.where((todo) {
      if (todo.isCompleted) return false;
      return priorityService.getPriorityForTodo(todo) == TaskPriority.p1;
    }).toList();

    if (urgentTasks.isEmpty) {
      return _EmptyState(
        icon: Icons.whatshot,
        title: 'No Urgent Tasks',
        subtitle:
            'Great! You have no urgent tasks.\nMark a task as P1 when it needs immediate attention.',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TaskPriority.p1.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: TaskPriority.p1.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TaskPriority.p1.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.priority_high,
                  color: TaskPriority.p1.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${urgentTasks.length} Urgent ${urgentTasks.length == 1 ? 'Task' : 'Tasks'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TaskPriority.p1.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'These need your immediate attention',
                      style: TextStyle(
                        fontSize: 13,
                        color: TaskPriority.p1.color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: urgentTasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(
                todo: urgentTasks[index],
                priorityService: priorityService,
                showUrgentBorder: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Today View - Tasks due today
class _TodayView extends StatelessWidget {
  final List<Todo> todos;
  final PriorityService priorityService;

  const _TodayView({
    required this.todos,
    required this.priorityService,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayTasks = todos.where((todo) {
      if (todo.isCompleted) return false;
      if (todo.deadline == null) return false;
      return todo.deadline!.isAfter(today) && todo.deadline!.isBefore(tomorrow);
    }).toList();

    // Sort by priority first, then by time
    todayTasks.sort((a, b) {
      final priorityA = priorityService.getPriorityForTodo(a);
      final priorityB = priorityService.getPriorityForTodo(b);
      if (priorityA != priorityB) {
        return priorityA.sortWeight.compareTo(priorityB.sortWeight);
      }
      return (a.deadline ?? today).compareTo(b.deadline ?? today);
    });

    if (todayTasks.isEmpty) {
      return _EmptyState(
        icon: Icons.today,
        title: 'No Tasks Due Today',
        subtitle:
            'You have nothing scheduled for today.\nEnjoy your free time or plan ahead!',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${todayTasks.length} ${todayTasks.length == 1 ? 'task' : 'tasks'} to complete',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todayTasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(
                todo: todayTasks[index],
                priorityService: priorityService,
                showDeadline: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Upcoming View - Tasks in the next 7 days
class _UpcomingView extends StatelessWidget {
  final List<Todo> todos;
  final PriorityService priorityService;

  const _UpcomingView({
    required this.todos,
    required this.priorityService,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final upcomingTasks = todos.where((todo) {
      if (todo.isCompleted) return false;
      if (todo.deadline == null) return false;
      return todo.deadline!.isAfter(today) && todo.deadline!.isBefore(nextWeek);
    }).toList();

    // Sort by deadline
    upcomingTasks.sort((a, b) {
      return (a.deadline ?? today).compareTo(b.deadline ?? today);
    });

    // Group by day
    final Map<DateTime, List<Todo>> groupedTasks = {};
    for (final todo in upcomingTasks) {
      final date = DateTime(
        todo.deadline!.year,
        todo.deadline!.month,
        todo.deadline!.day,
      );
      groupedTasks[date] = (groupedTasks[date] ?? [])..add(todo);
    }

    if (upcomingTasks.isEmpty) {
      return _EmptyState(
        icon: Icons.event,
        title: 'No Upcoming Tasks',
        subtitle:
            'Nothing scheduled for the next 7 days.\nPlan ahead by adding deadlines to your tasks.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTasks.length,
      itemBuilder: (context, index) {
        final date = groupedTasks.keys.elementAt(index);
        final tasks = groupedTasks[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatDate(date, today),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
            ...tasks.map((todo) => _TaskCard(
                  todo: todo,
                  priorityService: priorityService,
                  showDeadline: true,
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date, DateTime today) {
    final difference = date.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }
}

/// Completed View - Recently completed tasks
class _CompletedView extends StatelessWidget {
  final List<Todo> todos;
  final PriorityService priorityService;

  const _CompletedView({
    required this.todos,
    required this.priorityService,
  });

  @override
  Widget build(BuildContext context) {
    final completedTasks = todos.where((todo) => todo.isCompleted).toList();

    // Sort by last completed date (most recent first)
    completedTasks.sort((a, b) {
      return (b.lastCompleted ?? DateTime.now())
          .compareTo(a.lastCompleted ?? DateTime.now());
    });

    if (completedTasks.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Completed Tasks',
        subtitle:
            'Start checking off your tasks!\nCompleted tasks will appear here.',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${completedTasks.length} Tasks Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'Great progress! Keep it up! 🎉',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: completedTasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(
                todo: completedTasks[index],
                priorityService: priorityService,
                isCompleted: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Task Card Widget
class _TaskCard extends StatelessWidget {
  final Todo todo;
  final PriorityService priorityService;
  final bool showDeadline;
  final bool showUrgentBorder;
  final bool isCompleted;

  const _TaskCard({
    required this.todo,
    required this.priorityService,
    this.showDeadline = false,
    this.showUrgentBorder = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final priority = priorityService.getPriorityForTodo(todo);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: showUrgentBorder ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: showUrgentBorder
            ? BorderSide(color: TaskPriority.p1.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to task detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              InkWell(
                onTap: () {
                  todo.toggleCompleted();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? Colors.green : priority.color,
                      width: 2,
                    ),
                    color: isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.todoName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (todo.todoDescription.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        todo.todoDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showDeadline && todo.deadline != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(todo.deadline!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Priority badge
              if (!isCompleted)
                PriorityBadge(
                  priority: priority,
                  compact: true,
                  onTap: () async {
                    final newPriority = await PriorityBottomSheet.show(
                      context,
                      currentPriority: priority,
                    );
                    if (newPriority != null) {
                      await priorityService.setPriorityForTodo(
                          todo, newPriority);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Empty State Widget
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
