import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.createdAt,
    required this.likeCount,
    this.isLegacy = false,
  });

  final String id;
  final String text;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final Timestamp createdAt;
  final int likeCount;
  final bool isLegacy;
}
