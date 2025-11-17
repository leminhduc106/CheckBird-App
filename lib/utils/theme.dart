import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AppThemeKeys { light, dark }

class AppTheme extends ChangeNotifier {
  static AppTheme of(BuildContext context, {bool listen = false}) =>
      Provider.of<AppTheme>(context, listen: listen);

  AppTheme() {
    _init();
  }

  _init() async {
    prefs = await SharedPreferences.getInstance();
    bool? boolValue = prefs?.getBool('isDarkMode');
    if (boolValue == null) {
      _themeKeys = AppThemeKeys.light;
    } else if (boolValue) {
      _themeKeys = AppThemeKeys.dark;
    } else {
      _themeKeys = AppThemeKeys.light;
    }
    notifyListeners();
  }

  AppThemeKeys? _themeKeys;
  SharedPreferences? prefs;

  ThemeData? getCurrentTheme() => _themes[_themeKeys];

  AppThemeKeys? getCurrentThemeKey() => _themeKeys;

  void setTheme(AppThemeKeys themeKey) {
    _themeKeys = themeKey;
    prefs?.setBool('isDarkMode', _themeKeys == AppThemeKeys.dark);
    notifyListeners();
  }

  final Map<AppThemeKeys, ThemeData> _themes = {
    AppThemeKeys.light: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      ).copyWith(
        primary: const Color(0xFF2196F3),
        primaryContainer: const Color(0xFFE3F2FD),
        secondary: const Color(0xFF1976D2),
        secondaryContainer: const Color(0xFFBBDEFB),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 3,
        shape: CircleBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    ),
    AppThemeKeys.dark: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.expressive,
      ).copyWith(
        primary: const Color(0xFF42A5F5),
        primaryContainer: const Color(0xFF1565C0),
        secondary: const Color(0xFF64B5F6),
        secondaryContainer: const Color(0xFF0D47A1),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleSmall: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        bodyLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 3,
        shape: CircleBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    ),
  };
}
