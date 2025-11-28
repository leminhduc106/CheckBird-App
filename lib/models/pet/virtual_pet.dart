import 'package:flutter/material.dart';

/// Pet species available
enum PetSpecies {
  bird,
  cat,
  dog,
  dragon,
  fox,
  bunny,
}

/// Pet mood states
enum PetMood {
  ecstatic,
  happy,
  content,
  neutral,
  sad,
  sick,
}

/// Evolution stages
enum EvolutionStage {
  egg,
  baby,
  child,
  teen,
  adult,
  legendary,
}

/// Pet statistics
class PetStats {
  final int hunger; // 0-100
  final int happiness; // 0-100
  final int energy; // 0-100
  final int health; // 0-100

  const PetStats({
    this.hunger = 100,
    this.happiness = 100,
    this.energy = 100,
    this.health = 100,
  });

  double get overall => (hunger + happiness + energy + health) / 4;

  PetMood get mood {
    final avg = overall;
    if (avg >= 90) return PetMood.ecstatic;
    if (avg >= 70) return PetMood.happy;
    if (avg >= 50) return PetMood.content;
    if (avg >= 30) return PetMood.neutral;
    if (avg >= 10) return PetMood.sad;
    return PetMood.sick;
  }

  PetStats copyWith({
    int? hunger,
    int? happiness,
    int? energy,
    int? health,
  }) {
    return PetStats(
      hunger: (hunger ?? this.hunger).clamp(0, 100),
      happiness: (happiness ?? this.happiness).clamp(0, 100),
      energy: (energy ?? this.energy).clamp(0, 100),
      health: (health ?? this.health).clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'hunger': hunger,
        'happiness': happiness,
        'energy': energy,
        'health': health,
      };

  factory PetStats.fromJson(Map<String, dynamic> json) {
    return PetStats(
      hunger: json['hunger'] ?? 100,
      happiness: json['happiness'] ?? 100,
      energy: json['energy'] ?? 100,
      health: json['health'] ?? 100,
    );
  }
}

/// Pet accessory
class PetAccessory {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AccessoryType type;
  final int coinCost;
  final int gemCost;
  final Map<String, int> statBoosts;

  const PetAccessory({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    this.coinCost = 0,
    this.gemCost = 0,
    this.statBoosts = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'type': type.name,
        'coinCost': coinCost,
        'gemCost': gemCost,
        'statBoosts': statBoosts,
      };

  factory PetAccessory.fromJson(Map<String, dynamic> json) {
    return PetAccessory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      emoji: json['emoji'],
      type: AccessoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccessoryType.hat,
      ),
      coinCost: json['coinCost'] ?? 0,
      gemCost: json['gemCost'] ?? 0,
      statBoosts: Map<String, int>.from(json['statBoosts'] ?? {}),
    );
  }
}

enum AccessoryType {
  hat,
  glasses,
  collar,
  wings,
  background,
}

/// Virtual pet model
class VirtualPet {
  final String id;
  final String name;
  final PetSpecies species;
  final EvolutionStage stage;
  final PetStats stats;
  final int xp;
  final int level;
  final DateTime birthDate;
  final DateTime lastFed;
  final DateTime lastPlayed;
  final DateTime lastSlept;
  final List<String> ownedAccessories;
  final Map<AccessoryType, String?> equippedAccessories;
  final int tasksCompleted;
  final int focusMinutes;
  final int streakDays;
  final List<String> unlockedAchievements;

  const VirtualPet({
    required this.id,
    required this.name,
    required this.species,
    this.stage = EvolutionStage.egg,
    this.stats = const PetStats(),
    this.xp = 0,
    this.level = 1,
    required this.birthDate,
    required this.lastFed,
    required this.lastPlayed,
    required this.lastSlept,
    this.ownedAccessories = const [],
    this.equippedAccessories = const {},
    this.tasksCompleted = 0,
    this.focusMinutes = 0,
    this.streakDays = 0,
    this.unlockedAchievements = const [],
  });

  /// XP needed for next level
  int get xpForNextLevel => level * 100;

  /// Current progress to next level (0.0-1.0)
  double get levelProgress => xp / xpForNextLevel;

  /// Evolution requirements met
  bool get canEvolve {
    switch (stage) {
      case EvolutionStage.egg:
        return tasksCompleted >= 5;
      case EvolutionStage.baby:
        return level >= 5 && tasksCompleted >= 25;
      case EvolutionStage.child:
        return level >= 15 && focusMinutes >= 300;
      case EvolutionStage.teen:
        return level >= 30 && streakDays >= 7;
      case EvolutionStage.adult:
        return level >= 50 && streakDays >= 30 && stats.overall >= 90;
      case EvolutionStage.legendary:
        return false; // Max evolution
    }
  }

