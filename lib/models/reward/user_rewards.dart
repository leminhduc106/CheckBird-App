import 'package:cloud_firestore/cloud_firestore.dart';

/// User's reward stats stored in Firestore
/// Tracks coins, gems, XP, level, and daily login info
class UserRewards {
  final String userId;
  final int coins;
  final int gems;
  final int xp;
  final int level;
  final int totalTasksCompleted;
  final int totalHabitsCompleted;
  final Timestamp? lastLoginDate;
  final int currentLoginStreak;
  final int longestLoginStreak;
  final Timestamp? lastRewardEarnedAt;

  UserRewards({
    required this.userId,
    this.coins = 0,
    this.gems = 0,
    this.xp = 0,
    this.level = 1,
    this.totalTasksCompleted = 0,
    this.totalHabitsCompleted = 0,
    this.lastLoginDate,
    this.currentLoginStreak = 0,
    this.longestLoginStreak = 0,
    this.lastRewardEarnedAt,
  });

  /// Calculate level from XP (exponential curve)
  /// Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, etc.
  static int calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 1000) return 4;
    if (xp < 2000) return 5;
    if (xp < 3500) return 6;
    if (xp < 5500) return 7;
    if (xp < 8000) return 8;
    if (xp < 11000) return 9;
    if (xp < 15000) return 10;

    // For levels above 10, use formula: level = 10 + floor((xp - 15000) / 2000)
    return 10 + ((xp - 15000) ~/ 2000);
  }

  /// XP needed to reach next level
  int get xpForNextLevel {
    final currentLevelXp = _getXpForLevel(level);
    final nextLevelXp = _getXpForLevel(level + 1);
    return nextLevelXp - currentLevelXp;
  }

  /// Current progress towards next level (0.0 to 1.0)
  double get levelProgress {
    if (level == 1 && xp < 100) {
      return xp / 100.0;
    }
    final currentLevelXp = _getXpForLevel(level);
    final nextLevelXp = _getXpForLevel(level + 1);
    final progressXp = xp - currentLevelXp;
    return (progressXp / (nextLevelXp - currentLevelXp)).clamp(0.0, 1.0);
  }

  static int _getXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 250;
    if (level == 4) return 500;
    if (level == 5) return 1000;
    if (level == 6) return 2000;
    if (level == 7) return 3500;
    if (level == 8) return 5500;
    if (level == 9) return 8000;
    if (level == 10) return 11000;
    if (level == 11) return 15000;
    return 15000 + ((level - 11) * 2000);
  }

  factory UserRewards.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final xp = data['xp'] ?? 0;
    return UserRewards(
      userId: doc.id,
      coins: data['coins'] ?? 0,
      gems: data['gems'] ?? 0,
      xp: xp,
      level: calculateLevel(xp),
      totalTasksCompleted: data['totalTasksCompleted'] ?? 0,
      totalHabitsCompleted: data['totalHabitsCompleted'] ?? 0,
      lastLoginDate: data['lastLoginDate'],
      currentLoginStreak: data['currentLoginStreak'] ?? 0,
      longestLoginStreak: data['longestLoginStreak'] ?? 0,
      lastRewardEarnedAt: data['lastRewardEarnedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coins': coins,
      'gems': gems,
      'xp': xp,
      'level': level,
      'totalTasksCompleted': totalTasksCompleted,
      'totalHabitsCompleted': totalHabitsCompleted,
      'lastLoginDate': lastLoginDate,
      'currentLoginStreak': currentLoginStreak,
      'longestLoginStreak': longestLoginStreak,
      'lastRewardEarnedAt': lastRewardEarnedAt,
    };
  }

  UserRewards copyWith({
    int? coins,
    int? gems,
    int? xp,
    int? level,
    int? totalTasksCompleted,
    int? totalHabitsCompleted,
    Timestamp? lastLoginDate,
    int? currentLoginStreak,
    int? longestLoginStreak,
    Timestamp? lastRewardEarnedAt,
  }) {
    return UserRewards(
      userId: userId,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      currentLoginStreak: currentLoginStreak ?? this.currentLoginStreak,
      longestLoginStreak: longestLoginStreak ?? this.longestLoginStreak,
      lastRewardEarnedAt: lastRewardEarnedAt ?? this.lastRewardEarnedAt,
    );
  }
}
