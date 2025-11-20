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
    this.imageUrl,
    this.parentId,
    this.replyToUserName,
    this.replyToText,
  });

  final String id;
  final String text;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final Timestamp createdAt;
  final int likeCount;
  final bool isLegacy;
  final String? imageUrl;
  final String?
      parentId; // when set, this comment is a reply to another comment
  final String? replyToUserName; // cached for fast UI display
  final String? replyToText; // small snippet of the original comment
}
