import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:check_bird/models/chat/chat_type.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/widgets/chat/models/media_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ntp/ntp.dart';
import 'package:uuid/uuid.dart';

class Message {
  const Message({
    required this.isMe,
    required this.userId,
    required this.created,
    required this.data,
    required this.userImageUrl,
    required this.userName,
    required this.id,
    required this.mediaType,
    this.replyToMessageId,
    this.replyToUserName,
    this.replyToText,
    this.replyToMediaType,
    this.reactions = const {},
  });

  final MediaType mediaType;
  final String id;
  final String userName;
  final bool isMe;
  final Timestamp created;
  final String data;
  final String userId;
  final String userImageUrl;
  final String? replyToMessageId;
  final String? replyToUserName;
  final String? replyToText;
  final MediaType? replyToMediaType;
  // Map of emoji -> list of user IDs who reacted with that emoji
  final Map<String, List<String>> reactions;
}

class MessagesController {
  CollectionReference _textRef(
      ChatType chatType, String groupId, String? topicId) {
    var db = FirebaseFirestore.instance;
    late CollectionReference ref;
    if (chatType == ChatType.groupChat) {
      ref = db.collection('groups').doc(groupId).collection('chat');
    } else {
      ref = db
          .collection('groups')
          .doc(groupId)
          .collection('topics')
          .doc(topicId!)
          .collection('chat');
    }
    return ref;
  }

  Future<void> sendImg({
    required File image,
    required ChatType chatType,
    required String groupId,
    String? topicId,
  }) async {
    var ref = FirebaseStorage.instance
        .ref()
        .child('img')
        .child(groupId)
        .child('group-chat');
    if (chatType == ChatType.topicChat) {
      ref = ref.child(topicId!);
    }
    var imgName = const Uuid().v4();
    ref = ref.child('$imgName.jpg');
    TaskSnapshot storageTaskSnapshot = await ref.putFile(image);
    var dowUrl = await storageTaskSnapshot.ref.getDownloadURL();
    sendChat(
        data: dowUrl,
        chatType: chatType,
        groupId: groupId,
        topicId: topicId,
        mediaType: MediaType.image);
  }

  Future<void> sendVoice({
    required File audioFile,
    required int durationMs,
    required ChatType chatType,
    required String groupId,
    String? topicId,
    Message? replyTo,
  }) async {
    var ref = FirebaseStorage.instance
        .ref()
        .child('voice')
        .child(groupId)
        .child('group-chat');
    if (chatType == ChatType.topicChat) {
      ref = ref.child(topicId!);
    }
    var voiceName = const Uuid().v4();
    ref = ref.child('$voiceName.m4a');
    TaskSnapshot storageTaskSnapshot = await ref.putFile(audioFile);
    var dowUrl = await storageTaskSnapshot.ref.getDownloadURL();

    // Store URL with duration as JSON-like string: "url|duration"
    final dataWithDuration = '$dowUrl|$durationMs';

    await sendChat(
      data: dataWithDuration,
      chatType: chatType,
      groupId: groupId,
      topicId: topicId,
      mediaType: MediaType.voice,
      replyTo: replyTo,
    );
  }

  Future<void> sendChat(
      {required String data,
      required ChatType chatType,
      required String groupId,
      String? topicId,
      required MediaType mediaType,
      Message? replyTo}) async {
    var ref = _textRef(chatType, groupId, topicId);

    late String type;
    if (mediaType == MediaType.text) {
      type = 'text';
    } else if (mediaType == MediaType.image) {
      type = 'image';
    } else if (mediaType == MediaType.voice) {
      type = 'voice';
    }
    // If there is send video feature in the future, another if check is needed here
    if (chatType == ChatType.topicChat) {
      var topicRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('post')
          .doc(topicId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(topicRef);
        final data = postSnapshot.data()! as Map<String, dynamic>;
        transaction.update(topicRef, {
          "chatCount": data['chatCount'] + 1,
        });
      });
    }

