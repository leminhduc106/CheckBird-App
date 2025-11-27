import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  final void Function(File audioFile, int durationMs) onRecordingComplete;
  final VoidCallback onCancel;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  double _slideOffset = 0;
  bool _isCancelled = false;
  String? _recordPath;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _cancelThreshold = -100;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _recordPath = p.join(
          directory.path,
          'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordPath!,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });

        // Haptic feedback
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording({bool cancelled = false}) async {
    _timer?.cancel();

    if (_isRecording) {
      final path = await _recorder.stop();

      if (cancelled || _isCancelled) {
        // Delete the file if cancelled
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        widget.onCancel();
      } else if (path != null && _recordDuration > 0) {
        final file = File(path);
        widget.onRecordingComplete(file, _recordDuration * 1000);
      } else {
        widget.onCancel();
      }
    }

    setState(() {
      _isRecording = false;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelZone = _slideOffset < _cancelThreshold;
    // Calculate cancel progress (0 to 1)
    final cancelProgress =
        (_slideOffset.abs() / _cancelThreshold.abs()).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _slideOffset += details.delta.dx;
            if (_slideOffset > 0) _slideOffset = 0;
            // Limit how far left you can slide
            if (_slideOffset < -150) _slideOffset = -150;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_slideOffset < _cancelThreshold) {
            _isCancelled = true;
            HapticFeedback.mediumImpact();
            _stopRecording(cancelled: true);
          } else {
            // Snap back
            setState(() {
              _slideOffset = 0;
            });
          }
        },
        child: Row(
          children: [
            // Left: Trash icon (like Facebook) - tappable to cancel
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _isCancelled = true;
                _stopRecording(cancelled: true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCancelZone
                      ? Colors.red
                      : Colors.grey.withOpacity(0.2 + cancelProgress * 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: isCancelZone ? Colors.white : Colors.red,
                  size: 20,
                ),
              ),
            ),

            const Spacer(),

            // Center: Recording indicator + Duration (slides with gesture)
            Transform.translate(
              offset: Offset(_slideOffset, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isCancelZone ? 0.5 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recording indicator
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Duration
                    Text(
                      _formatDuration(_recordDuration),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Right: Send button
            GestureDetector(
              onTap: () {
                if (!isCancelZone) {
                  _stopRecording();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCancelZone
                      ? Colors.grey.shade400
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: isCancelZone
                      ? Colors.grey.shade600
                      : theme.colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A button that triggers voice recording on long press
class VoiceRecordButton extends StatefulWidget {
  const VoiceRecordButton({
    super.key,
    required this.onStartRecording,
    this.size = 48,
  });

  final VoidCallback onStartRecording;
  final double size;

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        _scaleController.forward();
        HapticFeedback.mediumImpact();
        widget.onStartRecording();
      },
      onLongPressEnd: (_) {
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}
