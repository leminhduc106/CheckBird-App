import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  static const keyLanguage = 'key-language';
  static const keyDarkMode = 'key-darkmode';
  static const routeName = '/setting-screen';
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text("Settings"), automaticallyImplyLeading: true),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              SettingsGroup(
                title: 'GENERAL',
                children: <Widget>[
                  buildDarkMode(),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: "FEEDBACK",
                children: <Widget>[
                  buildFeedBack(),
                  buildReportBug(),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: "ACCOUNT",
                children: <Widget>[
                  buildDeleteAccount(),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildFeedBack() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          title: Text(
            "Send Feedback",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            "Help us improve the app",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.thumb_up_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            // Add feedback functionality
          },
        ),
      );

  Widget buildReportBug() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          title: Text(
            "Report Bug",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            "Report issues you encounter",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bug_report_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            // Add bug report functionality
          },
        ),
      );

  Widget buildDeleteAccount() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListTile(
          title: Text(
            "Delete Account",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          subtitle: Text(
            "Permanently delete your account",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete_forever_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: 20,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (contextDialog) {
                return AlertDialog(
                  icon: Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                  title: const Text('Delete Account?'),
                  content: const Text(
                      '''This action cannot be undone. Your account and all associated data will be permanently deleted from our servers.'''),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(contextDialog).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        Navigator.of(contextDialog).pop();
                        await Authentication.deleteUserAccount();
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget buildLanguages() => DropDownSettingsTile(
        settingKey: SettingScreen.keyLanguage,
        title: "Languages",
        selected: 1,
        values: const <int, String>{
          1: "English",
          2: "Vietnamese",
        },
        onChange: (language) {/* */},
      );

  Widget buildDarkMode() => SwitchSettingsTile(
        title: "Dark mode",
        settingKey: SettingScreen.keyDarkMode,
        onChange: (value) async {
          debugPrint('key-check-box-dev-mode: $value');
          if (value) {
            AppTheme.of(context).setTheme(AppThemeKeys.dark);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isDarkMode', true);
          } else {
            AppTheme.of(context).setTheme(AppThemeKeys.light);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isDarkMode', false);
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurpleAccent,
          ),
          child: const Icon(
            Icons.dark_mode,
            color: Colors.white,
          ),
        ),
      );

  AppTheme? _theme;
  @override
  void didChangeDependencies() {
    _theme ??= AppTheme.of(context);
    super.didChangeDependencies();
  }
}
