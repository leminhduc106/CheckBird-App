import 'package:check_bird/screens/about/about_screen.dart';
import 'package:check_bird/screens/setting/setting_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        backgroundImage: Authentication.user?.photoURL != null
                            ? NetworkImage(Authentication.user!.photoURL!)
                            : null,
                        child: Authentication.user?.photoURL == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User name
                    Text(
                      Authentication.user?.displayName ??
                          (l10n?.guestUser ?? 'Guest User'),
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
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
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
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: l10n?.logout ?? 'Logout',
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Authentication.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
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
