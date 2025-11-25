import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks individual task completions to prevent reward farming
/// Each completion is recorded with timestamp and rewards earned
class TaskCompletionRecord {
  final String id; // Unique completion ID
  final String userId;
  final String taskId;
  final String taskName;
  final Timestamp completedAt;
  final int coinsEarned;
  final int xpEarned;
  final bool isHabit; // True for habit, false for task

  TaskCompletionRecord({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskName,
    required this.completedAt,
    required this.coinsEarned,
    required this.xpEarned,
    required this.isHabit,
  });

  factory TaskCompletionRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskCompletionRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      taskId: data['taskId'] ?? '',
      taskName: data['taskName'] ?? '',
      completedAt: data['completedAt'] ?? Timestamp.now(),
      coinsEarned: data['coinsEarned'] ?? 0,
      xpEarned: data['xpEarned'] ?? 0,
      isHabit: data['isHabit'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'taskId': taskId,
      'taskName': taskName,
      'completedAt': completedAt,
      'coinsEarned': coinsEarned,
      'xpEarned': xpEarned,
      'isHabit': isHabit,
    };
  }
}
