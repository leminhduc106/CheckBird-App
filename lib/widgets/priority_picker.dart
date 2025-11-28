import 'package:flutter/material.dart';
import 'package:check_bird/models/priority/task_priority.dart';

/// A widget to select task priority
class PriorityPicker extends StatelessWidget {
  final TaskPriority selectedPriority;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final bool showLabels;

  const PriorityPicker({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TaskPriority.values.map((priority) {
        final isSelected = priority == selectedPriority;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => onPriorityChanged(priority),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: showLabels ? 12 : 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color:
                    isSelected ? priority.backgroundColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? priority.color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    priority.icon,
                    size: 18,
                    color: isSelected ? priority.color : Colors.grey,
                  ),
                  if (showLabels) ...[
                    const SizedBox(width: 4),
                    Text(
                      priority.shortLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? priority.color : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A compact priority indicator badge
class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool compact;
  final VoidCallback? onTap;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (priority == TaskPriority.p4 && compact) {
      // Don't show badge for low priority in compact mode
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: priority.backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              priority.icon,
              size: compact ? 12 : 14,
              color: priority.color,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                priority.shortLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: priority.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A flag icon that shows priority with color
class PriorityFlag extends StatelessWidget {
  final TaskPriority priority;
  final double size;
  final VoidCallback? onTap;

  const PriorityFlag({
    super.key,
    required this.priority,
    this.size = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        priority.icon,
        size: size,
        color: priority.color,
      ),
    );
  }
}

/// Bottom sheet for selecting priority
class PriorityBottomSheet extends StatelessWidget {
  final TaskPriority currentPriority;
  final ValueChanged<TaskPriority> onPrioritySelected;

  const PriorityBottomSheet({
    super.key,
    required this.currentPriority,
    required this.onPrioritySelected,
  });

  static Future<TaskPriority?> show(
    BuildContext context, {
    required TaskPriority currentPriority,
  }) {
    return showModalBottomSheet<TaskPriority>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PriorityBottomSheet(
        currentPriority: currentPriority,
        onPrioritySelected: (priority) {
          Navigator.pop(context, priority);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Set Priority',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...TaskPriority.values.map((priority) {
              final isSelected = priority == currentPriority;
              return ListTile(
                onTap: () => onPrioritySelected(priority),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priority.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    priority.icon,
                    color: priority.color,
                  ),
                ),
                title: Text(
                  '${priority.shortLabel} - ${priority.displayName}',
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(_getPriorityDescription(priority)),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: priority.color)
                    : null,
                selected: isSelected,
                selectedTileColor:
                    priority.backgroundColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getPriorityDescription(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.p1:
        return 'Urgent tasks - Must complete today (+${priority.xpBonus} XP)';
      case TaskPriority.p2:
        return 'Important tasks - Complete soon (+${priority.xpBonus} XP)';
      case TaskPriority.p3:
        return 'Normal tasks - Regular priority (+${priority.xpBonus} XP)';
      case TaskPriority.p4:
        return 'Low priority - Nice to have';
    }
  }
}

/// A row widget showing priority with label
class PriorityRow extends StatelessWidget {
  final TaskPriority priority;
  final VoidCallback? onTap;

  const PriorityRow({
    super.key,
    required this.priority,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.flag, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              'Priority',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: priority.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    priority.icon,
                    size: 16,
                    color: priority.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    priority.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: priority.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
