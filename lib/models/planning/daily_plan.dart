import 'package:flutter/material.dart';

/// Daily planning session model
class DailyPlan {
  final String id;
  final DateTime date;
  final String? morningIntention;
  final List<String> topPriorities; // Max 3
  final List<TimeBlock> timeBlocks;
  final int energyLevel; // 1-5
  final String? focusArea;
  final List<String> gratitudeItems;
  final String? eveningReflection;
  final int dayRating; // 1-5
  final bool completed;

  const DailyPlan({
    required this.id,
    required this.date,
    this.morningIntention,
    this.topPriorities = const [],
    this.timeBlocks = const [],
    this.energyLevel = 3,
    this.focusArea,
    this.gratitudeItems = const [],
    this.eveningReflection,
    this.dayRating = 0,
    this.completed = false,
  });

  bool get hasMorningPlan =>
      morningIntention != null || topPriorities.isNotEmpty;
  bool get hasTimeBlocks => timeBlocks.isNotEmpty;
  bool get hasEveningReview => eveningReflection != null && dayRating > 0;

  DailyPlan copyWith({
    String? id,
    DateTime? date,
    String? morningIntention,
    List<String>? topPriorities,
    List<TimeBlock>? timeBlocks,
    int? energyLevel,
    String? focusArea,
    List<String>? gratitudeItems,
    String? eveningReflection,
    int? dayRating,
    bool? completed,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      morningIntention: morningIntention ?? this.morningIntention,
      topPriorities: topPriorities ?? this.topPriorities,
      timeBlocks: timeBlocks ?? this.timeBlocks,
      energyLevel: energyLevel ?? this.energyLevel,
      focusArea: focusArea ?? this.focusArea,
      gratitudeItems: gratitudeItems ?? this.gratitudeItems,
      eveningReflection: eveningReflection ?? this.eveningReflection,
      dayRating: dayRating ?? this.dayRating,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'morningIntention': morningIntention,
        'topPriorities': topPriorities,
        'timeBlocks': timeBlocks.map((b) => b.toJson()).toList(),
        'energyLevel': energyLevel,
        'focusArea': focusArea,
        'gratitudeItems': gratitudeItems,
        'eveningReflection': eveningReflection,
        'dayRating': dayRating,
        'completed': completed,
      };

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id'],
      date: DateTime.parse(json['date']),
      morningIntention: json['morningIntention'],
      topPriorities: List<String>.from(json['topPriorities'] ?? []),
      timeBlocks: (json['timeBlocks'] as List? ?? [])
          .map((b) => TimeBlock.fromJson(b))
          .toList(),
      energyLevel: json['energyLevel'] ?? 3,
      focusArea: json['focusArea'],
      gratitudeItems: List<String>.from(json['gratitudeItems'] ?? []),
      eveningReflection: json['eveningReflection'],
      dayRating: json['dayRating'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }

  factory DailyPlan.createForToday() {
    return DailyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
    );
  }
}

/// Time block for scheduling
class TimeBlock {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String title;
  final String? description;
  final TimeBlockType type;
  final String? linkedTaskId;
  final bool completed;

  const TimeBlock({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description,
    this.type = TimeBlockType.work,
    this.linkedTaskId,
    this.completed = false,
  });

  Duration get duration {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  Color get color {
    switch (type) {
      case TimeBlockType.work:
        return Colors.blue;
      case TimeBlockType.meeting:
        return Colors.purple;
      case TimeBlockType.focus:
        return Colors.orange;
      case TimeBlockType.exercise:
        return Colors.green;
      case TimeBlockType.meal:
        return Colors.amber;
      case TimeBlockType.rest:
        return Colors.teal;
      case TimeBlockType.personal:
        return Colors.pink;
      case TimeBlockType.learning:
        return Colors.indigo;
    }
  }

  IconData get icon {
    switch (type) {
      case TimeBlockType.work:
        return Icons.work;
      case TimeBlockType.meeting:
        return Icons.groups;
      case TimeBlockType.focus:
        return Icons.psychology;
      case TimeBlockType.exercise:
        return Icons.fitness_center;
      case TimeBlockType.meal:
        return Icons.restaurant;
      case TimeBlockType.rest:
        return Icons.self_improvement;
      case TimeBlockType.personal:
        return Icons.person;
      case TimeBlockType.learning:
        return Icons.school;
    }
  }

  TimeBlock copyWith({
    String? id,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? title,
    String? description,
    TimeBlockType? type,
    String? linkedTaskId,
    bool? completed,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'title': title,
        'description': description,
        'type': type.name,
        'linkedTaskId': linkedTaskId,
        'completed': completed,
      };

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id'],
      startTime: TimeOfDay(
        hour: json['startHour'],
        minute: json['startMinute'],
      ),
      endTime: TimeOfDay(
        hour: json['endHour'],
        minute: json['endMinute'],
      ),
      title: json['title'],
      description: json['description'],
      type: TimeBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TimeBlockType.work,
      ),
      linkedTaskId: json['linkedTaskId'],
      completed: json['completed'] ?? false,
    );
  }
}

