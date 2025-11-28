import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/habits/habit_stack.dart';
import 'package:check_bird/services/habit_stack_service.dart';

class HabitStackScreen extends StatefulWidget {
  const HabitStackScreen({super.key});

  @override
  State<HabitStackScreen> createState() => _HabitStackScreenState();
}

class _HabitStackScreenState extends State<HabitStackScreen> {
  final HabitStackService _stackService = HabitStackService();

  @override
  void initState() {
    super.initState();
    _stackService.initialize();
    _stackService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stackService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stacks = _stackService.stacks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Stacks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStats,
          ),
        ],
      ),
      body: stacks.isEmpty ? _buildEmptyState() : _buildStacksList(stacks),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        icon: const Icon(Icons.add),
        label: const Text('New Stack'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '⛓️',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Build Habit Chains',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Link habits together in sequences. When you complete one, the next one follows automatically!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showCreateOptions,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Stack'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStacksList(List<HabitStack> stacks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: stacks.length,
      itemBuilder: (context, index) {
        final stack = stacks[index];
        return _buildStackCard(stack);
      },
    );
  }

  Widget _buildStackCard(HabitStack stack) {
    final theme = Theme.of(context);
    final progress = stack.completionProgress;
    final isComplete = stack.isCompletedToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openStackDetail(stack),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isComplete
                      ? [
                          Colors.green.withOpacity(0.2),
                          Colors.green.withOpacity(0.1)
                        ]
                      : [
                          theme.colorScheme.primaryContainer.withOpacity(0.5),
                          theme.colorScheme.primaryContainer.withOpacity(0.2),
                        ],
                ),
              ),
              child: Row(
                children: [
                  // Icon/Completion indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isComplete ? Colors.green : theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isComplete ? Icons.check : Icons.link,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stack.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stack.triggerDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stack.totalEstimatedTime.inMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Streak badge
                  if (stack.currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stack.currentStreak}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? Colors.green : theme.colorScheme.primary,
              ),
            ),

            // Habits list
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...stack.habits.asMap().entries.map((entry) {
                    final index = entry.key;
                    final habit = entry.value;
                    final isNext = !habit.completed &&
                        (index == 0 || stack.habits[index - 1].completed);

                    return _buildHabitItem(stack, habit, isNext);
                  }),
                  if (stack.habits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No habits yet. Tap to add some!',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitItem(HabitStack stack, StackedHabit habit, bool isNext) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Chain connector
          if (habit.orderIndex > 0)
            Container(
              width: 24,
              height: 20,
              margin: const EdgeInsets.only(bottom: 8),
              child: CustomPaint(
                painter: ChainPainter(
                  color: habit.completed
                      ? Colors.green
                      : theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
            )
          else
            const SizedBox(width: 24),

          const SizedBox(width: 8),

          // Checkbox
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              if (habit.completed) {
                await _stackService.uncompleteHabit(
                  stackId: stack.id,
                  habitId: habit.id,
                );
              } else {
                await _stackService.completeHabit(
                  stackId: stack.id,
                  habitId: habit.id,
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: habit.completed
                    ? Colors.green
                    : (isNext
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(
                  color: habit.completed
                      ? Colors.green
                      : (isNext
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline),
                  width: isNext ? 2 : 1,
                ),
              ),
              child: habit.completed
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Emoji
          if (habit.emoji != null) ...[
            Text(habit.emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],

          // Name
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
                decoration: habit.completed ? TextDecoration.lineThrough : null,
                color:
                    habit.completed ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),

          // Duration
          Text(
            '${habit.estimatedDuration.inMinutes}m',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Habit Stack',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Create from scratch
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add),
                ),
                title: const Text('Start from Scratch'),
                subtitle: const Text('Build a custom habit chain'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateDialog();
                },
              ),
              const Divider(),

              // Templates
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '📚 Templates',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: HabitStackTemplate.templates.length,
                  itemBuilder: (context, index) {
                    final template = HabitStackTemplate.templates[index];
                    return _buildTemplateCard(template);
                  },
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard(HabitStackTemplate template) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await _stackService.createFromTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "${template.name}" stack!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${template.habits.length} habits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    String name = '';
    TriggerType triggerType = TriggerType.time;
    TimeOfDay? scheduledTime = const TimeOfDay(hour: 7, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Habit Stack'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Stack Name',
                        hintText: 'e.g., Morning Routine',
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    const Text('Trigger:'),
                    const SizedBox(height: 8),
                    DropdownButton<TriggerType>(
                      value: triggerType,
                      isExpanded: true,
                      items: TriggerType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(_getTriggerLabel(t)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => triggerType = value!);
                      },
                    ),
                    if (triggerType == TriggerType.time) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Scheduled Time'),
                        trailing: Text(
                          scheduledTime != null
                              ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
                              : 'Not set',
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: scheduledTime ??
                                const TimeOfDay(hour: 7, minute: 0),
                          );
                          if (time != null) {
                            setDialogState(() => scheduledTime = time);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: name.isNotEmpty
                      ? () async {
                          await _stackService.createStack(
                            name: name,
                            triggerType: triggerType,
                            scheduledTime: scheduledTime,
                          );
                          if (mounted) Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getTriggerLabel(TriggerType type) {
    switch (type) {
      case TriggerType.time:
        return '⏰ Specific Time';
      case TriggerType.afterWaking:
        return '🌅 After Waking Up';
      case TriggerType.beforeSleep:
        return '🌙 Before Sleep';
      case TriggerType.afterMeal:
        return '🍽️ After Eating';
      case TriggerType.afterExercise:
        return '💪 After Exercise';
      case TriggerType.custom:
        return '✨ Custom Trigger';
    }
  }

  void _openStackDetail(HabitStack stack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StackDetailScreen(stack: stack),
      ),
    );
  }

  void _showStats() {
    final stats = _stackService.getStats();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics),
              SizedBox(width: 8),
              Text('Stack Stats'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Stacks', '${stats['totalStacks']}'),
              _buildStatRow('Active Stacks', '${stats['activeStacks']}'),
              _buildStatRow('Total Habits', '${stats['totalHabits']}'),
              _buildStatRow('Completed Today', '${stats['completedToday']}'),
              _buildStatRow('Completion Rate', '${stats['completionRate']}%'),
              _buildStatRow('Longest Streak', '${stats['longestStreak']} days'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for chain links
class ChainPainter extends CustomPainter {
  final Color color;

  ChainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stack detail screen
class StackDetailScreen extends StatefulWidget {
  final HabitStack stack;

  const StackDetailScreen({super.key, required this.stack});

  @override
  State<StackDetailScreen> createState() => _StackDetailScreenState();
}

class _StackDetailScreenState extends State<StackDetailScreen> {
  final HabitStackService _stackService = HabitStackService();

  late HabitStack _stack;

  @override
  void initState() {
    super.initState();
    _stack = widget.stack;
    _stackService.addListener(_onUpdate);
  }

  void _onUpdate() {
    final updated = _stackService.stacks.firstWhere(
      (s) => s.id == _stack.id,
      orElse: () => _stack,
    );
    if (mounted) {
      setState(() => _stack = updated);
    }
  }

  @override
  void dispose() {
    _stackService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stack.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stack.habits.length,
        onReorder: (oldIndex, newIndex) async {
          await _stackService.reorderHabits(
            stackId: _stack.id,
            oldIndex: oldIndex,
            newIndex: newIndex,
          );
        },
        itemBuilder: (context, index) {
          final habit = _stack.habits[index];
          return Card(
            key: ValueKey(habit.id),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: habit.emoji != null
                  ? Text(habit.emoji!, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.circle_outlined),
              title: Text(habit.name),
              subtitle: Text('${habit.estimatedDuration.inMinutes} min'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editHabit(habit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteHabit(habit),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addHabit() {
    String name = '';
    String emoji = '';
    int duration = 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Emoji (optional)'),
                onChanged: (value) => emoji = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => duration = int.tryParse(value) ?? 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _stackService.addHabitToStack(
                  stackId: _stack.id,
                  name: name,
                  emoji: emoji.isNotEmpty ? emoji : null,
                  estimatedDuration: Duration(minutes: duration),
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editHabit(StackedHabit habit) {
    // TODO: Implement edit
  }

  void _deleteHabit(StackedHabit habit) async {
    await _stackService.removeHabitFromStack(
      stackId: _stack.id,
      habitId: habit.id,
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Stack?'),
          content: Text('Are you sure you want to delete "${_stack.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _stackService.deleteStack(_stack.id);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
