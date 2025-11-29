import 'package:check_bird/screens/about/about_screen.dart';
import 'package:check_bird/screens/achievements/achievements_screen.dart';
import 'package:check_bird/screens/focus/enhanced_focus_screen.dart';
import 'package:check_bird/screens/habits/habit_stack_screen.dart';
import 'package:check_bird/screens/mood/mood_tracker_screen.dart';
import 'package:check_bird/screens/pet/virtual_pet_screen.dart';
import 'package:check_bird/screens/planning/daily_planning_screen.dart';
import 'package:check_bird/screens/planning/evening_review_screen.dart';
import 'package:check_bird/screens/planning/planning_dashboard_screen.dart';
import 'package:check_bird/screens/profile/profile_screen.dart';
import 'package:check_bird/screens/quests/weekly_quests_screen.dart';
import 'package:check_bird/screens/setting/setting_screen.dart';
import 'package:check_bird/screens/smart_filters/smart_filters_screen.dart';
import 'package:check_bird/screens/statistics/statistics_screen.dart';
import 'package:check_bird/screens/templates/templates_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (e) {
      l10n = null;
    }
    return Drawer(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(ProfileScreen.routeName);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          backgroundImage: Authentication.user?.photoURL != null
                              ? NetworkImage(Authentication.user!.photoURL!)
                              : null,
                          child: Authentication.user?.photoURL == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User name
                      Text(
                        Authentication.user?.displayName ??
                            (l10n?.profile ?? 'Profile'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // User email
                      Text(
                        Authentication.user?.email ??
                            (l10n?.notSignedIn ?? 'Not signed in'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Productivity & Insights Section
                _buildSectionHeader(context, 'Productivity'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.wb_sunny_rounded,
                  title: 'Daily Planning',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DailyPlanningScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.nightlight_round,
                  title: 'Evening Review',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EveningReviewScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: 'Planning Dashboard',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PlanningDashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.psychology_rounded,
                  title: 'Focus Timer',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EnhancedFocusScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.link_rounded,
                  title: 'Habit Stacks',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const HabitStackScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Statistics',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StatisticsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.filter_list_rounded,
                  title: 'Smart Views',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SmartFiltersScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.content_copy_rounded,
                  title: 'Templates',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TemplatesScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Wellness Section
                _buildSectionHeader(context, 'Wellness'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.mood_rounded,
                  title: 'Mood Tracker',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MoodTrackerScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Rewards & Progress Section
                _buildSectionHeader(context, 'Rewards'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.pets_rounded,
                  title: 'My Pet',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const VirtualPetScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.bolt_rounded,
                  title: 'Weekly Quests',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WeeklyQuestsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                const Divider(indent: 16, endIndent: 16, height: 1),
                const SizedBox(height: 8),

                // Account & Settings Section
                _buildDrawerItem(
                  context: context,
                  icon: Icons.person_rounded,
                  title: l10n?.profile ?? 'Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(ProfileScreen.routeName);
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: l10n?.settingsTitle ?? 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(SettingScreen.routeName);
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_rounded,
                  title: l10n?.aboutUs ?? 'About Us',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(AboutScreen.routeName);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                // Show "Sign In" for guest users or "Logout" for authenticated users
                Authentication.user == null
                    ? _buildDrawerItem(
                        context: context,
                        icon: Icons.login_rounded,
                        title: l10n?.signIn ?? 'Sign In',
                        textColor: Theme.of(context).colorScheme.primary,
                        onTap: () {
                          Navigator.of(context).pop();
                          // Navigate to login screen and clear the stack
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/welcome-screen',
                            (route) => false,
                          );
                        },
                      )
                    : _buildDrawerItem(
                        context: context,
                        icon: Icons.logout_rounded,
                        title: l10n?.logout ?? 'Logout',
                        textColor: Theme.of(context).colorScheme.error,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await Authentication.signOut();
                          // Navigate to WelcomeScreen and clear the entire navigation stack
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/welcome-screen',
                              (route) => false,
                            );
                          }
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
