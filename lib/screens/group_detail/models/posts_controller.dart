import 'dart:io';

import 'package:check_bird/screens/group_detail/models/post.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ntp/ntp.dart';
import 'package:uuid/uuid.dart';

class PostsController {
  Stream<List<Post>> postsStream(String groupId) {
    var ref = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .orderBy('createdAt', descending: true);
    return ref.snapshots().map((element) {
      return element.docs.map((post) {
        final data = post.data();
        return Post(
          chatCount: data['chatCount'],
          likeCount: data['likeCount'],
          posterAvatarUrl: (data['posterAvatarUrl'] ?? '').toString(),
          posterName: data['posterName'],
          id: post.id,
          posterEmail: data['posterEmail'],
          posterId: data['posterId'],
          createdAt: data['createdAt'],
          posterImageUrl: data['posterImageUrl'],
          postText: data['postText'],
          type: (data['type'] ?? 'manual') as String,
          todoTitle: data['todoTitle'],
        );
      }).toList();
    });
  }

  Future<List<Post>> postsFuture(String groupId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .orderBy('createdAt', descending: true)
        .get();

    List<Post> results = [];
    for (var element in querySnapshot.docs) {
      final data = element.data()! as Map<String, dynamic>;
      results.add(Post(
        chatCount: data['chatCount'],
        likeCount: data['likeCount'],
        posterAvatarUrl: (data['posterAvatarUrl'] ?? '').toString(),
        posterName: data['posterName'],
        id: element.id,
        posterEmail: data['posterEmail'],
        posterId: data['posterId'],
        createdAt: data['createdAt'],
        posterImageUrl: data['posterImageUrl'],
        postText: data['postText'],
        type: (data['type'] ?? 'manual') as String,
        todoTitle: data['todoTitle'],
      ));
    }
    return results;
  }

  Future<String> _sendImg(
      {required File image, required String groupId}) async {
    var ref = FirebaseStorage.instance
        .ref()
        .child('img')
        .child(groupId)
        .child('post');
    var imgName = const Uuid().v4();
    ref = ref.child('$imgName.jpg');
    TaskSnapshot storageTaskSnapshot = await ref.putFile(image);
    var dowUrl = await storageTaskSnapshot.ref.getDownloadURL();
    return dowUrl;
  }

  Future<bool> isLiked(
      {required String groupId, required String postId}) async {
    var ref = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId)
        .collection('liker')
        .doc(Authentication.user!.uid);
    bool isLiked = false;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        isLiked = true;
      }
    });
    return isLiked;
  }

  Future<void> likePost(
      {required String groupId, required String postId}) async {
    var ref = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId);
    var likerRef = ref.collection('liker').doc(Authentication.user!.uid);
    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        DocumentSnapshot likerSnapshot = await transaction.get(likerRef);
        DocumentSnapshot postSnapshot = await transaction.get(ref);
        final data = postSnapshot.data()! as Map<String, dynamic>;
        if (likerSnapshot.exists) {
          transaction.delete(likerRef);
          transaction.update(ref, {
            "likeCount": data['likeCount'] - 1,
          });
        } else {
          transaction.set(likerRef, {
            'createdAt': Timestamp.now(),
          });
          transaction.update(ref, {
            "likeCount": data['likeCount'] + 1,
          });
        }
      },
    );
  }

  Future<void> createPostInDB(
      {required String groupId, String? text, File? img}) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('groups').doc(groupId).collection('post');
    String? imgUrl;
    if (img != null) {
      imgUrl = await _sendImg(image: img, groupId: groupId);
    }
    ref.add({
      'createdAt': await NTP.now(),
      'chatCount': 0,
      'likeCount': 0,
      'posterAvatarUrl': Authentication.user!.photoURL,
      'posterName': Authentication.user!.displayName,
      'postText': text,
      'posterImageUrl': imgUrl,
      'posterId': Authentication.user!.uid,
      'posterEmail': Authentication.user!.email,
      'type': 'manual',
    });
  }

  Future<void> createCompletionPost({
    required String groupId,
    required String todoName,
  }) async {
    final db = FirebaseFirestore.instance;
    final ref = db.collection('groups').doc(groupId).collection('post');

    await ref.add({
      'createdAt': await NTP.now(),
      'chatCount': 0,
      'likeCount': 0,
      'posterAvatarUrl': Authentication.user!.photoURL,
      'posterName': Authentication.user!.displayName,
      'postText': 'Completed: $todoName',
      'todoTitle': todoName,
      'posterImageUrl': null,
      'posterId': Authentication.user!.uid,
      'posterEmail': Authentication.user!.email,
      'type': 'completion',
    });
  }

  Future<void> deletePost({
    required String groupId,
    required String postId,
  }) async {
    final db = FirebaseFirestore.instance;

    // Delete the post document
    await db
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId)
        .delete();

    // Also delete the likers subcollection if it exists
    final likersRef = db
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId)
        .collection('liker');

    final likersSnapshot = await likersRef.get();
    for (final doc in likersSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<Post> postStream({required String groupId, required String postId}) {
    final ref = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('post')
        .doc(postId);
    return ref.snapshots().map((snapshot) {
      var data = snapshot.data()!;
      return Post(
        chatCount: data['chatCount'],
        likeCount: data['likeCount'],
        posterAvatarUrl: (data['posterAvatarUrl'] ?? '').toString(),
        posterName: data['posterName'],
        id: snapshot.id,
        posterEmail: data['posterEmail'],
        posterId: data['posterId'],
        createdAt: data['createdAt'],
        posterImageUrl: data['posterImageUrl'],
        postText: data['postText'],
        type: (data['type'] ?? 'manual') as String,
        todoTitle: data['todoTitle'],
      );
    });
  }
}
