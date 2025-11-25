import 'package:flutter/material.dart';
import 'package:check_bird/screens/authentication/authenticate_screen.dart';

class BeautifulWelcomeScreen extends StatefulWidget {
  static const routeName = '/beautiful-welcome-screen';

  const BeautifulWelcomeScreen({super.key});

  @override
  State<BeautifulWelcomeScreen> createState() => _BeautifulWelcomeScreenState();
}

class _BeautifulWelcomeScreenState extends State<BeautifulWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<Offset> _slide1Animation;
  late Animation<Offset> _slide2Animation;
  late Animation<Offset> _slide3Animation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slide1Animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slide2Animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _slide3Animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.primaryContainer.withOpacity(0.1),
              Colors.white,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48, // Account for padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated logo
                            AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_fadeController, _scaleController]),
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Hero(
                                      tag: 'app-logo',
                                      child: Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              theme.colorScheme.primary
                                                  .withOpacity(0.1),
                                              theme.colorScheme.primaryContainer
                                                  .withOpacity(0.05),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.1),
                                              blurRadius: 30,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/images/checkbird-logo.png',
                                          width: 140,
                                          height: 140,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // App name with gradient
                            SlideTransition(
                              position: _slide1Animation,
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
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Tagline
                            SlideTransition(
                              position: _slide2Animation,
                              child: Text(
                                'Organize your tasks, collaborate with your team,\\nand achieve your goals together.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Features section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            SlideTransition(
                              position: _slide3Animation,
                              child: _buildFeatureCard(
                                icon: Icons.group_work_rounded,
                                title: 'Team Collaboration',
                                subtitle:
                                    'Work together seamlessly with real-time updates',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SlideTransition(
                              position: _slide3Animation,
                              child: _buildFeatureCard(
                                icon: Icons.task_alt_rounded,
                                title: 'Task Management',
                                subtitle:
                                    'Organize and track your progress efficiently',
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SlideTransition(
                              position: _slide3Animation,
                              child: _buildFeatureCard(
                                icon: Icons.insights_rounded,
                                title: 'Progress Insights',
                                subtitle:
                                    'Analyze your productivity with detailed reports',
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Get Started button
                      SlideTransition(
                        position: _slide3Animation,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                AuthenticateScreen.routeName,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
