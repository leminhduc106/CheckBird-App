import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/focus/focus_session.dart';
import 'package:check_bird/services/focus_service.dart';

class EnhancedFocusScreen extends StatefulWidget {
  final String? taskId;
  final String? taskName;

  const EnhancedFocusScreen({
    super.key,
    this.taskId,
    this.taskName,
  });

  @override
  State<EnhancedFocusScreen> createState() => _EnhancedFocusScreenState();
}

class _EnhancedFocusScreenState extends State<EnhancedFocusScreen>
    with TickerProviderStateMixin {
  final FocusService _focusService = FocusService();

  late AnimationController _pulseController;
  late AnimationController _progressController;

  bool _showSettings = false;

  // Ambient sounds
  String? _selectedAmbience;
  final List<Map<String, dynamic>> _ambienceSounds = [
    {'name': 'None', 'icon': Icons.volume_off, 'color': Colors.grey},
    {'name': 'Rain', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Forest', 'icon': Icons.forest, 'color': Colors.green},
    {'name': 'Coffee Shop', 'icon': Icons.coffee, 'color': Colors.brown},
    {'name': 'Ocean', 'icon': Icons.waves, 'color': Colors.cyan},
    {
      'name': 'Fire',
      'icon': Icons.local_fire_department,
      'color': Colors.orange
    },
  ];

  @override
  void initState() {
    super.initState();
    _focusService.initialize();
    _focusService.addListener(_onServiceUpdate);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusService.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: _getBackgroundColor(colorScheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSettings ? Icons.close : Icons.settings,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() => _showSettings = !_showSettings);
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.onSurface),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSettings ? _buildSettings() : _buildMainContent(),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    final session = _focusService.currentSession;
    if (session == null) return colorScheme.surface;

    switch (session.type) {
      case SessionType.focus:
        return colorScheme.primaryContainer.withOpacity(0.3);
      case SessionType.shortBreak:
        return Colors.green.withOpacity(0.1);
      case SessionType.longBreak:
        return Colors.blue.withOpacity(0.1);
    }
  }

  String _getAppBarTitle() {
    final session = _focusService.currentSession;
    if (session == null) return 'Focus Timer';

    switch (session.type) {
      case SessionType.focus:
        return 'Focus Time';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Task indicator
            if (widget.taskName != null) ...[
              _buildTaskIndicator(),
              const SizedBox(height: 24),
            ],

            // Today's stats
            _buildTodayStats(),
            const SizedBox(height: 32),

            // Timer display
            Expanded(
              child: Center(
                child: _buildTimerDisplay(),
              ),
            ),

            // Ambience selector
            _buildAmbienceSelector(),
            const SizedBox(height: 24),

            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.taskName!,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    final stats = _focusService.todayStats;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.timer,
          value: '${stats.totalFocusMinutes}',
          label: 'Minutes',
          color: colorScheme.primary,
        ),
        _buildStatItem(
          icon: Icons.emoji_events,
          value: '${stats.pomodorosCompleted}',
          label: 'Sessions',
          color: Colors.orange,
        ),
        _buildStatItem(
          icon: Icons.star,
          value: '${stats.totalXpEarned}',
          label: 'XP',
          color: Colors.purple,
        ),
        _buildStatItem(
          icon: Icons.monetization_on,
          value: '${stats.totalCoinsEarned}',
          label: 'Coins',
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    final remaining = _focusService.remainingTime;
    final session = _focusService.currentSession;
    final isActive = session != null;

    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    final progress = isActive && session.plannedMinutes > 0
        ? 1 - (remaining.inSeconds / (session.plannedMinutes * 60))
        : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow animation
        if (isActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 280 + (10 * _pulseController.value),
                height: 280 + (10 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getSessionColor(session.type)
                          .withOpacity(0.3 * _pulseController.value),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),

        // Progress ring
        SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: ProgressRingPainter(
              progress: progress,
              color: isActive ? _getSessionColor(session.type) : Colors.grey,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),

        // Timer text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w200,
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (isActive)
              Text(
                _getSessionTypeLabel(session.type),
                style: TextStyle(
                  fontSize: 16,
                  color: _getSessionColor(session.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _getSessionColor(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return Theme.of(context).colorScheme.primary;
      case SessionType.shortBreak:
        return Colors.green;
      case SessionType.longBreak:
        return Colors.blue;
    }
  }

  String _getSessionTypeLabel(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return 'Deep Focus';
      case SessionType.shortBreak:
        return 'Quick Rest';
      case SessionType.longBreak:
        return 'Recharge Time';
    }
  }

  Widget _buildAmbienceSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _ambienceSounds.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final sound = _ambienceSounds[index];
          final isSelected = _selectedAmbience == sound['name'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedAmbience = isSelected ? null : sound['name'];
                });
                // TODO: Play/stop ambient sound
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (sound['color'] as Color).withOpacity(0.2)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: sound['color'], width: 2)
                          : null,
                    ),
                    child: Icon(
                      sound['icon'],
                      color: isSelected ? sound['color'] : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound['name'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? sound['color'] : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
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

  Widget _buildControlButtons() {
    final isRunning = _focusService.isRunning;
    final hasActiveSession = _focusService.currentSession != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasActiveSession) ...[
          // Cancel button
          IconButton(
            onPressed: () => _showCancelDialog(),
            icon: const Icon(Icons.stop),
            iconSize: 32,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(width: 20),
        ],

        // Main play/pause button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (!hasActiveSession) {
              _showSessionTypeDialog();
            } else if (isRunning) {
              _focusService.pauseSession();
            } else {
              _focusService.resumeSession();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              !hasActiveSession
                  ? Icons.play_arrow
                  : (isRunning ? Icons.pause : Icons.play_arrow),
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        if (hasActiveSession) ...[
          const SizedBox(width: 20),
          // Add time button
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _focusService.addExtraTime(5);
            },
            icon: const Icon(Icons.add),
            iconSize: 32,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  void _showSessionTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Start Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSessionTypeOption(
                title: 'Focus',
                subtitle: '${_focusService.settings.focusDuration} minutes',
                icon: Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _focusService.startFocusSession(
                    taskId: widget.taskId,
                    taskName: widget.taskName,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSessionTypeOption(
                title: 'Short Break',
                subtitle:
                    '${_focusService.settings.shortBreakDuration} minutes',
                icon: Icons.coffee,
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _focusService.startShortBreak();
                },
              ),
              const SizedBox(height: 12),
              _buildSessionTypeOption(
                title: 'Long Break',
                subtitle: '${_focusService.settings.longBreakDuration} minutes',
                icon: Icons.self_improvement,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _focusService.startLongBreak();
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'Are you sure you want to end this session early? '
          'Your progress will still be recorded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _focusService.cancelSession();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final settings = _focusService.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timer Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          _buildDurationSetting(
            title: 'Focus Duration',
            subtitle: 'How long each focus session lasts',
            value: settings.focusDuration,
            min: 15,
            max: 60,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(focusDuration: value),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildDurationSetting(
            title: 'Short Break',
            subtitle: 'Quick rest between sessions',
            value: settings.shortBreakDuration,
            min: 3,
            max: 15,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(shortBreakDuration: value),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildDurationSetting(
            title: 'Long Break',
            subtitle: 'Extended rest after several sessions',
            value: settings.longBreakDuration,
            min: 10,
            max: 30,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(longBreakDuration: value),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildDurationSetting(
            title: 'Sessions Before Long Break',
            subtitle: 'Number of focus sessions before long break',
            value: settings.sessionsBeforeLongBreak,
            min: 2,
            max: 6,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(sessionsBeforeLongBreak: value),
              );
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Notifications settings
          SwitchListTile(
            title: const Text('Auto-start breaks'),
            subtitle: const Text('Automatically start breaks after focus'),
            value: settings.autoStartBreaks,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(autoStartBreaks: value),
              );
            },
          ),

          SwitchListTile(
            title: const Text('Auto-start focus'),
            subtitle: const Text('Automatically start focus after breaks'),
            value: settings.autoStartFocus,
            onChanged: (value) {
              _focusService.updateSettings(
                settings.copyWith(autoStartFocus: value),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSetting({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value min',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FocusHistoryScreen(),
      ),
    );
  }
}

/// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// History screen for past focus sessions
class FocusHistoryScreen extends StatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends State<FocusHistoryScreen> {
  final FocusService _focusService = FocusService();
  List<FocusSession> _sessions = [];
  Map<String, int> _weeklyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _focusService.getSessionHistory(limit: 50);
    final weeklyData = await _focusService.getWeeklyFocusMinutes();

    setState(() {
      _sessions = sessions;
      _weeklyData = weeklyData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildWeeklyChart()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                _sessions.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_off,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No focus sessions yet',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildSessionTile(_sessions[index]),
                          childCount: _sessions.length,
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildWeeklyChart() {
    final maxValue =
        _weeklyData.values.isEmpty ? 60 : _weeklyData.values.reduce(math.max);
    final normalizedMax = maxValue == 0 ? 60 : maxValue;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _weeklyData.entries.map((entry) {
              final height = (entry.value / normalizedMax) * 100;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: height.clamp(4, 100),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${entry.value}m',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(FocusSession session) {
    final icon = session.type == SessionType.focus
        ? Icons.psychology
        : (session.type == SessionType.shortBreak
            ? Icons.coffee
            : Icons.self_improvement);

    final color = session.type == SessionType.focus
        ? Theme.of(context).colorScheme.primary
        : (session.type == SessionType.shortBreak ? Colors.green : Colors.blue);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        session.taskName ?? session.type.name.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatSessionTime(session),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${session.actualMinutes} min',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (session.completed)
            const Icon(Icons.check_circle, size: 16, color: Colors.green)
          else if (session.interrupted)
            const Icon(Icons.warning, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  String _formatSessionTime(FocusSession session) {
    final time = session.startTime;
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return 'Today at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
