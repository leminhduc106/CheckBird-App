import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:flutter/material.dart';

class AchievementTab extends StatelessWidget {
  final UserProfile? userProfile;

  const AchievementTab({
    super.key,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final profileController = ProfileController();
    final achievements = profileController.getAchievements(
      userProfile?.achievementProgress ?? {},
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final completedCount =
        achievements.where((a) => a.progressPercentage >= 100).length;

    return Column(
      children: [
        // Statistics header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.tertiaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Trophy icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 36,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatItem(
                          context: context,
                          label: 'Completed',
                          value: '$completedCount',
                          icon: Icons.check_circle_rounded,
                        ),
                        const SizedBox(width: 20),
                        _buildStatItem(
                          context: context,
                          label: 'Total',
                          value: '${achievements.length}',
                          icon: Icons.emoji_events_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Achievements list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            physics: const BouncingScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final isCompleted = achievement.progressPercentage >= 100;

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isCompleted
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber.shade50,
                              Colors.amber.shade100,
                            ],
                          )
                        : null,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.amber.shade300
                          : colorScheme.outlineVariant,
                      width: isCompleted ? 2 : 1,
                    ),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Achievement Icon
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: isCompleted
                                  ? LinearGradient(
                                      colors: [
                                        Colors.amber.shade400,
                                        Colors.amber.shade600,
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        colorScheme.surfaceContainerHigh,
                                        colorScheme.surfaceContainer,
                                      ],
                                    ),
                              shape: BoxShape.circle,
                              boxShadow: isCompleted
                                  ? [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.emoji_events_rounded
                                  : Icons.emoji_events_outlined,
                              size: 32,
                              color: isCompleted
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Achievement Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.amber.shade900
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isCompleted
                                        ? Colors.amber.shade800
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progress',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${achievement.progressPercentage}%',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: isCompleted
                                                ? Colors.amber.shade900
                                                : colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: achievement.progressPercentage /
                                            100,
                                        minHeight: 8,
                                        backgroundColor: isCompleted
                                            ? Colors.amber.shade200
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          isCompleted
                                              ? Colors.amber.shade600
                                              : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Completion badge
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onPrimaryContainer.withOpacity(0.8),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