  /// Get pet emoji based on species and stage
  String get emoji {
    switch (species) {
      case PetSpecies.bird:
        return _getBirdEmoji();
      case PetSpecies.cat:
        return _getCatEmoji();
      case PetSpecies.dog:
        return _getDogEmoji();
      case PetSpecies.dragon:
        return _getDragonEmoji();
      case PetSpecies.fox:
        return _getFoxEmoji();
      case PetSpecies.bunny:
        return _getBunnyEmoji();
    }
  }

  String _getBirdEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🐣';
      case EvolutionStage.child:
        return '🐤';
      case EvolutionStage.teen:
        return '🐥';
      case EvolutionStage.adult:
        return '🐦';
      case EvolutionStage.legendary:
        return '🦅';
    }
  }

  String _getCatEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🐱';
      case EvolutionStage.child:
        return '😺';
      case EvolutionStage.teen:
        return '😸';
      case EvolutionStage.adult:
        return '🐈';
      case EvolutionStage.legendary:
        return '🦁';
    }
  }

  String _getDogEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🐶';
      case EvolutionStage.child:
        return '🐕';
      case EvolutionStage.teen:
        return '🦮';
      case EvolutionStage.adult:
        return '🐕‍🦺';
      case EvolutionStage.legendary:
        return '🐺';
    }
  }

  String _getDragonEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🦎';
      case EvolutionStage.child:
        return '🐉';
      case EvolutionStage.teen:
        return '🐲';
      case EvolutionStage.adult:
        return '🔥';
      case EvolutionStage.legendary:
        return '⭐🐲';
    }
  }

  String _getFoxEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🦊';
      case EvolutionStage.child:
        return '🦊';
      case EvolutionStage.teen:
        return '🦊';
      case EvolutionStage.adult:
        return '🦊';
      case EvolutionStage.legendary:
        return '🌟🦊';
    }
  }

  String _getBunnyEmoji() {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚';
      case EvolutionStage.baby:
        return '🐰';
      case EvolutionStage.child:
        return '🐇';
      case EvolutionStage.teen:
        return '🐇';
      case EvolutionStage.adult:
        return '🐇';
      case EvolutionStage.legendary:
        return '✨🐰';
    }
  }

  /// Get pet color based on mood
  Color get moodColor {
    switch (stats.mood) {
      case PetMood.ecstatic:
        return Colors.amber;
      case PetMood.happy:
        return Colors.green;
      case PetMood.content:
        return Colors.lightGreen;
      case PetMood.neutral:
        return Colors.grey;
      case PetMood.sad:
        return Colors.blue;
      case PetMood.sick:
        return Colors.red;
    }
  }

  VirtualPet copyWith({
    String? id,
    String? name,
    PetSpecies? species,
    EvolutionStage? stage,
    PetStats? stats,
    int? xp,
    int? level,
    DateTime? birthDate,
    DateTime? lastFed,
    DateTime? lastPlayed,
    DateTime? lastSlept,
    List<String>? ownedAccessories,
    Map<AccessoryType, String?>? equippedAccessories,
    int? tasksCompleted,
    int? focusMinutes,
    int? streakDays,
    List<String>? unlockedAchievements,
  }) {
    return VirtualPet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      stage: stage ?? this.stage,
      stats: stats ?? this.stats,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      birthDate: birthDate ?? this.birthDate,
      lastFed: lastFed ?? this.lastFed,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      lastSlept: lastSlept ?? this.lastSlept,
      ownedAccessories: ownedAccessories ?? this.ownedAccessories,
      equippedAccessories: equippedAccessories ?? this.equippedAccessories,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      streakDays: streakDays ?? this.streakDays,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species.name,
        'stage': stage.name,
        'stats': stats.toJson(),
        'xp': xp,
        'level': level,
        'birthDate': birthDate.toIso8601String(),
        'lastFed': lastFed.toIso8601String(),
        'lastPlayed': lastPlayed.toIso8601String(),
        'lastSlept': lastSlept.toIso8601String(),
        'ownedAccessories': ownedAccessories,
        'equippedAccessories': equippedAccessories.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'tasksCompleted': tasksCompleted,
        'focusMinutes': focusMinutes,
        'streakDays': streakDays,
        'unlockedAchievements': unlockedAchievements,
      };

  factory VirtualPet.fromJson(Map<String, dynamic> json) {
    return VirtualPet(
      id: json['id'],
      name: json['name'],
      species: PetSpecies.values.firstWhere(
        (e) => e.name == json['species'],
        orElse: () => PetSpecies.bird,
      ),
      stage: EvolutionStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => EvolutionStage.egg,
      ),
      stats: PetStats.fromJson(json['stats'] ?? {}),
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      birthDate: DateTime.parse(json['birthDate']),
      lastFed: DateTime.parse(json['lastFed']),
      lastPlayed: DateTime.parse(json['lastPlayed']),
      lastSlept: DateTime.parse(json['lastSlept']),
      ownedAccessories: List<String>.from(json['ownedAccessories'] ?? []),
      equippedAccessories:
          (json['equippedAccessories'] as Map<String, dynamic>? ?? {})
              .map((key, value) => MapEntry(
                    AccessoryType.values.firstWhere((e) => e.name == key),
                    value as String?,
                  )),
      tasksCompleted: json['tasksCompleted'] ?? 0,
      focusMinutes: json['focusMinutes'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      unlockedAchievements:
          List<String>.from(json['unlockedAchievements'] ?? []),
    );
  }

  /// Create a new pet
  factory VirtualPet.create({
    required String name,
    required PetSpecies species,
  }) {
    final now = DateTime.now();
    return VirtualPet(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      species: species,
      stage: EvolutionStage.egg,
      stats: const PetStats(),
      birthDate: now,
      lastFed: now,
      lastPlayed: now,
      lastSlept: now,
    );
  }
}

