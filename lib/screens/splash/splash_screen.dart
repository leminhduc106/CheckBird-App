import 'package:flutter/material.dart';
import 'package:check_bird/screens/welcome/beautiful_welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash-screen';
  final VoidCallback? onAnimationComplete;

  const SplashScreen({super.key, this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late AnimationController _textController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _startAnimations();
  }

  void _startAnimations() async {
    // Start background animation immediately
    _backgroundController.forward();

    // Wait a bit, then start logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();

    // Wait a bit more, then start text animation
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Wait for all animations to complete, then navigate or callback
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      if (widget.onAnimationComplete != null) {
        widget.onAnimationComplete!();
      } else {
        Navigator.of(context)
            .pushReplacementNamed(BeautifulWelcomeScreen.routeName);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _backgroundController,
          _fadeController,
          _scaleController,
          _textController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    Colors.white,
                    theme.colorScheme.primary.withOpacity(0.1),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    Colors.white,
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    Colors.white,
                    Colors.white,
                    _backgroundAnimation.value,
                  )!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.primaryContainer
                                  .withOpacity(0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/checkbird-logo.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Animated app name
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _textAnimation,
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'CheckBird',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Animated tagline
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _textAnimation,
                      child: Text(
                        'Organize • Collaborate • Achieve',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Animated loading indicator
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
