import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/pet/virtual_pet.dart';
import 'package:check_bird/services/pet_service.dart';

class VirtualPetScreen extends StatefulWidget {
  const VirtualPetScreen({super.key});

  @override
  State<VirtualPetScreen> createState() => _VirtualPetScreenState();
}

class _VirtualPetScreenState extends State<VirtualPetScreen>
    with TickerProviderStateMixin {
  final PetService _petService = PetService();

  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  DateTime? _lastTapTime; // Cooldown for pet tapping

  @override
  void initState() {
    super.initState();
    _petService.initialize();
    _petService.addListener(_onUpdate);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _petService.removeListener(_onUpdate);
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = _petService.pet;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet?.name ?? 'My Pet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: pet == null ? _buildNoPetView() : _buildPetView(pet),
    );
  }

  Widget _buildNoPetView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🥚',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Adopt a Companion!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your productivity buddy will grow with you as you complete tasks and build habits!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showAdoptionDialog,
              icon: const Icon(Icons.pets),
              label: const Text('Adopt Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetView(VirtualPet pet) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Pet display area
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  pet.moodColor.withOpacity(0.2),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mood glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 150 + (20 * _pulseController.value),
                      height: 150 + (20 * _pulseController.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: pet.moodColor.withOpacity(0.3),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Pet emoji
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_bounceAnimation.value),
                      child: GestureDetector(
                        onTap: () => _petTapped(),
                        child: Text(
                          pet.emoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                      ),
                    );
                  },
                ),

                // Level badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${pet.level}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                // Evolution stage badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEvolutionStageName(pet.stage),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status message
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(pet.stats.mood),
                  color: pet.moodColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _petService.getStatusMessage(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Stats bars
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatBar('Hunger', pet.stats.hunger, Colors.orange,
                    Icons.restaurant),
                const SizedBox(height: 12),
                _buildStatBar('Happiness', pet.stats.happiness, Colors.pink,
                    Icons.favorite),
                const SizedBox(height: 12),
                _buildStatBar(
                    'Energy', pet.stats.energy, Colors.blue, Icons.bolt),
                const SizedBox(height: 12),
                _buildStatBar(
                    'Health', pet.stats.health, Colors.green, Icons.healing),
              ],
            ),
          ),

          // XP Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${pet.xp} / ${pet.xpForNextLevel} XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pet.levelProgress,
                    minHeight: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ),
              ],
            ),
          ),

          // Evolution progress
          if (pet.canEvolve)
            Container(
              margin: const EdgeInsets.all(16),
              child: FilledButton.tonalIcon(
                onPressed: _evolvePet,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Evolve Now!'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _petService.getEvolutionRequirements(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const Divider(height: 32),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.restaurant,
                  label: 'Feed',
                  color: Colors.orange,
                  onTap: _showFeedDialog,
                  enabled: pet.stage != EvolutionStage.egg,
                ),
                _buildActionButton(
                  icon: Icons.sports_esports,
                  label: 'Play',
                  color: Colors.pink,
                  onTap: _showPlayDialog,
                  enabled: pet.stage != EvolutionStage.egg,
                ),
                _buildActionButton(
                  icon: Icons.bed,
                  label: 'Sleep',
                  color: Colors.blue,
                  onTap: _putToSleep,
                  enabled: pet.stage != EvolutionStage.egg,
                ),
                _buildActionButton(
                  icon: Icons.checkroom,
                  label: 'Dress Up',
                  color: Colors.purple,
                  onTap: _showAccessoriesDialog,
                  enabled: pet.stage != EvolutionStage.egg,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats summary
          _buildStatsSummary(pet),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$value%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 8,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final effectiveColor = enabled ? color : Colors.grey;
    final effectiveOpacity = enabled ? 0.1 : 0.05;

    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(effectiveOpacity),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(VirtualPet pet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('Tasks', '${pet.tasksCompleted}', Icons.check_circle),
          _buildMiniStat('Focus', '${pet.focusMinutes}m', Icons.timer),
          _buildMiniStat(
              'Streak', '${pet.streakDays}d', Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(PetMood mood) {
    switch (mood) {
      case PetMood.ecstatic:
        return Icons.sentiment_very_satisfied;
      case PetMood.happy:
        return Icons.sentiment_satisfied;
      case PetMood.content:
        return Icons.sentiment_satisfied_alt;
      case PetMood.neutral:
        return Icons.sentiment_neutral;
      case PetMood.sad:
        return Icons.sentiment_dissatisfied;
      case PetMood.sick:
        return Icons.sick;
    }
  }

  String _getEvolutionStageName(EvolutionStage stage) {
    switch (stage) {
      case EvolutionStage.egg:
        return '🥚 Egg';
      case EvolutionStage.baby:
        return '🐣 Baby';
      case EvolutionStage.child:
        return '🌟 Child';
      case EvolutionStage.teen:
        return '💫 Teen';
      case EvolutionStage.adult:
        return '⭐ Adult';
      case EvolutionStage.legendary:
        return '👑 Legendary';
    }
  }

  void _petTapped() {
    final pet = _petService.pet;
    if (pet == null) return;

    // Check if pet is still an egg - can't interact much with eggs
    if (pet.stage == EvolutionStage.egg) {
      HapticFeedback.lightImpact();
      final tasksNeeded = 5 - pet.tasksCompleted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tasksNeeded > 0
                ? 'Complete $tasksNeeded more task${tasksNeeded > 1 ? 's' : ''} to hatch your egg! 🥚'
                : 'Your egg is ready to hatch! Tap the evolve button! ✨',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Cooldown check - 3 seconds between taps
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 3) {
      return; // Too soon, ignore tap
    }
    _lastTapTime = now;

    HapticFeedback.lightImpact();

    // Just give a tiny happiness boost (no XP!) - purely cosmetic interaction
    _petService.petPet(); // New method that only gives happiness, no XP

    // Show cute reaction message
    final reactions = [
      '${pet.name} loved that! 💕',
      '${pet.name} is happy! 😊',
      '${pet.name} purrs happily! 💖',
      '${pet.name} wags excitedly! 🎉',
      '${pet.name} feels loved! ❤️',
    ];
    final reaction = reactions[now.millisecond % reactions.length];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reaction),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAdoptionDialog() {
    String petName = '';
    PetSpecies selectedSpecies = PetSpecies.bird;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🐣 Adopt a Companion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Pet Name',
                      hintText: 'Give your companion a name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => petName = value,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  // Species selection
                  const Text(
                    'Choose a species:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: PetSpecies.values.map((species) {
                      final isSelected = selectedSpecies == species;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => selectedSpecies = species);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _getSpeciesEmoji(species),
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                species.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Adopt button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: petName.isNotEmpty
                          ? () async {
                              await _petService.createPet(
                                name: petName,
                                species: selectedSpecies,
                              );
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Adopt!'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getSpeciesEmoji(PetSpecies species) {
    switch (species) {
      case PetSpecies.bird:
        return '🐦';
      case PetSpecies.cat:
        return '🐱';
      case PetSpecies.dog:
        return '🐶';
      case PetSpecies.dragon:
        return '🐲';
      case PetSpecies.fox:
        return '🦊';
      case PetSpecies.bunny:
        return '🐰';
    }
  }

  void _showFeedDialog() {
    final pet = _petService.pet;

    // Can't feed eggs
    if (pet?.stage == EvolutionStage.egg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Eggs don\'t need food! Complete tasks to hatch it. 🥚'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🍽️ Feed Your Pet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: PetFood.allFoods.length,
                  itemBuilder: (context, index) {
                    final food = PetFood.allFoods[index];
                    return ListTile(
                      leading: Text(food.emoji,
                          style: const TextStyle(fontSize: 32)),
                      title: Text(food.name),
                      subtitle: Text(
                        '+${food.hungerRestore} Hunger${food.happinessBoost > 0 ? ', +${food.happinessBoost} Happiness' : ''}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${food.coinCost}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      onTap: () async {
                        // TODO: Check user coins
                        final success =
                            await _petService.feedPet(food, userCoins: 1000);
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '${_petService.pet?.name} enjoyed the ${food.name}! 😋'
                                    : 'Not enough coins!',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _showPlayDialog() {
    final pet = _petService.pet;

    // Can't play with eggs
    if (pet?.stage == EvolutionStage.egg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You can\'t play with an egg! Complete tasks to hatch it first. 🥚'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎮 Play With Your Pet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: PetActivity.allActivities.length,
                  itemBuilder: (context, index) {
                    final activity = PetActivity.allActivities[index];
                    final currentPet = _petService.pet;
                    final hasEnergy = currentPet != null &&
                        currentPet.stats.energy >= activity.energyCost;

                    return ListTile(
                      leading: Text(activity.emoji,
                          style: const TextStyle(fontSize: 32)),
                      title: Text(activity.name),
                      subtitle: Text(
                        '+${activity.happinessGain} Happiness, +${activity.xpGain} XP\nCosts ${activity.energyCost} Energy',
                      ),
                      trailing: Icon(
                        hasEnergy ? Icons.play_circle : Icons.lock,
                        color: hasEnergy
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      enabled: hasEnergy,
                      onTap: hasEnergy
                          ? () async {
                              final xpGained =
                                  await _petService.playWithPet(activity);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${_petService.pet?.name} had fun! +$xpGained XP 🎉',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _putToSleep() async {
    final pet = _petService.pet;

    // Can't put eggs to sleep
    if (pet?.stage == EvolutionStage.egg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Eggs don\'t need sleep! Complete tasks to hatch it. 🥚'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await _petService.putPetToSleep();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_petService.pet?.name} is well rested! 😴💤'),
        ),
      );
    }
  }

  void _showAccessoriesDialog() {
    // TODO: Implement accessories shop
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accessories shop coming soon! 🛍️'),
      ),
    );
  }

  void _evolvePet() async {
    await _petService.evolvePet();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✨ EVOLUTION ✨',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _petService.pet?.emoji ?? '🐣',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                '${_petService.pet?.name} evolved to ${_petService.pet?.stage.name}!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Amazing!'),
            ),
          ],
        ),
      );
    }
  }

  void _showSettings() {
    // TODO: Pet settings
  }
}
