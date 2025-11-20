import 'dart:async';
import 'dart:io';
import 'package:check_bird/screens/group_detail/models/comment.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ntp/ntp.dart';

class CommentsController {
  CollectionReference _commentsRef(String groupId, String postId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId)
        .collection('comments');
  }

  CollectionReference _legacyChatRef(String groupId, String postId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('topics')
        .doc(postId)
        .collection('chat');
  }

  Future<void> addComment({
    required String groupId,
    required String postId,
    required String text,
    File? imageFile,
    String? parentCommentId,
    String? replyToUserName,
    String? replyToText,
  }) async {
    final commentsRef = _commentsRef(groupId, postId);
    final postRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId);
    final user = Authentication.user!;
    final now = Timestamp.fromDate(await NTP.now());
    final displayName = (user.displayName ?? '').trim();
    // Pre-generate comment doc ID so we can upload image first if needed
    final newCommentRef = commentsRef.doc();
    String? uploadedImageUrl;
    if (imageFile != null) {
      try {
        final storagePath =
            'groups/$groupId/posts/$postId/comments/${newCommentRef.id}.jpg';
        final task = await FirebaseStorage.instance
            .ref(storagePath)
            .putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
        uploadedImageUrl = await task.ref.getDownloadURL();
      } catch (e) {}
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) {
        throw StateError('Post does not exist');
      }
      final postData = postSnapshot.data()!;
      final chatCountValue = postData['chatCount'];
      final currentCount = chatCountValue is num ? chatCountValue.toInt() : 0;

      final commentData = <String, dynamic>{
        'text': text,
        'userId': user.uid,
        'userName': displayName.isNotEmpty
            ? displayName
            : (user.email ?? 'CheckBird member'),
        'userAvatarUrl': user.photoURL ?? '',
        'createdAt': now,
        'likeCount': 0,
      };
      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        commentData['parentId'] = parentCommentId;
        if (replyToUserName != null)
          commentData['replyToUserName'] = replyToUserName;
        if (replyToText != null) commentData['replyToText'] = replyToText;
      }
      if (uploadedImageUrl != null) {
        commentData['imageUrl'] = uploadedImageUrl;
      }

      transaction.set(newCommentRef, commentData);
      transaction.update(postRef, {
        'chatCount': currentCount + 1,
      });
    });
  }

  Future<void> likeComment({
    required String groupId,
    required String postId,
    required String commentId,
  }) async {
    final commentRef = _commentsRef(groupId, postId).doc(commentId);
    final likeRef =
        commentRef.collection('likes').doc(Authentication.user!.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeRef);
      final commentSnapshot = await transaction.get(commentRef);
      final commentData = commentSnapshot.data()! as Map<String, dynamic>;

      if (likeSnapshot.exists) {
        // Unlike
        transaction.delete(likeRef);
        transaction.update(commentRef, {
          'likeCount': commentData['likeCount'] - 1,
        });
      } else {
        // Like
        transaction.set(likeRef, {
          'createdAt': Timestamp.now(),
        });
        transaction.update(commentRef, {
          'likeCount': commentData['likeCount'] + 1,
        });
      }
    });
  }

  Future<bool> isCommentLiked({
    required String groupId,
    required String postId,
    required String commentId,
  }) async {
    final likeRef = _commentsRef(groupId, postId)
        .doc(commentId)
        .collection('likes')
        .doc(Authentication.user!.uid);

    final snapshot = await likeRef.get();
    return snapshot.exists;
  }

  Stream<List<Comment>> commentsStream(String groupId, String postId) {
    final controller = StreamController<List<Comment>>.broadcast();
    List<Comment> modernComments = const [];
    List<Comment> legacyComments = const [];

    void emit() {
      if (controller.isClosed) return;
      final merged = <Comment>[...legacyComments, ...modernComments]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      controller.add(merged);
    }

    final modernSub = _commentsRef(groupId, postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      modernComments = snapshot.docs.map((doc) {
        final data = doc.data()! as Map<String, dynamic>;
        final createdAt = _timestampFromValue(data['createdAt']);
        final likeValue = data['likeCount'];
        final likeCount = likeValue is num ? likeValue.toInt() : 0;
        return Comment(
          id: doc.id,
          text: data['text'] ?? '',
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? '',
          userAvatarUrl: (data['userAvatarUrl'] ?? '').toString(),
          createdAt: createdAt,
          likeCount: likeCount,
          imageUrl: (data['imageUrl'] ?? '').toString().isEmpty
              ? null
              : (data['imageUrl'] as String),
          parentId: (data['parentId'] ?? '').toString().isEmpty
              ? null
              : (data['parentId'] as String),
          replyToUserName: (data['replyToUserName'] ?? '').toString().isEmpty
              ? null
              : (data['replyToUserName'] as String),
          replyToText: (data['replyToText'] ?? '').toString().isEmpty
              ? null
              : (data['replyToText'] as String),
        );
      }).toList();
      emit();
    }, onError: controller.addError);

    final legacySub = _legacyChatRef(groupId, postId)
        .orderBy('created', descending: false)
        .snapshots()
        .listen((snapshot) {
      legacyComments = snapshot.docs.map((doc) {
        final data = doc.data()! as Map<String, dynamic>;
        final createdAt = _timestampFromValue(data['created']);
        return Comment(
          id: 'legacy_${doc.id}',
          text: _legacyMessageText(data),
          userId: (data['userId'] ?? '').toString(),
          userName: (data['userName'] ?? 'CheckBird member').toString(),
          userAvatarUrl: (data['userImageUrl'] ?? '').toString(),
          createdAt: createdAt,
          likeCount: 0,
          isLegacy: true,
        );
      }).toList();
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await modernSub.cancel();
      await legacySub.cancel();
    };

    return controller.stream;
  }

  Timestamp _timestampFromValue(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }
    return Timestamp.now();
  }

  String _legacyMessageText(Map<String, dynamic> data) {
    final type = (data['type'] ?? 'text').toString();
    final raw = data['data'];
    if (type == 'text') {
      return (raw ?? '').toString();
    }
    final label = type.isEmpty
        ? 'Attachment'
        : '${type[0].toUpperCase()}${type.substring(1)}';
    return '[$label message]';
  }
}
