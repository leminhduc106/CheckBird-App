import 'package:flutter/material.dart';

/// Task priority levels inspired by Todoist
/// P1 = Urgent (Red) - Must do today
/// P2 = High (Orange) - Important
/// P3 = Medium (Blue) - Normal
/// P4 = Low (Grey) - Nice to have
enum TaskPriority {
  p1, // Urgent - Red
  p2, // High - Orange
  p3, // Medium - Blue
  p4, // Low - Grey (default)
}

extension TaskPriorityExtension on TaskPriority {
  /// Get the display name for the priority
  String get displayName {
    switch (this) {
      case TaskPriority.p1:
        return 'Urgent';
      case TaskPriority.p2:
        return 'High';
      case TaskPriority.p3:
        return 'Medium';
      case TaskPriority.p4:
        return 'Low';
    }
  }

  /// Get the short label (P1, P2, etc.)
  String get shortLabel {
    switch (this) {
      case TaskPriority.p1:
        return 'P1';
      case TaskPriority.p2:
        return 'P2';
      case TaskPriority.p3:
        return 'P3';
      case TaskPriority.p4:
        return 'P4';
    }
  }

  /// Get the color for this priority
  Color get color {
    switch (this) {
      case TaskPriority.p1:
        return const Color(0xFFD93025); // Red
      case TaskPriority.p2:
        return const Color(0xFFF57C00); // Orange
      case TaskPriority.p3:
        return const Color(0xFF1A73E8); // Blue
      case TaskPriority.p4:
        return const Color(0xFF5F6368); // Grey
    }
  }

  /// Get the background color (lighter variant)
  Color get backgroundColor {
    switch (this) {
      case TaskPriority.p1:
        return const Color(0xFFFCE8E6); // Light Red
      case TaskPriority.p2:
        return const Color(0xFFFFF3E0); // Light Orange
      case TaskPriority.p3:
        return const Color(0xFFE8F0FE); // Light Blue
      case TaskPriority.p4:
        return const Color(0xFFF1F3F4); // Light Grey
    }
  }

  /// Get the icon for this priority
  IconData get icon {
    switch (this) {
      case TaskPriority.p1:
        return Icons.flag;
      case TaskPriority.p2:
        return Icons.flag;
      case TaskPriority.p3:
        return Icons.flag_outlined;
      case TaskPriority.p4:
        return Icons.outlined_flag;
    }
  }

  /// Sort weight (lower = higher priority)
  int get sortWeight {
    switch (this) {
      case TaskPriority.p1:
        return 1;
      case TaskPriority.p2:
        return 2;
      case TaskPriority.p3:
        return 3;
      case TaskPriority.p4:
        return 4;
    }
  }

  /// Get XP bonus for completing high priority tasks
  int get xpBonus {
    switch (this) {
      case TaskPriority.p1:
        return 15; // +15 XP for urgent tasks
      case TaskPriority.p2:
        return 10; // +10 XP for high priority
      case TaskPriority.p3:
        return 5; // +5 XP for medium priority
      case TaskPriority.p4:
        return 0; // No bonus for low priority
    }
  }

  /// Get coin bonus for completing high priority tasks
  int get coinBonus {
    switch (this) {
      case TaskPriority.p1:
        return 5;
      case TaskPriority.p2:
        return 3;
      case TaskPriority.p3:
        return 1;
      case TaskPriority.p4:
        return 0;
    }
  }

  /// Parse from string
  static TaskPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'p1':
      case 'urgent':
      case '1':
        return TaskPriority.p1;
      case 'p2':
      case 'high':
      case '2':
        return TaskPriority.p2;
      case 'p3':
      case 'medium':
      case '3':
        return TaskPriority.p3;
      case 'p4':
      case 'low':
      case '4':
      default:
        return TaskPriority.p4;
    }
  }
}

/// Model to store task priority mapping
class TaskPriorityData {
  final String taskId;
  final TaskPriority priority;
  final DateTime updatedAt;

  TaskPriorityData({
    required this.taskId,
    required this.priority,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'priority': priority.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskPriorityData.fromJson(Map<String, dynamic> json) {
    return TaskPriorityData(
      taskId: json['taskId'] as String,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.p4,
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Smart filter for viewing tasks by priority
class PriorityFilter {
  final Set<TaskPriority> includedPriorities;
  final bool sortByPriority;
  final bool showOverdueFirst;

  PriorityFilter({
    Set<TaskPriority>? includedPriorities,
    this.sortByPriority = true,
    this.showOverdueFirst = true,
  }) : includedPriorities = includedPriorities ?? TaskPriority.values.toSet();

  /// Check if a priority should be shown
  bool shouldShow(TaskPriority priority) {
    return includedPriorities.contains(priority);
  }

  /// Create a filter for urgent tasks only
  factory PriorityFilter.urgentOnly() {
    return PriorityFilter(
      includedPriorities: {TaskPriority.p1},
    );
  }

  /// Create a filter for high priority tasks (P1 and P2)
  factory PriorityFilter.highPriority() {
    return PriorityFilter(
      includedPriorities: {TaskPriority.p1, TaskPriority.p2},
    );
  }

  /// Create a filter excluding low priority
  factory PriorityFilter.excludeLow() {
    return PriorityFilter(
      includedPriorities: {TaskPriority.p1, TaskPriority.p2, TaskPriority.p3},
    );
  }
}
