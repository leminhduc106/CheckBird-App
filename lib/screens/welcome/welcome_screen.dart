import 'package:animations/animations.dart';
import 'package:check_bird/screens/main_navigator/main_navigator_screen.dart';
import 'package:check_bird/screens/splash/splash_screen.dart';
import 'package:check_bird/screens/welcome/beautiful_welcome_screen.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  static const routeName = '/welcome-screen';

  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isFirstLaunch = true;
  bool _isCheckingFirstLaunch = true;

  // Use a stream that combines auth state changes
  late Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
    // Use idTokenChanges which fires on sign-in, sign-out, and token refresh
    // This is more reliable than authStateChanges on web
    _authStream = FirebaseAuth.instance.idTokenChanges();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;

    setState(() {
      _isFirstLaunch = !hasSeenSplash;
      _isCheckingFirstLaunch = false;
    });
  }

  Future<void> _markSplashAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_splash', true);
    setState(() {
      _isFirstLaunch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingFirstLaunch) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isFirstLaunch) {
      return SplashScreen(
        onAnimationComplete: _markSplashAsSeen,
      );
    }

    return StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, snapshot) {
          debugPrint(
              'WelcomeScreen: Auth state changed - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, user: ${snapshot.data?.email}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check if user exists AND either:
          // 1. Email is verified, OR
          // 2. User signed in with Google (Google emails are pre-verified)
          final user = snapshot.data;
          bool isAuthenticated = false;

          if (user != null) {
            // Check if user signed in with Google (no email verification needed)
            final isGoogleUser = user.providerData
                .any((provider) => provider.providerId == 'google.com');

            isAuthenticated = user.emailVerified || isGoogleUser;
            debugPrint(
                'WelcomeScreen: User found - isGoogleUser: $isGoogleUser, emailVerified: ${user.emailVerified}, isAuthenticated: $isAuthenticated');
          }

          if (isAuthenticated) {
            Authentication.user = user;
          } else {
            Authentication.user = null;
          }

          // Show beautiful welcome for unauthenticated users
          // Show main app for authenticated users
          Widget currentWidget = isAuthenticated
              ? const MainNavigatorScreen()
              : const BeautifulWelcomeScreen();

          return PageTransitionSwitcher(
            // Add key to force rebuild when auth state changes
            key: ValueKey(isAuthenticated),
            child: currentWidget,
            transitionBuilder: (Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation) {
              const begin = Offset(1.0, 0);
              const end = Offset.zero;
              const curve = Curves.ease;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: primaryAnimation.drive(tween),
                child: child,
              );
            },
          );
        });
  }
}
