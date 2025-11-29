import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:check_bird/models/focus/focus_session.dart';
import 'package:check_bird/services/focus_service.dart';
import 'package:check_bird/services/ambient_sound_service.dart';

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
  final AmbientSoundService _ambientService = AmbientSoundService();

  late AnimationController _pulseController;
  late AnimationController _progressController;

  bool _showSettings = false;

  // Ambient sounds configuration
  String? _selectedAmbience;
  final List<Map<String, dynamic>> _ambienceSounds = [
    {'name': 'None', 'icon': Icons.volume_off, 'color': Colors.grey},
    {'name': 'Rain', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': 'Forest', 'icon': Icons.forest, 'color': Colors.green},
    {'name': 'Café', 'icon': Icons.coffee, 'color': Colors.brown},
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
    _ambientService.addListener(_onAmbientUpdate);

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
    if (mounted) setState(() {});
  }

  void _onAmbientUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusService.removeListener(_onServiceUpdate);
    _ambientService.removeListener(_onAmbientUpdate);
    _pulseController.dispose();
    _progressController.dispose();
    _ambientService.stop();
    super.dispose();
  }

  Future<void> _playAmbientSound(String soundName) async {
    if (soundName == 'None') {
      await _ambientService.stop();
      return;
    }

    final success = await _ambientService.play(soundName);
    if (!success && mounted) {
      setState(() => _selectedAmbience = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ambientService.errorMessage ?? 'Could not play sound'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSettings ? Icons.close_rounded : Icons.tune_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() => _showSettings = !_showSettings);
            },
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: colorScheme.onSurface),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: '${stats.totalFocusMinutes}',
            label: 'Minutes',
            color: colorScheme.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.emoji_events_outlined,
            value: '${stats.pomodorosCompleted}',
            label: 'Sessions',
            color: Colors.orange,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.star_outline_rounded,
            value: '${stats.totalXpEarned}',
            label: 'XP',
            color: Colors.purple,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.monetization_on_outlined,
            value: '${stats.totalCoinsEarned}',
            label: 'Coins',
            color: Colors.amber.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
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
            fontSize: 11,
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
    final isRunning = _focusService.isRunning;
    final colorScheme = Theme.of(context).colorScheme;

    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    final progress = isActive && session.plannedMinutes > 0
        ? 1 - (remaining.inSeconds / (session.plannedMinutes * 60))
        : 0.0;

    final sessionColor =
        isActive ? _getSessionColor(session.type) : colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final breatheScale =
            isRunning ? 1.0 + (0.015 * _pulseController.value) : 1.0;

        return Transform.scale(
          scale: breatheScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative ring with gradient
              Container(
                width: 290,
                height: 290,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      sessionColor.withOpacity(0.08),
                      sessionColor.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.7, 0.9, 1.0],
                  ),
                ),
              ),

              // Background circle
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Progress ring
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: ProgressRingPainter(
                    progress: progress,
                    color: sessionColor,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),

              // Inner white circle
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer text
                    Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        color: colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Session type label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: sessionColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive
                            ? _getSessionTypeLabel(session.type)
                            : 'Ready to Focus',
                        style: TextStyle(
                          fontSize: 13,
                          color: sessionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        return '🧠 Deep Focus';
      case SessionType.shortBreak:
        return '☕ Quick Rest';
      case SessionType.longBreak:
        return '🌴 Recharge';
    }
  }

  Widget _buildAmbienceSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(Icons.music_note_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Ambient Sounds',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ambienceSounds.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final sound = _ambienceSounds[index];
              final soundName = sound['name'] as String;
              final isSelected = _selectedAmbience == soundName;
              final color = sound['color'] as Color;

              final isLoading =
                  _ambientService.isLoading && _selectedAmbience == soundName;
              final isPlaying = _ambientService.isPlaying &&
                  _ambientService.currentSound == soundName;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: _ambientService.isLoading
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          if (isSelected) {
                            setState(() => _selectedAmbience = null);
                            await _ambientService.stop();
                          } else {
                            setState(() => _selectedAmbience = soundName);
                            await _playAmbientSound(soundName);
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          )
                        else if (isPlaying)
                          Icon(
                            Icons.volume_up_rounded,
                            color: color,
                            size: 24,
                          )
                        else
                          Icon(
                            sound['icon'],
                            color: isSelected
                                ? color
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          soundName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? color
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    final isRunning = _focusService.isRunning;
    final hasActiveSession = _focusService.currentSession != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasActiveSession) ...[
          // Cancel button
          _buildControlButton(
            icon: Icons.stop_rounded,
            color: Colors.red.shade400,
            backgroundColor: Colors.red.withOpacity(0.1),
            onTap: _showCancelDialog,
            size: 56,
          ),
          const SizedBox(width: 24),
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
                  colorScheme.primary,
                  colorScheme.primary.withBlue(255),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              !hasActiveSession
                  ? Icons.play_arrow_rounded
                  : (isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
              size: 42,
              color: colorScheme.onPrimary,
            ),
          ),
        ),

        if (hasActiveSession) ...[
          const SizedBox(width: 24),
          // Add time button
          _buildControlButton(
            icon: Icons.add_rounded,
            color: colorScheme.primary,
            backgroundColor: colorScheme.primaryContainer,
            onTap: () {
              HapticFeedback.lightImpact();
              _focusService.addExtraTime(5);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('+5 minutes added'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            size: 56,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  void _showSessionTypeDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '🎯 Start a Session',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your focus mode',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _buildSessionTypeOption(
                title: 'Focus Session',
                subtitle:
                    '${_focusService.settings.focusDuration} minutes of deep work',
                icon: Icons.psychology_rounded,
                color: colorScheme.primary,
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
                    '${_focusService.settings.shortBreakDuration} minutes to refresh',
                icon: Icons.coffee_rounded,
                color: const Color(0xFF4CAF50),
                onTap: () {
                  Navigator.pop(context);
                  _focusService.startShortBreak();
                },
              ),
              const SizedBox(height: 12),
              _buildSessionTypeOption(
                title: 'Long Break',
                subtitle:
                    '${_focusService.settings.longBreakDuration} minutes to recharge',
                icon: Icons.self_improvement_rounded,
                color: const Color(0xFF2196F3),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
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
