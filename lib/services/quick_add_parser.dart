import 'package:check_bird/models/priority/task_priority.dart';

/// Result of parsing natural language text for task creation
class ParsedTaskInput {
  final String taskName;
  final String? description;
  final DateTime? deadline;
  final DateTime? reminder;
  final TaskPriority priority;
  final List<bool>? weekdays;
  final bool isHabit;
  final List<String> tags;

  ParsedTaskInput({
    required this.taskName,
    this.description,
    this.deadline,
    this.reminder,
    this.priority = TaskPriority.p4,
    this.weekdays,
    this.isHabit = false,
    this.tags = const [],
  });

  @override
  String toString() {
    return 'ParsedTaskInput(taskName: $taskName, deadline: $deadline, priority: $priority, isHabit: $isHabit)';
  }
}

/// Service to parse natural language input for task creation
/// Similar to Todoist's smart date recognition
class QuickAddParser {
  static final QuickAddParser _instance = QuickAddParser._internal();
  factory QuickAddParser() => _instance;
  QuickAddParser._internal();

  /// Parse natural language text into structured task data
  /// Examples:
  /// - "Buy groceries tomorrow at 3pm p1" → deadline tomorrow 3pm, priority P1
  /// - "Meeting with John on Friday at 10am !!" → deadline Friday 10am, priority P2
  /// - "Daily workout every day" → habit with all weekdays
  /// - "Call mom next Monday" → deadline next Monday
  ParsedTaskInput parse(String input) {
    var text = input.trim();
    DateTime? deadline;
    DateTime? reminder;
    TaskPriority priority = TaskPriority.p4;
    List<bool>? weekdays;
    bool isHabit = false;
    List<String> tags = [];

    // Extract priority
    final priorityResult = _extractPriority(text);
    text = priorityResult.$1;
    priority = priorityResult.$2;

    // Extract tags (words starting with #)
    final tagResult = _extractTags(text);
    text = tagResult.$1;
    tags = tagResult.$2;

    // Check for habit patterns
    final habitResult = _extractHabitPattern(text);
    text = habitResult.$1;
    if (habitResult.$2 != null) {
      isHabit = true;
      weekdays = habitResult.$2;
    }

    // Extract date and time
    if (!isHabit) {
      final dateResult = _extractDateTime(text);
      text = dateResult.$1;
      deadline = dateResult.$2;
    }

    // Extract reminder
    final reminderResult = _extractReminder(text);
    text = reminderResult.$1;
    reminder = reminderResult.$2;

    // Clean up the remaining text as task name
    text = text.trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return ParsedTaskInput(
      taskName: text,
      deadline: deadline,
      reminder: reminder,
      priority: priority,
      weekdays: weekdays,
      isHabit: isHabit,
      tags: tags,
    );
  }

  /// Extract priority from text
  (String, TaskPriority) _extractPriority(String text) {
    // Check for !!! (urgent/P1)
    if (text.contains('!!!') ||
        text.contains('p1') ||
        text.toLowerCase().contains('urgent')) {
      text =
          text.replaceAll(RegExp(r'!!!|p1|urgent', caseSensitive: false), '');
      return (text, TaskPriority.p1);
    }

    // Check for !! (high/P2)
    if (text.contains('!!') ||
        text.contains('p2') ||
        text.toLowerCase().contains('important')) {
      text =
          text.replaceAll(RegExp(r'!!|p2|important', caseSensitive: false), '');
      return (text, TaskPriority.p2);
    }

    // Check for ! (medium/P3)
    if (RegExp(r'(?<!!)\!(?!!)').hasMatch(text) ||
        text.toLowerCase().contains('p3') ||
        text.toLowerCase().contains('medium priority')) {
      text = text.replaceAll(
          RegExp(r'(?<!!)\!(?!!)|p3|medium priority', caseSensitive: false),
          '');
      return (text, TaskPriority.p3);
    }

    // Check for p4 or low priority
    if (text.toLowerCase().contains('p4') ||
        text.toLowerCase().contains('low priority')) {
      text =
          text.replaceAll(RegExp(r'p4|low priority', caseSensitive: false), '');
      return (text, TaskPriority.p4);
    }

    return (text, TaskPriority.p4);
  }

  /// Extract tags from text
  (String, List<String>) _extractTags(String text) {
    final tags = <String>[];
    final tagPattern = RegExp(r'#(\w+)');
    final matches = tagPattern.allMatches(text);

    for (final match in matches) {
      tags.add(match.group(1)!);
    }

    text = text.replaceAll(tagPattern, '');
    return (text, tags);
  }

