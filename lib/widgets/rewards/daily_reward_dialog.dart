import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/rewards_service.dart';
import 'package:flutter/material.dart';

/// Dialog shown on daily login with streak info and rewards
class DailyRewardDialog extends StatelessWidget {
  final int streak;
  final int bonusCoins;
  final int bonusXp;
  final bool isNewStreak;

  const DailyRewardDialog({
    super.key,
    required this.streak,
    required this.bonusCoins,
    required this.bonusXp,
    required this.isNewStreak,
  });

  /// Check and show daily reward dialog if user hasn't logged in today
  static Future<void> checkAndShow(BuildContext context) async {
    if (Authentication.user == null) return;

    try {
      final result =
          await RewardsService().checkDailyLogin(Authentication.user!.uid);

      if (result != null && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DailyRewardDialog(
            streak: result['streak'],
            bonusCoins: result['bonusCoins'],
            bonusXp: result['bonusXp'],
            isNewStreak: result['isNewStreak'],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking daily login: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon or animation
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              isNewStreak ? 'Welcome Back!' : 'Daily Streak!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),

            // Streak info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '$streak Day${streak > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (isNewStreak && streak == 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Starting fresh! Keep it up!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Current streak',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rewards earned
            const Text(
              'Daily Rewards Earned:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardBadge(
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  value: '+$bonusCoins',
                  label: 'Coins',
                ),
                const SizedBox(width: 16),
                _buildRewardBadge(
                  icon: Icons.stars,
                  color: Colors.purple,
                  value: '+$bonusXp',
                  label: 'XP',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Motivational message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                streak >= 7
                    ? '🎉 Amazing! Keep the momentum going!'
                    : 'Keep logging in daily to increase your rewards!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Let\'s Go!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardBadge({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
