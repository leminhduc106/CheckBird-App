import 'package:flutter/material.dart';
import 'package:check_bird/services/planning_service.dart';
import 'package:check_bird/screens/planning/daily_planning_screen.dart';
import 'package:check_bird/screens/planning/evening_review_screen.dart';

class PlanningDashboardScreen extends StatefulWidget {
  const PlanningDashboardScreen({super.key});

  @override
  State<PlanningDashboardScreen> createState() =>
      _PlanningDashboardScreenState();
}

class _PlanningDashboardScreenState extends State<PlanningDashboardScreen> {
  final PlanningService _planningService = PlanningService();
  Map<String, dynamic> _weeklyStats = {};
  List<String> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _planningService.initialize().timeout(
            const Duration(seconds: 5),
            onTimeout: () {},
          );
      _weeklyStats = await _planningService.getWeeklyStats();
      _insights = _planningService.getProductivityInsights();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Dashboard'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(context),

                    const SizedBox(height: 24),

                    // Today's Plan Summary
                    _buildTodaysSummary(context),

                    const SizedBox(height: 24),

                    // Weekly Stats
                    Text(
                      '📊 This Week',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWeeklyStats(context),

                    const SizedBox(height: 24),

                    // Insights
                    Text(
                      '💡 Insights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInsights(context),

                    const SizedBox(height: 24),

                    // Recent Plans
                    Text(
                      '📅 Recent Days',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentPlans(context),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final plan = _planningService.todaysPlan;
    final hasPlan = plan?.hasMorningPlan ?? false;
    final hasReview = plan?.hasEveningReview ?? false;
    final isEvening = DateTime.now().hour >= 18;

    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.wb_sunny_rounded,
            title: hasPlan ? 'Edit Plan' : 'Morning Plan',
            subtitle: hasPlan ? 'Update today\'s plan' : 'Start your day right',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyPlanningScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            icon: Icons.nightlight_round,
            title: hasReview ? 'Review Done' : 'Evening Review',
            subtitle: hasReview
                ? 'Already completed'
                : isEvening
                    ? 'Reflect on today'
                    : 'Available after 6 PM',
            color: Colors.indigo,
            enabled: !hasReview && isEvening,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EveningReviewScreen(),
                ),
              ).then((_) => _loadData());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: enabled
          ? color.withOpacity(0.1)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: enabled ? color : theme.colorScheme.outline,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? null : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSummary(BuildContext context) {
    final theme = Theme.of(context);
    final plan = _planningService.todaysPlan;

    if (plan == null || !plan.hasMorningPlan) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.wb_sunny_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No plan for today yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyPlanningScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getEnergyEmoji(plan.energyLevel),
                style: const TextStyle(fontSize: 32),
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
                      ),
                    ),
                    Text(
                      plan.morningIntention ?? 'Have a great day!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.topPriorities.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              '🎯 Priorities',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...plan.topPriorities.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p)),
                    ],
                  ),
                )),
          ],
          if (plan.timeBlocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${plan.timeBlocks.where((b) => b.completed).length}/${plan.timeBlocks.length} time blocks completed',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.wb_sunny,
                  label: 'Days Planned',
                  value: '${_weeklyStats['planningDays'] ?? 0}/7',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.nightlight,
                  label: 'Days Reviewed',
                  value: '${_weeklyStats['reviewDays'] ?? 0}/7',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.star,
                  label: 'Avg Rating',
                  value: (_weeklyStats['avgRating'] ?? 0.0).toStringAsFixed(1),
                  color: Colors.amber,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.check_circle,
                  label: 'Blocks Done',
                  value: '${_weeklyStats['completionRate'] ?? 0}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: _insights.map((insight) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            insight,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentPlans(BuildContext context) {
    final theme = Theme.of(context);
    final recentPlans = _planningService.recentPlans;

    if (recentPlans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No recent plans yet. Start planning your days!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: recentPlans.take(5).map((plan) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: plan.dayRating > 0
                      ? _getRatingColor(plan.dayRating).withOpacity(0.2)
                      : theme.colorScheme.outline.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    plan.dayRating > 0 ? '${plan.dayRating}' : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: plan.dayRating > 0
                          ? _getRatingColor(plan.dayRating)
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(plan.date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      plan.morningIntention ?? 'No intention set',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (plan.hasMorningPlan)
                Icon(
                  Icons.wb_sunny,
                  size: 16,
                  color: Colors.orange.shade400,
                ),
              if (plan.hasEveningReview) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.nightlight,
                  size: 16,
                  color: Colors.indigo.shade400,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
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

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.grey;
      case 4:
        return Colors.green;
      case 5:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
