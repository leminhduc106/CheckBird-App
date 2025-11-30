import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:check_bird/services/planning_service.dart';
import 'package:check_bird/screens/planning/evening_review_screen.dart';
import 'package:check_bird/screens/planning/planning_dashboard_screen.dart';

/// A smart insights widget that shows personalized data from evening reviews
/// Shows mood trends, gratitude items, and encourages consistent reflection
/// Falls back to inspiring quotes when no gratitude data is available
class InsightsWidget extends StatefulWidget {
  const InsightsWidget({super.key});

  @override
  State<InsightsWidget> createState() => _InsightsWidgetState();
}

class _InsightsWidgetState extends State<InsightsWidget>
    with SingleTickerProviderStateMixin {
  final PlanningService _planningService = PlanningService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Quote data for fallback
  String? _quote;
  String? _quoteAuthor;
  bool _showingQuote = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _planningService.addListener(_onUpdate);
    _initService();
  }

  Future<void> _initService() async {
    await _planningService.initialize();

    final hasReviewData =
        _planningService.recentPlans.any((p) => p.hasEveningReview) ||
            (_planningService.todaysPlan?.hasEveningReview ?? false);

    if (hasReviewData) {
      // Decide whether to show quote or gratitude for existing users
      _decideContent();
    } else {
      // New user - fetch quote
      await _fetchQuote();
    }

    if (mounted) {
      setState(() {});
      _animationController.forward();
    }
  }

  void _decideContent() {
    final gratitude = _planningService.getRandomGratitudeItem();
    // Show quote 30% of the time OR when no gratitude available
    _showingQuote = gratitude == null || Random().nextDouble() < 0.3;
    if (_showingQuote && _quote == null) {
      _fetchQuote();
    }
  }

  Future<void> _fetchQuote() async {
    try {
      final response =
          await http.get(Uri.parse('https://api.quotable.io/random'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _quote = data['content'];
            _quoteAuthor = data['author'];
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch quote: $e');
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _planningService.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasReviewData =
        _planningService.recentPlans.any((p) => p.hasEveningReview) ||
            (_planningService.todaysPlan?.hasEveningReview ?? false);

    if (!hasReviewData) {
      // No evening review data yet - show encouragement
      return _buildEncouragementCard(context);
    }

    // Has data - show insights
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildInsightsCard(context),
    );
  }

  Widget _buildEncouragementCard(BuildContext context) {
    final theme = Theme.of(context);
    final isEvening = DateTime.now().hour >= 18;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isEvening
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EveningReviewScreen(),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Quote icon
                Icon(
                  Icons.format_quote,
                  size: 28,
                  color: theme.colorScheme.onPrimary.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                // Quote or loading
                Text(
                  _quote ?? 'Start your journey with intention...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: theme.colorScheme.onPrimary,
                    height: 1.4,
                  ),
                ),
                if (_quoteAuthor != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '— $_quoteAuthor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                // Evening review prompt
                if (isEvening) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start Evening Review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    final theme = Theme.of(context);
    final streak = _planningService.eveningReviewStreak;
    final moodTrend = _planningService.getMoodTrend(days: 7);
    final gratitude = _planningService.getRandomGratitudeItem();
    final avgMood = _planningService.getAverageMood(days: 7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlanningDashboardScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with streak
                Row(
                  children: [
                    Text(
                      '🌟 Your Week',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '$streak day${streak > 1 ? 's' : ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Mood trend visualization
                _buildMoodTrendChart(context, moodTrend),

                const SizedBox(height: 12),

                // Average mood summary
                Row(
                  children: [
                    Text(
                      _getMoodEmoji(avgMood),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMoodSummary(avgMood),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.colorScheme.primary,
                      size: 14,
                    ),
                  ],
                ),

                // Gratitude item OR Quote (alternating for variety)
                if (_showingQuote && _quote != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💭',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"$_quote"',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onPrimaryContainer
                                    .withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_quoteAuthor != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '— $_quoteAuthor',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (gratitude != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💝',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '"$gratitude"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTrendChart(
      BuildContext context, List<Map<String, dynamic>> trend) {
    final theme = Theme.of(context);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Get day abbreviations for the trend
    final trendDays = trend.map((t) {
      final date = t['date'] as DateTime;
      return days[date.weekday - 1];
    }).toList();

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(trend.length.clamp(0, 7), (index) {
          final data = trend[index];
          final rating = data['rating'] as int;
          final hasReview = data['hasReview'] as bool;
          final isToday = index == trend.length - 1;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mood bar
                AnimatedContainer(
                  duration: Duration(milliseconds: 300 + index * 50),
                  height: hasReview ? (rating * 5.0 + 8) : 8,
                  width: 20,
                  decoration: BoxDecoration(
                    color: hasReview
                        ? _getMoodColor(rating).withOpacity(isToday ? 1 : 0.7)
                        : theme.colorScheme.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Day label
                Text(
                  index < trendDays.length ? trendDays[index] : '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Color _getMoodColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.amber.shade400;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getMoodEmoji(double avgMood) {
    if (avgMood == 0) return '📊';
    if (avgMood <= 1.5) return '😔';
    if (avgMood <= 2.5) return '😐';
    if (avgMood <= 3.5) return '🙂';
    if (avgMood <= 4.5) return '😊';
    return '🤩';
  }

  String _getMoodSummary(double avgMood) {
    if (avgMood == 0) return 'Complete more reviews to see your trend';
    if (avgMood <= 1.5) return 'Tough week. Take care of yourself.';
    if (avgMood <= 2.5) return 'Room for improvement. Small wins help!';
    if (avgMood <= 3.5) return 'Steady week. Keep building momentum!';
    if (avgMood <= 4.5) return 'Great week! You\'re doing well.';
    return 'Amazing week! Keep up the energy!';
  }
}
