import 'package:check_bird/models/quest/weekly_quest.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/quest_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class WeeklyQuestsScreen extends StatefulWidget {
  static const routeName = '/weekly-quests-screen';

  const WeeklyQuestsScreen({super.key});

  @override
  State<WeeklyQuestsScreen> createState() => _WeeklyQuestsScreenState();
}

class _WeeklyQuestsScreenState extends State<WeeklyQuestsScreen> {
  final QuestService _questService = QuestService();
  List<WeeklyQuest> _quests = [];
  Timer? _countdownTimer;
  Duration _timeUntilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadQuests();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    final quests = await _questService.getCurrentQuests();
    setState(() {
      _quests = quests;
    });
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeUntilReset = _questService.getTimeUntilReset();
    });
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Authentication.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Quests')),
        body: const Center(
          child: Text('Please sign in to view quests'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Quests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Timer header
          _buildTimerHeader(),
          // Quest list
          Expanded(
            child: StreamBuilder<Map<String, QuestProgress>>(
              stream: _questService
                  .getUserQuestProgressStream(Authentication.user!.uid),
              builder: (context, snapshot) {
                final progressMap = snapshot.data ?? {};

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quests.length,
                  itemBuilder: (context, index) {
                    final quest = _quests[index];
                    final progress = progressMap[quest.id];
                    return _buildQuestCard(quest, progress);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.deepPurple.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.timer,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quests Reset In',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_timeUntilReset),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Reward hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events,
                    color: Colors.amber.shade300, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_quests.length} Quests',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(WeeklyQuest quest, QuestProgress? progress) {
    final isCompleted = progress?.isCompleted ?? false;
    final canClaimRewards = isCompleted && !(progress?.rewardsClaimed ?? true);
    final currentProgress = progress?.currentProgress ?? 0;
    final progressPercentage =
        progress?.getProgressPercentage(quest.targetValue) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(
                color: Colors.green.withOpacity(0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.green.withOpacity(0.15)
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
          onTap: canClaimRewards ? () => _claimRewards(quest) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: quest.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        quest.icon,
                        color: quest.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and difficulty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quest.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      quest.difficultyColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quest.difficultyName,
                                  style: TextStyle(
                                    color: quest.difficultyColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quest.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressPercentage,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : quest.color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isCompleted
                                ? '✓ Completed!'
                                : '$currentProgress / ${quest.targetValue}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Rewards
                    _buildRewardsChip(quest, canClaimRewards),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsChip(WeeklyQuest quest, bool canClaim) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: canClaim
            ? Colors.amber.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: canClaim
            ? Border.all(color: Colors.amber.shade600, width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canClaim)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Tap to claim!',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quest.coinsReward > 0) ...[
                Icon(Icons.monetization_on,
                    size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 2),
                Text('${quest.coinsReward}',
                    style: const TextStyle(fontSize: 12)),
              ],
              if (quest.gemsReward > 0) ...[
                const SizedBox(width: 6),
                const Icon(Icons.diamond, size: 14, color: Colors.pink),
                const SizedBox(width: 2),
                Text('${quest.gemsReward}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.purple),
              const SizedBox(width: 2),
              Text('${quest.xpReward} XP',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _claimRewards(WeeklyQuest quest) async {
    final success = await _questService.claimQuestRewards(
      userId: Authentication.user!.uid,
      questId: quest.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 12),
              Text('Claimed rewards for "${quest.title}"!'),
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