  /// Extract habit pattern from text
  (String, List<bool>?) _extractHabitPattern(String text) {
    final lowerText = text.toLowerCase();

    // Check for "every day" or "daily"
    if (lowerText.contains('every day') || lowerText.contains('daily')) {
      text = text.replaceAll(
          RegExp(r'every\s*day|daily', caseSensitive: false), '');
      return (text, List.filled(7, true));
    }

    // Check for weekday patterns
    if (lowerText.contains('weekdays') || lowerText.contains('every weekday')) {
      text = text.replaceAll(
          RegExp(r'every\s*weekdays?|weekdays?', caseSensitive: false), '');
      return (text, [true, true, true, true, true, false, false]);
    }

    // Check for weekend patterns
    if (lowerText.contains('weekends') || lowerText.contains('every weekend')) {
      text = text.replaceAll(
          RegExp(r'every\s*weekends?|weekends?', caseSensitive: false), '');
      return (text, [false, false, false, false, false, true, true]);
    }

    // Check for specific days "every monday and wednesday"
    final dayPattern = RegExp(
      r'every\s+((?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s*(?:,|and)\s*(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))*)',
      caseSensitive: false,
    );

    final match = dayPattern.firstMatch(lowerText);
    if (match != null) {
      final daysString = match.group(1)!;
      final weekdays = [false, false, false, false, false, false, false];

      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      for (int i = 0; i < dayNames.length; i++) {
        if (daysString.contains(dayNames[i])) {
          weekdays[i] = true;
        }
      }

      text = text.replaceAll(dayPattern, '');
      return (text, weekdays);
    }

    return (text, null);
  }

  /// Extract date and time from text
  (String, DateTime?) _extractDateTime(String text) {
    final now = DateTime.now();
    final lowerText = text.toLowerCase();
    DateTime? result;

    // Check for "today"
    if (lowerText.contains('today')) {
      text = text.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
      result = DateTime(now.year, now.month, now.day, 23, 59);
    }

    // Check for "tomorrow"
    else if (lowerText.contains('tomorrow')) {
      text = text.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '');
      final tomorrow = now.add(const Duration(days: 1));
      result = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
    }