enum TimeBlockType {
  work,
  meeting,
  focus,
  exercise,
  meal,
  rest,
  personal,
  learning,
}

/// Focus area presets
class FocusAreaPreset {
  final String id;
  final String name;
  final String emoji;
  final String description;

  const FocusAreaPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });

  static const List<FocusAreaPreset> presets = [
    FocusAreaPreset(
      id: 'deep_work',
      name: 'Deep Work',
      emoji: '🧠',
      description: 'Focus on cognitively demanding tasks',
    ),
    FocusAreaPreset(
      id: 'creative',
      name: 'Creative',
      emoji: '🎨',
      description: 'Express creativity and innovation',
    ),
    FocusAreaPreset(
      id: 'learning',
      name: 'Learning',
      emoji: '📚',
      description: 'Acquire new knowledge or skills',
    ),
    FocusAreaPreset(
      id: 'health',
      name: 'Health',
      emoji: '💪',
      description: 'Prioritize physical wellbeing',
    ),
    FocusAreaPreset(
      id: 'relationships',
      name: 'Relationships',
      emoji: '❤️',
      description: 'Connect with people who matter',
    ),
    FocusAreaPreset(
      id: 'organization',
      name: 'Organization',
      emoji: '📋',
      description: 'Get things in order',
    ),
    FocusAreaPreset(
      id: 'rest',
      name: 'Rest',
      emoji: '😌',
      description: 'Recharge and recover',
    ),
    FocusAreaPreset(
      id: 'adventure',
      name: 'Adventure',
      emoji: '🌟',
      description: 'Try something new',
    ),
  ];
}

/// Morning affirmation templates
class AffirmationTemplate {
  final String id;
  final String template;
  final String category;

  const AffirmationTemplate({
    required this.id,
    required this.template,
    required this.category,
  });

  static const List<AffirmationTemplate> templates = [
    AffirmationTemplate(
      id: '1',
      template: 'Today I will focus on what matters most.',
      category: 'focus',
    ),
    AffirmationTemplate(
      id: '2',
      template: 'I am capable of achieving my goals.',
      category: 'confidence',
    ),
    AffirmationTemplate(
      id: '3',
      template: 'Every task I complete brings me closer to my dreams.',
      category: 'motivation',
    ),
    AffirmationTemplate(
      id: '4',
      template: 'I embrace challenges as opportunities to grow.',
      category: 'growth',
    ),
    AffirmationTemplate(
      id: '5',
      template: 'I will be present and mindful throughout this day.',
      category: 'mindfulness',
    ),
    AffirmationTemplate(
      id: '6',
      template: 'I choose progress over perfection.',
      category: 'progress',
    ),
    AffirmationTemplate(
      id: '7',
      template: 'Today I will take one step forward.',
      category: 'action',
    ),
    AffirmationTemplate(
      id: '8',
      template: 'I am grateful for the opportunity this day brings.',
      category: 'gratitude',
    ),
  ];
}

/// Weekly review summary
class WeeklyReview {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int tasksCompleted;
  final int focusMinutes;
  final double averageDayRating;
  final List<String> topWins;
  final List<String> challenges;
  final String? nextWeekFocus;
  final List<DailyPlan> dailyPlans;

  const WeeklyReview({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    this.tasksCompleted = 0,
    this.focusMinutes = 0,
    this.averageDayRating = 0,
    this.topWins = const [],
    this.challenges = const [],
    this.nextWeekFocus,
    this.dailyPlans = const [],
  });

  int get daysPlanned => dailyPlans.where((p) => p.hasMorningPlan).length;
  int get daysReviewed => dailyPlans.where((p) => p.hasEveningReview).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekStart': weekStart.toIso8601String(),
        'weekEnd': weekEnd.toIso8601String(),
        'tasksCompleted': tasksCompleted,
        'focusMinutes': focusMinutes,
        'averageDayRating': averageDayRating,
        'topWins': topWins,
        'challenges': challenges,
        'nextWeekFocus': nextWeekFocus,
        'dailyPlans': dailyPlans.map((p) => p.toJson()).toList(),
      };

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    return WeeklyReview(
      id: json['id'],
      weekStart: DateTime.parse(json['weekStart']),
      weekEnd: DateTime.parse(json['weekEnd']),
      tasksCompleted: json['tasksCompleted'] ?? 0,
      focusMinutes: json['focusMinutes'] ?? 0,
      averageDayRating: (json['averageDayRating'] ?? 0).toDouble(),
      topWins: List<String>.from(json['topWins'] ?? []),
      challenges: List<String>.from(json['challenges'] ?? []),
      nextWeekFocus: json['nextWeekFocus'],
      dailyPlans: (json['dailyPlans'] as List? ?? [])
          .map((p) => DailyPlan.fromJson(p))
          .toList(),
    );
  }
}
