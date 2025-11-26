import 'dart:async';
import 'package:flutter/material.dart';

/// Data class for reward toast
class RewardToastData {
  final int coins;
  final int xp;
  final bool isGroupTask;
  final DateTime timestamp;

  RewardToastData({
    required this.coins,
    required this.xp,
    this.isGroupTask = false,
  }) : timestamp = DateTime.now();
}

/// Global controller for showing reward toasts
class RewardToastController {
  static final RewardToastController _instance = RewardToastController._();
  factory RewardToastController() => _instance;
  RewardToastController._();

  final _toastStream = StreamController<RewardToastData>.broadcast();
  Stream<RewardToastData> get stream => _toastStream.stream;

  void showReward({
    required int coins,
    required int xp,
    bool isGroupTask = false,
  }) {
    debugPrint(
        '🎉 RewardToastController: Broadcasting toast +$coins coins, +$xp XP');
    _toastStream.add(RewardToastData(
      coins: coins,
      xp: xp,
      isGroupTask: isGroupTask,
    ));
  }

  void dispose() {
    _toastStream.close();
  }
}

/// Wrap your app with this to enable reward toasts
class RewardToastOverlay extends StatefulWidget {
  final Widget child;

  const RewardToastOverlay({super.key, required this.child});

  @override
  State<RewardToastOverlay> createState() => _RewardToastOverlayState();
}

class _RewardToastOverlayState extends State<RewardToastOverlay>
    with SingleTickerProviderStateMixin {
  RewardToastData? _currentToast;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  StreamSubscription? _subscription;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _subscription = RewardToastController().stream.listen(_onToast);
  }

  void _onToast(RewardToastData data) {
    debugPrint('🔔 RewardToastOverlay: Received toast data');
    _dismissTimer?.cancel();

    setState(() {
      _currentToast = data;
    });

    _animationController.forward(from: 0);

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentToast = null;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_currentToast != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: () {
                      _dismissTimer?.cancel();
                      _animationController.reverse().then((_) {
                        if (mounted) {
                          setState(() {
                            _currentToast = null;
                          });
                        }
                      });
                    },
                    child: _buildToastCard(_currentToast!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToastCard(RewardToastData data) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.isGroupTask
                ? [Colors.purple.shade600, Colors.purple.shade800]
                : [Colors.green.shade500, Colors.green.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Icon + Text
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.isGroupTask
                            ? '🎯 Team Bonus!'
                            : '🎉 Task Complete!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Keep up the great work!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: Rewards in white container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coins
                  Icon(
                    Icons.monetization_on,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${data.coins}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'coins',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // XP
                  Icon(
                    Icons.stars,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${data.xp}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'XP',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