    // Check for "next week"
    else if (lowerText.contains('next week')) {
      text =
          text.replaceAll(RegExp(r'\bnext\s+week\b', caseSensitive: false), '');
      final nextWeek = now.add(const Duration(days: 7));
      result = DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 23, 59);
    }

    // Check for specific day name "on monday", "next friday"
    else {
      final dayNames = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ];
      for (int i = 0; i < dayNames.length; i++) {
        final pattern = RegExp(r'\b(on\s+|next\s+)?' + dayNames[i] + r'\b',
            caseSensitive: false);
        if (pattern.hasMatch(lowerText)) {
          text = text.replaceAll(pattern, '');

          // Calculate the date for this weekday
          final targetDay = i + 1; // Monday = 1, Sunday = 7
          var daysUntil = targetDay - now.weekday;
          if (daysUntil <= 0) {
            daysUntil += 7; // Next occurrence
          }

          final targetDate = now.add(Duration(days: daysUntil));
          result = DateTime(
              targetDate.year, targetDate.month, targetDate.day, 23, 59);
          break;
        }
      }
    }

    // Check for "in X days"
    final inDaysPattern =
        RegExp(r'\bin\s+(\d+)\s*days?\b', caseSensitive: false);
    final inDaysMatch = inDaysPattern.firstMatch(lowerText);
    if (inDaysMatch != null) {
      text = text.replaceAll(inDaysPattern, '');
      final days = int.parse(inDaysMatch.group(1)!);
      final targetDate = now.add(Duration(days: days));
      result =
          DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59);
    }

    // Check for specific date "Dec 25", "25 Dec", "12/25"
    final datePatterns = [
      RegExp(
          r'\b(\d{1,2})[/\-](\d{1,2})(?:[/\-](\d{2,4}))?\b'), // 12/25 or 12-25
      RegExp(
          r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,?\s*(\d{4}))?\b',
          caseSensitive: false), // Dec 25
      RegExp(
          r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*(?:\s*,?\s*(\d{4}))?\b',
          caseSensitive: false), // 25 Dec
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.replaceAll(pattern, '');
        result = _parseDateMatch(match, now);
        break;
      }
    }

    // Extract time if present and apply to result
    if (result != null) {
      final timeResult = _extractTime(text);
      text = timeResult.$1;
      if (timeResult.$2 != null) {
        result = DateTime(
          result.year,
          result.month,
          result.day,
          timeResult.$2!.hour,
          timeResult.$2!.minute,
        );
      }
    } else {
      // Check for time only (implies today)
      final timeResult = _extractTime(text);
      if (timeResult.$2 != null) {
        text = timeResult.$1;
        result = DateTime(
          now.year,
          now.month,
          now.day,
          timeResult.$2!.hour,
          timeResult.$2!.minute,
        );
      }
    }

    return (text, result);
  }

  /// Parse date from regex match
  DateTime? _parseDateMatch(RegExpMatch match, DateTime now) {
    try {
      final groups = match.groups([1, 2, 3]);

      int? month;
      int? day;
      int year = now.year;

      // Determine format based on content
      final first = groups[0]?.toLowerCase();
      final second = groups[1]?.toLowerCase();
      final third = groups[2];

      if (first != null) {
        if (int.tryParse(first) != null) {
          // Numeric format
          month = int.parse(first);
          day = int.tryParse(second ?? '');
        } else {
          // Month name format
          month = _parseMonthName(first);
          day = int.tryParse(second ?? '');
        }
      }

      if (second != null && month == null) {
        month = _parseMonthName(second);
        day = int.tryParse(first ?? '');
      }

      if (third != null) {
        year = int.parse(third);
        if (year < 100) year += 2000;
      }

      if (month != null && day != null) {
        return DateTime(year, month, day, 23, 59);
      }
    } catch (e) {
      // Parsing failed, return null
    }
    return null;
  }

  /// Parse month name to number
  int? _parseMonthName(String name) {
    final months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return months[name.toLowerCase()];
  }

  /// Extract time from text
  (String, DateTime?) _extractTime(String text) {
    // Pattern for time: "at 3pm", "3:30pm", "15:00"
    final timePatterns = [
      RegExp(r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
          caseSensitive: false),
      RegExp(r'\b(\d{1,2}):(\d{2})\s*(am|pm)?\b', caseSensitive: false),
      RegExp(r'\b(\d{1,2})\s*(am|pm)\b', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        text = text.replaceAll(pattern, '');

        int hour = int.parse(match.group(1)!);
        int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
        final ampm = match
            .groups([2, 3])
            .whereType<String>()
            .firstWhere(
              (g) => g.toLowerCase() == 'am' || g.toLowerCase() == 'pm',
              orElse: () => '',
            )
            .toLowerCase();

        // Convert to 24-hour format
        if (ampm == 'pm' && hour != 12) {
          hour += 12;
        } else if (ampm == 'am' && hour == 12) {
          hour = 0;
        }

        return (text, DateTime(2000, 1, 1, hour, minute));
      }
    }

    return (text, null);
  }

  /// Extract reminder from text
  (String, DateTime?) _extractReminder(String text) {
    // Pattern for reminder: "remind me", "reminder"
    final reminderPattern = RegExp(
      r'\b(remind(?:\s*me)?|reminder)\s+(.*?)(?=\s+(?:at|on|tomorrow|today)|$)',
      caseSensitive: false,
    );

    final match = reminderPattern.firstMatch(text);
    if (match != null) {
      text = text.replaceAll(reminderPattern, '');
      // For now, just set reminder to the deadline time
      // In a full implementation, this would parse "remind me 1 hour before"
    }

    return (text, null);
  }

  /// Get suggestions based on partial input
  List<String> getSuggestions(String input) {
    if (input.isEmpty) return [];

    final suggestions = <String>[];
    final lowerInput = input.toLowerCase();

    // Date suggestions
    if (lowerInput.contains('tom') && !lowerInput.contains('tomorrow')) {
      suggestions.add('$input tomorrow');
    }
    if (lowerInput.contains('tod') && !lowerInput.contains('today')) {
      suggestions.add('$input today');
    }
    if (lowerInput.contains('next') && !lowerInput.contains('next ')) {
      suggestions.addAll([
        '$input next week',
        '$input next monday',
        '$input next friday',
      ]);
    }

    // Priority suggestions
    if (!lowerInput.contains('p1') && !lowerInput.contains('p2')) {
      suggestions.add('$input p1');
      suggestions.add('$input p2');
    }

    // Habit suggestions
    if (lowerInput.contains('every') && !lowerInput.contains('every ')) {
      suggestions.addAll([
        '$input every day',
        '$input every weekday',
        '$input every monday',
      ]);
    }

    return suggestions.take(5).toList();
  }
}
