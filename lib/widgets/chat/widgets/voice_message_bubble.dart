import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationMs,
    required this.isMe,
    required this.constraints,
    this.onLongPress,
    this.replyPreview,
  });

  final String audioUrl;
  final int durationMs;
  final bool isMe;
  final BoxConstraints constraints;
  final VoidCallback? onLongPress;
  final Widget? replyPreview;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _progress = 0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _totalDuration = Duration(milliseconds: widget.durationMs);
    _setupPlayer();
  }

  void _setupPlayer() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (_totalDuration.inMilliseconds > 0) {
            _progress = position.inMilliseconds / _totalDuration.inMilliseconds;
          }
        });
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _progress = 0;
            _currentPosition = Duration.zero;
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_audioPlayer.duration == null) {
          setState(() => _isLoading = true);
          await _audioPlayer.setUrl(widget.audioUrl);
          final duration = _audioPlayer.duration;
          if (duration != null) {
            setState(() => _totalDuration = duration);
          }
          setState(() => _isLoading = false);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _isLoading = false);
    }
  }

  void _seekTo(double value) async {
    final position = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).round(),
    );
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceVariant;
    final foregroundColor = widget.isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Material(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
          bottomRight: Radius.circular(widget.isMe ? 6 : 20),
        ),
        color: backgroundColor,
        elevation: 0,
        child: InkWell(
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
            bottomRight: Radius.circular(widget.isMe ? 6 : 20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: widget.constraints.maxWidth * 0.75,
              minWidth: 200,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.replyPreview != null) widget.replyPreview!,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play/Pause button
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: foregroundColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: foregroundColor,
                                ),
                              )
                            : Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: foregroundColor,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Waveform/Progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom waveform-like progress bar
                          _WaveformProgressBar(
                            progress: _progress,
                            isPlaying: _isPlaying,
                            foregroundColor: foregroundColor,
                            onSeek: _seekTo,
                          ),
                          const SizedBox(height: 4),
                          // Duration text
                          Text(
                            _isPlaying || _progress > 0
                                ? _formatDuration(_currentPosition)
                                : _formatDuration(_totalDuration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: foregroundColor.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Voice message icon
                    Icon(
                      Icons.mic_rounded,
                      color: foregroundColor.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformProgressBar extends StatelessWidget {
  const _WaveformProgressBar({
    required this.progress,
    required this.isPlaying,
    required this.foregroundColor,
    required this.onSeek,
  });

  final double progress;
  final bool isPlaying;
  final Color foregroundColor;
  final void Function(double) onSeek;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final newProgress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(newProgress);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final newProgress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek(newProgress);
      },
      child: SizedBox(
        height: 24,
        child: CustomPaint(
          size: const Size(double.infinity, 24),
          painter: _WaveformPainter(
            progress: progress,
            isPlaying: isPlaying,
            foregroundColor: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.foregroundColor,
  });

  final double progress;
  final bool isPlaying;
  final Color foregroundColor;

  // Pre-generated waveform pattern (simulated)
  static const List<double> _waveformData = [
    0.3,
    0.5,
    0.4,
    0.7,
    0.5,
    0.8,
    0.6,
    0.4,
    0.7,
    0.9,
    0.5,
    0.6,
    0.8,
    0.4,
    0.6,
    0.7,
    0.5,
    0.9,
    0.6,
    0.4,
    0.7,
    0.5,
    0.8,
    0.6,
    0.4,
    0.7,
    0.5,
    0.3,
    0.6,
    0.8,
    0.5,
    0.7,
    0.4,
    0.6,
    0.8,
    0.5,
    0.7,
    0.4,
    0.6,
    0.3,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final barSpacing = 2.0;
    final totalBars = (size.width / (barWidth + barSpacing)).floor();
    final centerY = size.height / 2;

    for (var i = 0; i < totalBars; i++) {
      final x = i * (barWidth + barSpacing);
      final dataIndex = (i * _waveformData.length / totalBars).floor();
      final amplitude = _waveformData[dataIndex % _waveformData.length];
      final barHeight = amplitude * size.height * 0.8;

      final barProgress = i / totalBars;
      final isPlayed = barProgress <= progress;

      final paint = Paint()
        ..color = isPlayed ? foregroundColor : foregroundColor.withOpacity(0.3)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight / 2),
        Offset(x + barWidth / 2, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}

/// Helper function to parse voice message data (url|duration format)
class VoiceMessageData {
  final String url;
  final int durationMs;

  VoiceMessageData({required this.url, required this.durationMs});

  factory VoiceMessageData.parse(String data) {
    final parts = data.split('|');
    if (parts.length >= 2) {
      return VoiceMessageData(
        url: parts[0],
        durationMs: int.tryParse(parts[1]) ?? 0,
      );
    }
    // Fallback for old format (just URL)
    return VoiceMessageData(url: data, durationMs: 0);
  }
}
