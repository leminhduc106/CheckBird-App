import 'package:flutter/material.dart';

/// Pomodoro session types
enum SessionType {
  focus,
  shortBreak,
  longBreak,
}

extension SessionTypeExtension on SessionType {
  String get label {
    switch (this) {
      case SessionType.focus:
        return 'Focus';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String get emoji {
    switch (this) {
      case SessionType.focus:
        return '🎯';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🌴';
    }
  }

  Color get color {
    switch (this) {
      case SessionType.focus:
        return const Color(0xFFE53935);
      case SessionType.shortBreak:
        return const Color(0xFF43A047);
      case SessionType.longBreak:
        return const Color(0xFF1E88E5);
    }
  }

  int get defaultDurationMinutes {
    switch (this) {
      case SessionType.focus:
        return 25;
      case SessionType.shortBreak:
        return 5;
      case SessionType.longBreak:
        return 15;
    }
  }
}

/// A single focus session
class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionType type;
  final int plannedMinutes;
  final int? actualMinutes;
  final bool completed;
  final bool interrupted;
  final String? taskId;
  final String? taskName;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.type,
    required this.plannedMinutes,
    this.actualMinutes,
    this.completed = false,
    this.interrupted = false,
    this.taskId,
    this.taskName,
  });

  bool get isRunning => endTime == null;

  Duration get duration {
    if (actualMinutes != null) {
      return Duration(minutes: actualMinutes!);
    }
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get xpReward {
    if (!completed || type != SessionType.focus) return 0;
    // 2 XP per minute of focus
    return (actualMinutes ?? plannedMinutes) * 2;
  }

  int get coinReward {
    if (!completed || type != SessionType.focus) return 0;
    // Base: 5 coins + 1 per 5 minutes
    return 5 + ((actualMinutes ?? plannedMinutes) ~/ 5);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type.index,
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'completed': completed,
      'interrupted': interrupted,
      'taskId': taskId,
      'taskName': taskName,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      type: SessionType.values[json['type'] as int],
      plannedMinutes: json['plannedMinutes'] as int,
      actualMinutes: json['actualMinutes'] as int?,
      completed: json['completed'] as bool? ?? false,
      interrupted: json['interrupted'] as bool? ?? false,
      taskId: json['taskId'] as String?,
      taskName: json['taskName'] as String?,
    );
  }

  FocusSession copyWith({
    DateTime? endTime,
    int? actualMinutes,
    bool? completed,
    bool? interrupted,
  }) {
    return FocusSession(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      type: type,
      plannedMinutes: plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      completed: completed ?? this.completed,
      interrupted: interrupted ?? this.interrupted,
      taskId: taskId,
      taskName: taskName,
    );
  }
}

/// Daily focus statistics
class FocusStats {
  final DateTime date;
  final int totalFocusMinutes;
  final int sessionsCompleted;
  final int sessionsInterrupted;
  final int pomodorosCompleted;
  final int currentStreak;
  final int longestStreak;
  final int totalXpEarned;
  final int totalCoinsEarned;

  FocusStats({
    required this.date,
    this.totalFocusMinutes = 0,
    this.sessionsCompleted = 0,
    this.sessionsInterrupted = 0,
    this.pomodorosCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXpEarned = 0,
    this.totalCoinsEarned = 0,
  });

  String get formattedTime {
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get completionRate {
    final total = sessionsCompleted + sessionsInterrupted;
    if (total == 0) return 0;
    return sessionsCompleted / total;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalFocusMinutes': totalFocusMinutes,
      'sessionsCompleted': sessionsCompleted,
      'sessionsInterrupted': sessionsInterrupted,
      'pomodorosCompleted': pomodorosCompleted,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalXpEarned': totalXpEarned,
      'totalCoinsEarned': totalCoinsEarned,
    };
  }

  factory FocusStats.fromJson(Map<String, dynamic> json) {
    return FocusStats(
      date: DateTime.parse(json['date'] as String),
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      sessionsCompleted: json['sessionsCompleted'] as int? ?? 0,
      sessionsInterrupted: json['sessionsInterrupted'] as int? ?? 0,
      pomodorosCompleted: json['pomodorosCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalXpEarned: json['totalXpEarned'] as int? ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
    );
  }

  FocusStats copyWith({
    int? totalFocusMinutes,
    int? sessionsCompleted,
    int? sessionsInterrupted,
    int? pomodorosCompleted,
    int? currentStreak,
    int? longestStreak,
    int? totalXpEarned,
    int? totalCoinsEarned,
  }) {
    return FocusStats(
      date: date,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      sessionsInterrupted: sessionsInterrupted ?? this.sessionsInterrupted,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
    );
  }
}

/// Focus timer settings
class FocusSettings {
  final int focusDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? selectedAmbientSound;

  const FocusSettings({
    this.focusDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.selectedAmbientSound,
  });

  Map<String, dynamic> toJson() {
    return {
      'focusDuration': focusDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'sessionsBeforeLongBreak': sessionsBeforeLongBreak,
      'autoStartBreaks': autoStartBreaks,
      'autoStartFocus': autoStartFocus,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'selectedAmbientSound': selectedAmbientSound,
    };
  }

  factory FocusSettings.fromJson(Map<String, dynamic> json) {
    return FocusSettings(
      focusDuration: json['focusDuration'] as int? ?? 25,
      shortBreakDuration: json['shortBreakDuration'] as int? ?? 5,
      longBreakDuration: json['longBreakDuration'] as int? ?? 15,
      sessionsBeforeLongBreak: json['sessionsBeforeLongBreak'] as int? ?? 4,
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? false,
      autoStartFocus: json['autoStartFocus'] as bool? ?? false,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      selectedAmbientSound: json['selectedAmbientSound'] as String?,
    );
  }

  FocusSettings copyWith({
    int? focusDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? selectedAmbientSound,
  }) {
    return FocusSettings(
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      selectedAmbientSound: selectedAmbientSound ?? this.selectedAmbientSound,
    );
  }
}

/// Ambient sound options for focus
class AmbientSound {
  final String id;
  final String name;
  final String emoji;
  final String? assetPath;

  const AmbientSound({
    required this.id,
    required this.name,
    required this.emoji,
    this.assetPath,
  });

  static const List<AmbientSound> allSounds = [
    AmbientSound(id: 'none', name: 'None', emoji: '🔇'),
    AmbientSound(id: 'rain', name: 'Rain', emoji: '🌧️'),
    AmbientSound(id: 'forest', name: 'Forest', emoji: '🌲'),
    AmbientSound(id: 'ocean', name: 'Ocean Waves', emoji: '🌊'),
    AmbientSound(id: 'fireplace', name: 'Fireplace', emoji: '🔥'),
    AmbientSound(id: 'coffee_shop', name: 'Coffee Shop', emoji: '☕'),
    AmbientSound(id: 'wind', name: 'Wind', emoji: '💨'),
    AmbientSound(id: 'birds', name: 'Birds', emoji: '🐦'),
    AmbientSound(id: 'thunder', name: 'Thunderstorm', emoji: '⛈️'),
    AmbientSound(id: 'white_noise', name: 'White Noise', emoji: '📺'),
  ];
}
