import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/utils/theme.dart';
import 'package:check_bird/utils/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingScreen extends StatefulWidget {
  static const keyLanguage = 'key-language';
  static const keyDarkMode = 'key-darkmode';
  static const routeName = '/setting-screen';
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Future<void> _showLanguagePicker(LocaleController controller) async {
    final l10n = AppLocalizations.of(context)!;
    final current = controller.locale.languageCode;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text(l10n.english),
              trailing: current == 'en'
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                controller.setLocale(const Locale('en'));
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
              title: Text(l10n.vietnamese),
              trailing: current == 'vi'
                  ? Icon(Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                controller.setLocale(const Locale('vi'));
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 48),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.settingsTitle),
            automaticallyImplyLeading: true),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              SettingsGroup(
                title: AppLocalizations.of(context)!.generalSection,
                children: <Widget>[
                  buildLanguages(),
                  buildDarkMode(),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.feedbackSection,
                children: <Widget>[
                  buildFeedBack(),
                  buildReportBug(),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                title: AppLocalizations.of(context)!.accountSection,
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
            AppLocalizations.of(context)!.sendFeedback,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.helpImprove,
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
            AppLocalizations.of(context)!.reportBug,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.reportIssues,
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
            AppLocalizations.of(context)!.deleteAccount,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          subtitle: Text(
            AppLocalizations.of(context)!.deleteAccountDesc,
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
                  title: Text(AppLocalizations.of(context)!.deleteAccount),
                  content:
                      Text(AppLocalizations.of(context)!.deleteAccountDesc),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(contextDialog).pop();
                      },
                      child: Text(AppLocalizations.of(context)!.cancel),
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
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget buildLanguages() {
    final controller = Provider.of<LocaleController>(context, listen: true);
    final l10n = AppLocalizations.of(context)!;
    final isVi = controller.locale.languageCode == 'vi';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        title: Text(
          l10n.languages,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          isVi ? l10n.vietnamese : l10n.english,
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
            Icons.language_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showLanguagePicker(controller),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget buildDarkMode() => SwitchSettingsTile(
        title: AppLocalizations.of(context)!.darkMode,
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
