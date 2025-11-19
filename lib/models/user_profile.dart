import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final String? bio;

  // Inventory
  final String? selectedFrameId;
  final String? selectedBackgroundId;
  final String? selectedTitleId;
  final List<String> ownedFrames;
  final List<String> ownedBackgrounds;
  final List<String> ownedTitles;

  // Achievements
  final List<String> achievements;
  final Map<String, int> achievementProgress;

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.avatarUrl,
    this.bio,
    this.selectedFrameId,
    this.selectedBackgroundId,
    this.selectedTitleId,
    this.ownedFrames = const [],
    this.ownedBackgrounds = const [],
    this.ownedTitles = const [],
    this.achievements = const [],
    this.achievementProgress = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      gender: data['gender'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      selectedFrameId: data['selectedFrameId'],
      selectedBackgroundId: data['selectedBackgroundId'],
      selectedTitleId: data['selectedTitleId'],
      ownedFrames: List<String>.from(data['ownedFrames'] ?? []),
      ownedBackgrounds: List<String>.from(data['ownedBackgrounds'] ?? []),
      ownedTitles: List<String>.from(data['ownedTitles'] ?? []),
      achievements: List<String>.from(data['achievements'] ?? []),
      achievementProgress:
          Map<String, int>.from(data['achievementProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'selectedFrameId': selectedFrameId,
      'selectedBackgroundId': selectedBackgroundId,
      'selectedTitleId': selectedTitleId,
      'ownedFrames': ownedFrames,
      'ownedBackgrounds': ownedBackgrounds,
      'ownedTitles': ownedTitles,
      'achievements': achievements,
      'achievementProgress': achievementProgress,
    };
  }

  UserProfile copyWith({
    String? username,
    String? email,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    String? avatarUrl,
    String? bio,
    String? selectedFrameId,
    String? selectedBackgroundId,
    String? selectedTitleId,
    List<String>? ownedFrames,
    List<String>? ownedBackgrounds,
    List<String>? ownedTitles,
    List<String>? achievements,
    Map<String, int>? achievementProgress,
  }) {
    return UserProfile(
      uid: uid,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      selectedFrameId: selectedFrameId ?? this.selectedFrameId,
      selectedBackgroundId: selectedBackgroundId ?? this.selectedBackgroundId,
      selectedTitleId: selectedTitleId ?? this.selectedTitleId,
      ownedFrames: ownedFrames ?? this.ownedFrames,
      ownedBackgrounds: ownedBackgrounds ?? this.ownedBackgrounds,
      ownedTitles: ownedTitles ?? this.ownedTitles,
      achievements: achievements ?? this.achievements,
      achievementProgress: achievementProgress ?? this.achievementProgress,
    );
  }
}

class ProfileFrame {
  final String id;
  final String name;
  final String? imagePath;
  final int price;
  final String currencyType; // 'coins' or 'gems'

  ProfileFrame({
    required this.id,
    required this.name,
    this.imagePath,
    required this.price,
    this.currencyType = 'coins',
  });
}

class ProfileBackground {
  final String id;
  final String name;
  final String? imagePath;
  final int price;
  final String currencyType;

  ProfileBackground({
    required this.id,
    required this.name,
    this.imagePath,
    required this.price,
    this.currencyType = 'coins',
  });
}

class ProfileTitle {
  final String id;
  final String name;
  final int? colorValue; // Store color as int value

  ProfileTitle({
    required this.id,
    required this.name,
    this.colorValue,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final int progress;
  final int maxProgress;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.progress = 0,
    required this.maxProgress,
  });

  int get progressPercentage => ((progress / maxProgress) * 100).round();
}