/// Pet food items
class PetFood {
  final String id;
  final String name;
  final String emoji;
  final int hungerRestore;
  final int happinessBoost;
  final int coinCost;

  const PetFood({
    required this.id,
    required this.name,
    required this.emoji,
    required this.hungerRestore,
    this.happinessBoost = 0,
    required this.coinCost,
  });

  static const List<PetFood> allFoods = [
    PetFood(
      id: 'basic_food',
      name: 'Basic Food',
      emoji: '🍖',
      hungerRestore: 20,
      coinCost: 10,
    ),
    PetFood(
      id: 'tasty_treat',
      name: 'Tasty Treat',
      emoji: '🍗',
      hungerRestore: 35,
      happinessBoost: 10,
      coinCost: 25,
    ),
    PetFood(
      id: 'premium_meal',
      name: 'Premium Meal',
      emoji: '🥩',
      hungerRestore: 50,
      happinessBoost: 20,
      coinCost: 50,
    ),
    PetFood(
      id: 'gourmet_feast',
      name: 'Gourmet Feast',
      emoji: '🍱',
      hungerRestore: 75,
      happinessBoost: 30,
      coinCost: 100,
    ),
    PetFood(
      id: 'legendary_dish',
      name: 'Legendary Dish',
      emoji: '✨🍽️',
      hungerRestore: 100,
      happinessBoost: 50,
      coinCost: 200,
    ),
  ];
}

/// Pet game/activity
class PetActivity {
  final String id;
  final String name;
  final String emoji;
  final int happinessGain;
  final int energyCost;
  final int xpGain;
  final Duration cooldown;

  const PetActivity({
    required this.id,
    required this.name,
    required this.emoji,
    required this.happinessGain,
    required this.energyCost,
    required this.xpGain,
    this.cooldown = const Duration(minutes: 30),
  });

  static const List<PetActivity> allActivities = [
    PetActivity(
      id: 'pet',
      name: 'Pet',
      emoji: '🤚',
      happinessGain: 10,
      energyCost: 0,
      xpGain: 5,
      cooldown: Duration(minutes: 5),
    ),
    PetActivity(
      id: 'play_ball',
      name: 'Play Ball',
      emoji: '⚽',
      happinessGain: 25,
      energyCost: 15,
      xpGain: 15,
      cooldown: Duration(minutes: 30),
    ),
    PetActivity(
      id: 'go_walk',
      name: 'Go for Walk',
      emoji: '🚶',
      happinessGain: 30,
      energyCost: 20,
      xpGain: 20,
      cooldown: Duration(hours: 1),
    ),
    PetActivity(
      id: 'adventure',
      name: 'Adventure',
      emoji: '🗺️',
      happinessGain: 50,
      energyCost: 40,
      xpGain: 50,
      cooldown: Duration(hours: 4),
    ),
  ];
}