    final payload = {
      'type': type,
      'data': data,
      'userId': Authentication.user!.uid,
      'userName': Authentication.user!.displayName,
      'created': await NTP.now(),
      'userImageUrl': Authentication.user!.photoURL ?? '',
    };
    if (replyTo != null) {
      payload['replyToMessageId'] = replyTo.id;
      payload['replyToUserName'] = replyTo.userName;
      payload['replyToText'] = replyTo.data;
      payload['replyToMediaType'] = replyTo.mediaType.name;
    }
    await ref.add(payload);
  }

  Stream<List<Message>> messagesStream(
      ChatType chatType, String groupId, String? topicId) {
    var ref = _textRef(chatType, groupId, topicId);
    return ref.orderBy('created', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((msg) {
        var msgData = msg.data()! as Map<String, dynamic>;
        late MediaType type;
        if (msgData['type'] == 'text') {
          type = MediaType.text;
        } else if (msgData['type'] == 'image') {
          type = MediaType.image;
        } else if (msgData['type'] == 'voice') {
          type = MediaType.voice;
        } else {
          type = MediaType.text; // Default fallback
        }

        // Parse reactions from Firestore
        // New format: Map<emoji, Map<userId, userName>>
        // Old format: Map<emoji, List<userId>> for backward compatibility
        Map<String, List<String>> reactions = {};
        if (msgData['reactions'] != null) {
          final reactionsData = msgData['reactions'] as Map<String, dynamic>;
          reactionsData.forEach((emoji, value) {
            if (value is Map) {
              // New format: Map<userId, userName>
              reactions[emoji] = (value as Map<String, dynamic>).keys.toList();
            } else if (value is List) {
              // Old format: List<userId> (backward compatibility)
              reactions[emoji] = value.map((id) => id.toString()).toList();
            }
          });
        }

        return Message(
          mediaType: type,
          id: msg.id,
          created: msgData['created'],
          data: msgData['data'].toString(),
          isMe: Authentication.user!.uid == msgData['userId'],
          userId: msgData['userId'],
          userImageUrl: (msgData['userImageUrl'] ?? '').toString(),
          userName: msgData['userName'],
          replyToMessageId:
              (msgData['replyToMessageId'] ?? '').toString().isEmpty
                  ? null
                  : msgData['replyToMessageId'],
          replyToUserName: (msgData['replyToUserName'] ?? '').toString().isEmpty
              ? null
              : msgData['replyToUserName'],
          replyToText: (msgData['replyToText'] ?? '').toString().isEmpty
              ? null
              : msgData['replyToText'],
          replyToMediaType:
              (msgData['replyToMediaType'] ?? '').toString().isEmpty
                  ? null
                  : (msgData['replyToMediaType'] == 'image'
                      ? MediaType.image
                      : msgData['replyToMediaType'] == 'voice'
                          ? MediaType.voice
                          : MediaType.text),
          reactions: reactions,
        );
      }).toList();
    });
  }

  // Add or update a reaction to a message
  // Single reaction per user (like WhatsApp/iMessage) - selecting new emoji replaces old one
  Future<void> addReaction({
    required String messageId,
    required String emoji,
    required ChatType chatType,
    required String groupId,
    String? topicId,
  }) async {
    final userId = Authentication.user!.uid;
    final userName = Authentication.user!.displayName ?? 'Unknown User';
    final messageRef = _textRef(chatType, groupId, topicId).doc(messageId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final messageDoc = await transaction.get(messageRef);
      if (!messageDoc.exists) return;

      final data = messageDoc.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      // Store reactions as Map<emoji, Map<userId, userName>>
      // This allows us to get usernames without extra queries

      // Check if user already has this exact emoji (for toggle)
      bool hasThisEmoji = false;
      if (reactions[emoji] != null && reactions[emoji] is Map) {
        final emojiMap = reactions[emoji] as Map<String, dynamic>;
        hasThisEmoji = emojiMap.containsKey(userId);
      }

      // Remove user's previous reactions from ALL emojis (single reaction per user)
      final keysToRemove = <String>[];
      reactions.forEach((emojiKey, value) {
        if (value is Map) {
          final reactionMap = Map<String, dynamic>.from(value);
          reactionMap.remove(userId);
          if (reactionMap.isEmpty) {
            keysToRemove.add(emojiKey);
          } else {
            reactions[emojiKey] = reactionMap;
          }
        }
      });

      // Remove empty emoji entries
      for (final key in keysToRemove) {
        reactions.remove(key);
      }

      // If user already had this exact emoji, it's a toggle to remove - don't add it back
      if (!hasThisEmoji) {
        // Add the new reaction
        Map<String, dynamic> emojiReactions = {};
        if (reactions[emoji] != null && reactions[emoji] is Map) {
          emojiReactions = Map<String, dynamic>.from(reactions[emoji]);
        }
        emojiReactions[userId] = userName;
        reactions[emoji] = emojiReactions;
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  // Remove a specific user's reaction
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
    required ChatType chatType,
    required String groupId,
    String? topicId,
  }) async {
    final userId = Authentication.user!.uid;
    final messageRef = _textRef(chatType, groupId, topicId).doc(messageId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final messageDoc = await transaction.get(messageRef);
      if (!messageDoc.exists) return;

      final data = messageDoc.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      if (reactions[emoji] != null) {
        List<String> userIds = List<String>.from(reactions[emoji]);
        userIds.remove(userId);

        if (userIds.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = userIds;
        }
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  // Delete a message
  Future<void> deleteMessage({
    required String messageId,
    required ChatType chatType,
    required String groupId,
    String? topicId,
  }) async {
    final messageRef = _textRef(chatType, groupId, topicId).doc(messageId);

    // Get the message to check if it has media to delete from storage
    final messageDoc = await messageRef.get();
    if (messageDoc.exists) {
      final data = messageDoc.data() as Map<String, dynamic>;
      final type = data['type'];
      final messageData = data['data'] as String?;

      // Delete associated media from Firebase Storage
      if (messageData != null && (type == 'image' || type == 'voice')) {
        try {
          String url = messageData;
          // For voice messages, extract URL from "url|duration" format
          if (type == 'voice' && messageData.contains('|')) {
            url = messageData.split('|').first;
          }
          // Delete from Firebase Storage
          final ref = FirebaseStorage.instance.refFromURL(url);
          await ref.delete();
        } catch (e) {
          // Ignore storage deletion errors (file might not exist)
          debugPrint('Error deleting media from storage: $e');
        }
      }

      // Decrement chat count for topic chats
      if (chatType == ChatType.topicChat) {
        var topicRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('post')
            .doc(topicId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot postSnapshot = await transaction.get(topicRef);
          if (postSnapshot.exists) {
            final postData = postSnapshot.data()! as Map<String, dynamic>;
            final currentCount = postData['chatCount'] ?? 0;
            if (currentCount > 0) {
              transaction.update(topicRef, {
                "chatCount": currentCount - 1,
              });
            }
          }
        });
      }
    }

    // Delete the message document
    await messageRef.delete();
  }

  // Get user names for reaction details
  Future<List<String>> getUserNamesForReaction({
    required String messageId,
    required String emoji,
    required ChatType chatType,
    required String groupId,
    String? topicId,
  }) async {
    final messageRef = _textRef(chatType, groupId, topicId).doc(messageId);
    final messageDoc = await messageRef.get();

    if (!messageDoc.exists) return [];

    final data = messageDoc.data() as Map<String, dynamic>;
    final reactions = data['reactions'] as Map<String, dynamic>? ?? {};

    if (!reactions.containsKey(emoji)) return [];

    final emojiReactions = reactions[emoji];

    // New format: Map<userId, userName>
    if (emojiReactions is Map) {
      return (emojiReactions as Map<String, dynamic>)
          .values
          .map((name) => name.toString())
          .toList();
    }

    // Old format fallback: List<userId> - try to get names from messages
    if (emojiReactions is List) {
      final userIds = emojiReactions.map((id) => id.toString()).toList();
      final userNames = <String>[];

      // Try to find usernames from recent messages in the same chat
      final messagesSnapshot = await _textRef(chatType, groupId, topicId)
          .where('userId', whereIn: userIds)
          .limit(userIds.length)
          .get();

      final foundUserNames = <String, String>{};
      for (var doc in messagesSnapshot.docs) {
        final msgData = doc.data() as Map<String, dynamic>;
        final userId = msgData['userId'];
        final userName = msgData['userName'];
        if (userId != null && userName != null) {
          foundUserNames[userId] = userName;
        }
      }

      for (var userId in userIds) {
        userNames.add(foundUserNames[userId] ?? 'Unknown User');
      }

      return userNames;
    }

    return [];
  }
}
