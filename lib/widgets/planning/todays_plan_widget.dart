import 'package:flutter/material.dart';
import 'package:check_bird/models/planning/daily_plan.dart';
import 'package:check_bird/services/planning_service.dart';
import 'package:check_bird/screens/planning/daily_planning_screen.dart';
import 'package:check_bird/screens/planning/evening_review_screen.dart';

/// Widget to show today's plan summary on the home screen
class TodaysPlanWidget extends StatefulWidget {
  const TodaysPlanWidget({super.key});

  @override
  State<TodaysPlanWidget> createState() => _TodaysPlanWidgetState();
}

class _TodaysPlanWidgetState extends State<TodaysPlanWidget> {
  final PlanningService _planningService = PlanningService();

  @override
  void initState() {
    super.initState();
    _planningService.addListener(_onUpdate);
    _initService();
  }

  Future<void> _initService() async {
    await _planningService.initialize();
    if (mounted) setState(() {});
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _planningService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _planningService.todaysPlan;
    final hasPlan = plan != null && plan.hasMorningPlan;
    final isEvening = DateTime.now().hour >= 18;
    final hasEveningReview = plan?.hasEveningReview ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPlan
              ? [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.primaryContainer.withOpacity(0.7),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!hasPlan) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DailyPlanningScreen(),
                ),
              );
            } else if (isEvening && !hasEveningReview) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EveningReviewScreen(),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: hasPlan
                ? _buildPlanContent(context, plan)
                : _buildEmptyState(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.wb_sunny_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting! 👋',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start your day with intention. Tap to plan!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildPlanContent(BuildContext context, DailyPlan plan) {
    final theme = Theme.of(context);
    final isEvening = DateTime.now().hour >= 18;
    final hasEveningReview = plan.hasEveningReview;
    final currentBlock = _getCurrentTimeBlock(plan);
    final energySuggestion = _planningService.getEnergySuggestion();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with intention
        Row(
          children: [
            Text(
              _getEnergyEmoji(plan.energyLevel),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Intention',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    plan.morningIntention ?? 'Have a productive day!',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isEvening && !hasEveningReview)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      color: theme.colorScheme.onTertiary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Review',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Energy suggestion based on mood trends
        if (energySuggestion != null && !isEvening) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    energySuggestion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (plan.topPriorities.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Top Priorities
          Text(
            '🎯 Top Priorities',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...plan.topPriorities.take(3).map((priority) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      priority,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Current Time Block
        if (currentBlock != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentBlock.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentBlock.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  currentBlock.icon,
                  color: currentBlock.color,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Focus',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: currentBlock.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currentBlock.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatTime(currentBlock.startTime)} - ${_formatTime(currentBlock.endTime)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Focus Area badge
        if (plan.focusArea != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFocusBadge(context, plan.focusArea!),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFocusBadge(BuildContext context, String focusAreaId) {
    final theme = Theme.of(context);
    final preset = FocusAreaPreset.presets.firstWhere(
      (p) => p.id == focusAreaId,
      orElse: () => FocusAreaPreset.presets.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(preset.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            preset.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  TimeBlock? _getCurrentTimeBlock(DailyPlan plan) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final block in plan.timeBlocks) {
      final startMinutes = block.startTime.hour * 60 + block.startTime.minute;
      final endMinutes = block.endTime.hour * 60 + block.endTime.minute;

      if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
        return block;
      }
    }
    return null;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _getEnergyEmoji(int level) {
    switch (level) {
      case 1:
        return '😴';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🔥';
      default:
        return '🙂';
    }
  }
}
