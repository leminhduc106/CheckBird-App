import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/widgets/image_crop_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('userProfiles').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('userProfiles')
          .doc(profile.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<String?> uploadAvatar(String uid, File imageFile) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }

  Future<void> updateAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    }
  }

  Future<File?> pickAndCropImage(BuildContext context,
      [ImageSource source = ImageSource.gallery]) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        debugPrint('No image selected');
        return null;
      }

      final imageFile = File(pickedFile.path);

      // Show our custom crop dialog
      final croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => ImageCropDialog(imageFile: imageFile),
          fullscreenDialog: true,
        ),
      );

      return croppedFile;
    } catch (e) {
      debugPrint('Error picking/cropping image: $e');
      // Don't rethrow for user cancellations or common plugin errors
      // Return null to indicate failure without crashing the app
      if (e.toString().contains('Reply already submitted') ||
          e.toString().contains('User cancelled') ||
          e.toString().contains('ActivityNotFoundException')) {
        debugPrint('Image picker/cropper operation cancelled or failed');
        return null;
      }
      // Only rethrow for unexpected errors
      rethrow;
    }
  }

  Future<void> initializeProfile(
      String uid, String email, String username) async {
    try {
      final profile = UserProfile(
        uid: uid,
        username: username,
        email: email,
        ownedFrames: [], // Start with no items
        ownedBackgrounds: [],
        ownedTitles: ['default'], // Everyone gets default title
      );
      await updateUserProfile(profile);
    } catch (e) {
      debugPrint('Error initializing profile: $e');
    }
  }

  Future<void> selectFrame(String uid, String? frameId) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'selectedFrameId': frameId,
      });
    } catch (e) {
      debugPrint('Error selecting frame: $e');
    }
  }

  Future<void> selectBackground(String uid, String? backgroundId) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'selectedBackgroundId': backgroundId,
      });
    } catch (e) {
      debugPrint('Error selecting background: $e');
    }
  }

  Future<void> selectTitle(String uid, String? titleId) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'selectedTitleId': titleId,
      });
    } catch (e) {
      debugPrint('Error selecting title: $e');
    }
  }

  Future<void> purchaseItem(String uid, String itemId, String itemType) async {
    try {
      final field = itemType == 'frame'
          ? 'ownedFrames'
          : itemType == 'background'
              ? 'ownedBackgrounds'
              : 'ownedTitles';

      await _firestore.collection('userProfiles').doc(uid).update({
        field: FieldValue.arrayUnion([itemId]),
      });
    } catch (e) {
      debugPrint('Error purchasing item: $e');
      rethrow;
    }
  }

  Future<void> updateAchievementProgress(
      String uid, String achievementId, int progress) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'achievementProgress.$achievementId': progress,
      });
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }

  Future<void> unlockAchievement(String uid, String achievementId) async {
    try {
      await _firestore.collection('userProfiles').doc(uid).update({
        'achievements': FieldValue.arrayUnion([achievementId]),
      });
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  List<ProfileFrame> getAvailableFrames() {
    return [
      ProfileFrame(
        id: 'challenger',
        name: 'Challenger',
        price: 10,
        currencyType: 'coins',
      ),
      ProfileFrame(
        id: 'purple',
        name: 'Purple',
        price: 5,
        currencyType: 'coins',
      ),
      ProfileFrame(
        id: 'hanghieu',
        name: 'HangHieu',
        price: 12,
        currencyType: 'coins',
      ),
    ];
  }

  List<ProfileBackground> getAvailableBackgrounds() {
    return [
      ProfileBackground(
        id: 'space',
        name: 'Space',
        price: 5,
        currencyType: 'coins',
      ),
      ProfileBackground(
        id: 'wjbu1',
        name: 'Wjbu1',
        price: 7,
        currencyType: 'coins',
      ),
      ProfileBackground(
        id: 'wjbu2',
        name: 'Wjbu2',
        price: 7,
        currencyType: 'coins',
      ),
    ];
  }

  List<ProfileTitle> getAvailableTitles() {
    return [
      ProfileTitle(
        id: 'default',
        name: 'Hard-Working',
        colorValue: 0xFF2196F3, // Colors.blue
      ),
      ProfileTitle(
        id: 'newbie',
        name: 'Newbie',
        colorValue: 0xFF9E9E9E, // Colors.grey
      ),
      ProfileTitle(
        id: 'hardworking2',
        name: 'Hard-Working2',
        colorValue: 0xFF4CAF50, // Colors.green
      ),
      ProfileTitle(
        id: 'hardworking3',
        name: 'Hard-Working3',
        colorValue: 0xFF4CAF50, // Colors.green
      ),
    ];
  }

  List<Achievement> getAchievements(Map<String, int> progress) {
    return [
      Achievement(
        id: 'achievement1',
        name: 'Achievement 1',
        description: 'Description',
        progress: progress['achievement1'] ?? 0,
        maxProgress: 100,
      ),
      Achievement(
        id: 'achievement2',
        name: 'Achievement 2',
        description: 'Description',
        progress: progress['achievement2'] ?? 0,
        maxProgress: 100,
      ),
      Achievement(
        id: 'achievement3',
        name: 'Achievement 3',
        description: 'Description',
        progress: progress['achievement3'] ?? 0,
        maxProgress: 100,
      ),
      Achievement(
        id: 'achievement4',
        name: 'Achievement 4',
        description: 'Description',
        progress: progress['achievement4'] ?? 0,
        maxProgress: 100,
      ),
      Achievement(
        id: 'achievement5',
        name: 'Achievement 5',
        description: 'Description',
        progress: progress['achievement5'] ?? 0,
        maxProgress: 100,
      ),
    ];
  }
}
