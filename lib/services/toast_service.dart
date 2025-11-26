import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Global toast service that works from anywhere in the app
class ToastService {
  static final ToastService _instance = ToastService._();
  factory ToastService() => _instance;
  ToastService._();

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _currentOverlay;

  /// Show a reward toast notification
  static void showRewardToast({
    required int coins,
    required int xp,
    bool isGroupTask = false,
  }) {
    debugPrint('🎉 ToastService: Showing reward toast +$coins coins, +$xp XP');

    // Use post-frame callback to ensure overlay is available
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _showToastOverlay(coins: coins, xp: xp, isGroupTask: isGroupTask);
    });
  }

  static void _showToastOverlay({
    required int coins,
    required int xp,
    required bool isGroupTask,
  }) {
    // Remove any existing overlay
    _currentOverlay?.remove();
    _currentOverlay = null;

    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('❌ ToastService: Navigator state is null');
      return;
    }

    final overlay = navigatorState.overlay;
    if (overlay == null) {
      debugPrint('❌ ToastService: Overlay is null');
      return;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => _RewardToastWidget(
        coins: coins,
        xp: xp,
        isGroupTask: isGroupTask,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlay.insert(_currentOverlay!);
    debugPrint('✅ ToastService: Overlay inserted successfully');

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  /// Show a simple message toast
  static void showMessage(String message, {bool isError = false}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('❌ ToastService: No context available');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _RewardToastWidget extends StatefulWidget {
  final int coins;
  final int xp;
  final bool isGroupTask;
  final VoidCallback onDismiss;

  const _RewardToastWidget({
    required this.coins,
    required this.xp,
    required this.isGroupTask,
    required this.onDismiss,
  });

  @override
  State<_RewardToastWidget> createState() => _RewardToastWidgetState();
}

class _RewardToastWidgetState extends State<_RewardToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isGroupTask
                      ? [Colors.purple.shade600, Colors.purple.shade800]
                      : [Colors.green.shade500, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isGroupTask ? '🎯 Team Bonus!' : '🎉 Awesome!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Task completed!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rewards
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.coins}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.stars,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.xp}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
