import 'package:check_bird/models/achievement/achievement.dart';
import 'package:check_bird/services/achievement_service.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:flutter/material.dart';

class AchievementsScreen extends StatefulWidget {
  static const routeName = '/achievements-screen';

  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  late TabController _tabController;

  final List<AchievementCategory> _categories = [
    AchievementCategory.tasks,
    AchievementCategory.habits,
    AchievementCategory.streaks,
    AchievementCategory.social,
    AchievementCategory.shop,
    AchievementCategory.special,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.tasks:
        return 'Tasks';
      case AchievementCategory.habits:
        return 'Habits';
      case AchievementCategory.streaks:
        return 'Streaks';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.shop:
        return 'Shop';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.tasks:
        return Icons.check_circle_outline;
      case AchievementCategory.habits:
        return Icons.repeat;
      case AchievementCategory.streaks:
        return Icons.local_fire_department;
      case AchievementCategory.social:
        return Icons.groups;
      case AchievementCategory.shop:
        return Icons.shopping_bag;
      case AchievementCategory.special:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Authentication.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Achievements')),
        body: const Center(
          child: Text('Please sign in to view achievements'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _categories
              .map((category) => Tab(
                    icon: Icon(_getCategoryIcon(category)),
                    text: _getCategoryName(category),
                  ))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          // Progress header
          _buildProgressHeader(),
          // Achievement list
          Expanded(
            child: StreamBuilder<Map<String, UserAchievementProgress>>(
              stream: _achievementService
                  .getUserAchievementsStream(Authentication.user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final progressMap = snapshot.data ?? {};

                return TabBarView(
                  controller: _tabController,
                  children: _categories
                      .map((category) => _buildAchievementList(
                            Achievement.getByCategory(category),
                            progressMap,
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return FutureBuilder<int>(
      future: _achievementService.getUnlockedCount(Authentication.user!.uid),
      builder: (context, snapshot) {
        final unlockedCount = snapshot.data ?? 0;
        final totalCount = Achievement.allAchievements.length;
        final progress = unlockedCount / totalCount;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade300,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$unlockedCount / $totalCount',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% Complete',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementList(
    List<Achievement> achievements,
    Map<String, UserAchievementProgress> progressMap,
  ) {
    // Sort: unlocked first, then by progress
    achievements.sort((a, b) {
      final aProgress = progressMap[a.id];
      final bProgress = progressMap[b.id];
      final aUnlocked = aProgress?.isUnlocked ?? false;
      final bUnlocked = bProgress?.isUnlocked ?? false;

      if (aUnlocked != bUnlocked) {
        return aUnlocked ? -1 : 1;
      }

      final aPercentage = aProgress?.progressPercentage ?? 0;
      final bPercentage = bProgress?.progressPercentage ?? 0;
      return bPercentage.compareTo(aPercentage);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final progress = progressMap[achievement.id];
        return _buildAchievementCard(achievement, progress);
      },
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    UserAchievementProgress? progress,
  ) {
    final isUnlocked = progress?.isUnlocked ?? false;
    final isSecret = achievement.isSecret && !isUnlocked;
    final progressValue = progress?.currentProgress ?? 0;
    final progressPercentage = progress?.progressPercentage ?? 0;
    final canClaimRewards = isUnlocked && !(progress?.rewardsClaimed ?? true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(
                color: achievement.color.withOpacity(0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? achievement.color.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canClaimRewards ? () => _claimRewards(achievement) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? achievement.color.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSecret ? Icons.lock : achievement.icon,
                    color: isUnlocked ? achievement.color : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSecret ? '???' : achievement.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSecret
                            ? 'Complete special actions to unlock'
                            : achievement.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (!isUnlocked && !isSecret) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressPercentage,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    achievement.color.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$progressValue / ${achievement.targetValue}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (canClaimRewards) ...[
                        const SizedBox(height: 8),
                        _buildRewardsRow(achievement),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsRow(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          const Text(
            'Tap to claim: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          if (achievement.coinsReward > 0) ...[
            Icon(Icons.monetization_on, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 2),
            Text('${achievement.coinsReward}',
                style: const TextStyle(fontSize: 12)),
          ],
          if (achievement.gemsReward > 0) ...[
            const SizedBox(width: 6),
            const Icon(Icons.diamond, size: 14, color: Colors.pink),
            const SizedBox(width: 2),
            Text('${achievement.gemsReward}',
                style: const TextStyle(fontSize: 12)),
          ],
          if (achievement.xpReward > 0) ...[
            const SizedBox(width: 6),
            const Icon(Icons.star, size: 14, color: Colors.purple),
            const SizedBox(width: 2),
            Text('${achievement.xpReward} XP',
                style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Future<void> _claimRewards(Achievement achievement) async {
    final success = await _achievementService.claimRewards(
      userId: Authentication.user!.uid,
      achievementId: achievement.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 12),
              Text('Claimed rewards for "${achievement.name}"!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
