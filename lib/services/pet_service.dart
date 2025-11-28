import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:check_bird/models/pet/virtual_pet.dart';

/// Service to manage virtual pet
class PetService extends ChangeNotifier {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  VirtualPet? _pet;
  Timer? _decayTimer;

  VirtualPet? get pet => _pet;
  bool get hasPet => _pet != null;

  /// Initialize service
  Future<void> initialize() async {
    await _loadPet();
    _startDecayTimer();
  }

  /// Load pet from storage
  Future<void> _loadPet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('virtual_pet');

      if (jsonString != null) {
        _pet = VirtualPet.fromJson(json.decode(jsonString));
        await _applyTimedDecay();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading pet: $e');
    }
  }

  /// Save pet to storage
  Future<void> _savePet() async {
    if (_pet == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('virtual_pet', json.encode(_pet!.toJson()));

      // Sync to Firestore
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('pet')
            .doc('current')
            .set(_pet!.toJson());
      }
    } catch (e) {
      debugPrint('Error saving pet: $e');
    }
  }

  /// Create a new pet
  Future<VirtualPet> createPet({
    required String name,
    required PetSpecies species,
  }) async {
    _pet = VirtualPet.create(name: name, species: species);
    await _savePet();
    notifyListeners();
    return _pet!;
  }

  /// Start decay timer (stats decrease over time)
  void _startDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _applyHourlyDecay();
    });
  }

  /// Apply time-based stat decay
  Future<void> _applyTimedDecay() async {
    if (_pet == null) return;

    final now = DateTime.now();

    // Calculate hours since last interactions
    final hoursSinceLastFed = now.difference(_pet!.lastFed).inHours;
    final hoursSinceLastPlayed = now.difference(_pet!.lastPlayed).inHours;
    final hoursSinceLastSlept = now.difference(_pet!.lastSlept).inHours;

    // Apply decay
    var newStats = _pet!.stats;

    // Hunger decreases over time
    if (hoursSinceLastFed > 0) {
      newStats = newStats.copyWith(
        hunger: newStats.hunger - (hoursSinceLastFed * 3),
      );
    }

    // Happiness decreases over time
    if (hoursSinceLastPlayed > 0) {
      newStats = newStats.copyWith(
        happiness: newStats.happiness - (hoursSinceLastPlayed * 2),
      );
    }

    // Energy recovers during sleep, decreases when awake
    if (hoursSinceLastSlept > 8) {
      newStats = newStats.copyWith(
        energy: newStats.energy - ((hoursSinceLastSlept - 8) * 2),
      );
    }

    // Health affected by other stats
    if (newStats.hunger < 20 || newStats.happiness < 20) {
      newStats = newStats.copyWith(
        health: newStats.health - 5,
      );
    }

    _pet = _pet!.copyWith(stats: newStats);
    await _savePet();
    notifyListeners();
  }

  /// Apply hourly decay
  void _applyHourlyDecay() {
    if (_pet == null) return;

    var newStats = _pet!.stats.copyWith(
      hunger: _pet!.stats.hunger - 2,
      happiness: _pet!.stats.happiness - 1,
    );

    // Health regenerates if other stats are good
    if (newStats.hunger > 50 &&
        newStats.happiness > 50 &&
        newStats.energy > 30) {
      newStats = newStats.copyWith(
        health: (newStats.health + 2).clamp(0, 100),
      );
    }

    _pet = _pet!.copyWith(stats: newStats);
    _savePet();
    notifyListeners();
  }

  /// Feed the pet
  Future<bool> feedPet(PetFood food, {required int userCoins}) async {
    if (_pet == null) return false;
    if (_pet!.stage == EvolutionStage.egg) return false; // Can't feed eggs!
    if (userCoins < food.coinCost) return false;

    final newStats = _pet!.stats.copyWith(
      hunger: _pet!.stats.hunger + food.hungerRestore,
      happiness: _pet!.stats.happiness + food.happinessBoost,
    );

    _pet = _pet!.copyWith(
      stats: newStats,
      lastFed: DateTime.now(),
    );

    await _savePet();
    notifyListeners();
    return true;
  }

  /// Play with pet
  Future<int> playWithPet(PetActivity activity) async {
    if (_pet == null) return 0;
    if (_pet!.stage == EvolutionStage.egg) return 0; // Can't play with eggs!
    if (_pet!.stats.energy < activity.energyCost) return 0;

    final newStats = _pet!.stats.copyWith(
      happiness: _pet!.stats.happiness + activity.happinessGain,
      energy: _pet!.stats.energy - activity.energyCost,
    );

    int newXp = _pet!.xp + activity.xpGain;
    int newLevel = _pet!.level;

    // Check for level up
    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
    }

    _pet = _pet!.copyWith(
      stats: newStats,
      xp: newXp,
      level: newLevel,
      lastPlayed: DateTime.now(),
    );

    await _savePet();
    notifyListeners();
    return activity.xpGain;
  }

  /// Pet the pet (no XP gain, just happiness - for tap interactions)
  void petPet() {
    if (_pet == null) return;
    if (_pet!.stage == EvolutionStage.egg) return; // Can't pet eggs!

    // Small happiness boost only - no XP!
    final newStats = _pet!.stats.copyWith(
      happiness: _pet!.stats.happiness + 2, // Tiny boost
    );

    _pet = _pet!.copyWith(stats: newStats);
    _savePet();
    notifyListeners();
  }

  /// Put pet to sleep
  Future<void> putPetToSleep() async {
    if (_pet == null) return;

    final newStats = _pet!.stats.copyWith(
      energy: 100,
    );

    _pet = _pet!.copyWith(
      stats: newStats,
      lastSlept: DateTime.now(),
    );

    await _savePet();
    notifyListeners();
  }

  /// Record task completion (rewards pet)
  Future<void> onTaskCompleted() async {
    if (_pet == null) return;

    final newStats = _pet!.stats.copyWith(
      happiness: _pet!.stats.happiness + 5,
    );

    int newXp = _pet!.xp + 10;
    int newLevel = _pet!.level;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
    }

    _pet = _pet!.copyWith(
      stats: newStats,
      xp: newXp,
      level: newLevel,
      tasksCompleted: _pet!.tasksCompleted + 1,
    );

    await _savePet();
    notifyListeners();
  }

  /// Record focus session (rewards pet)
  Future<void> onFocusSessionCompleted(int minutes) async {
    if (_pet == null) return;

    final happinessGain = (minutes / 5).round();
    final xpGain = (minutes * 2).round();

    final newStats = _pet!.stats.copyWith(
      happiness: _pet!.stats.happiness + happinessGain,
    );

    int newXp = _pet!.xp + xpGain;
    int newLevel = _pet!.level;

    while (newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
    }

    _pet = _pet!.copyWith(
      stats: newStats,
      xp: newXp,
      level: newLevel,
      focusMinutes: _pet!.focusMinutes + minutes,
    );

    await _savePet();
    notifyListeners();
  }

  /// Update daily streak
  Future<void> updateStreak(int streakDays) async {
    if (_pet == null) return;

    _pet = _pet!.copyWith(streakDays: streakDays);
    await _savePet();
    notifyListeners();
  }

  /// Evolve pet to next stage
  Future<bool> evolvePet() async {
    if (_pet == null || !_pet!.canEvolve) return false;

    EvolutionStage nextStage;
    switch (_pet!.stage) {
      case EvolutionStage.egg:
        nextStage = EvolutionStage.baby;
        break;
      case EvolutionStage.baby:
        nextStage = EvolutionStage.child;
        break;
      case EvolutionStage.child:
        nextStage = EvolutionStage.teen;
        break;
      case EvolutionStage.teen:
        nextStage = EvolutionStage.adult;
        break;
      case EvolutionStage.adult:
        nextStage = EvolutionStage.legendary;
        break;
      case EvolutionStage.legendary:
        return false;
    }

    // Restore stats on evolution
    _pet = _pet!.copyWith(
      stage: nextStage,
      stats: const PetStats(), // Full stats
    );

    await _savePet();
    notifyListeners();
    return true;
  }

  /// Get pet status message
  String getStatusMessage() {
    if (_pet == null) return '';

    final stats = _pet!.stats;

    if (stats.health < 20) {
      return '${_pet!.name} is not feeling well... 😷';
    }
    if (stats.hunger < 20) {
      return '${_pet!.name} is very hungry! 🍽️';
    }
    if (stats.happiness < 20) {
      return '${_pet!.name} is feeling lonely... 😢';
    }
    if (stats.energy < 20) {
      return '${_pet!.name} is exhausted and needs rest! 😴';
    }

    if (stats.overall >= 90) {
      return '${_pet!.name} is absolutely thriving! ✨';
    }
    if (stats.overall >= 70) {
      return '${_pet!.name} is happy and healthy! 😊';
    }
    if (stats.overall >= 50) {
      return '${_pet!.name} is doing okay. 🙂';
    }

    return '${_pet!.name} could use some attention. 😐';
  }

  /// Get evolution requirements description
  String getEvolutionRequirements() {
    if (_pet == null) return '';

    switch (_pet!.stage) {
      case EvolutionStage.egg:
        return 'Complete 5 tasks to hatch! (${_pet!.tasksCompleted}/5)';
      case EvolutionStage.baby:
        return 'Reach level 5 & complete 25 tasks (Lv${_pet!.level}/5, ${_pet!.tasksCompleted}/25)';
      case EvolutionStage.child:
        return 'Reach level 15 & focus 300 minutes (Lv${_pet!.level}/15, ${_pet!.focusMinutes}/300)';
      case EvolutionStage.teen:
        return 'Reach level 30 & 7-day streak (Lv${_pet!.level}/30, ${_pet!.streakDays}/7 days)';
      case EvolutionStage.adult:
        return 'Reach level 50, 30-day streak & 90% happiness';
      case EvolutionStage.legendary:
        return 'Maximum evolution reached! ⭐';
    }
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    super.dispose();
  }
}
