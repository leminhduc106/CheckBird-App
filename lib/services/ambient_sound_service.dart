import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// A simple, robust service for playing ambient sounds
class AmbientSoundService extends ChangeNotifier {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  AmbientSoundService._internal();

  AudioPlayer? _player;
  String? _currentSound;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _errorMessage;
  StreamSubscription? _playerStateSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String? get currentSound => _currentSound;
  String? get errorMessage => _errorMessage;

  // Map sound names to asset paths
  static const Map<String, String> _soundAssets = {
    'Rain': 'assets/audio/rain.mp3',
    'Forest': 'assets/audio/forest.mp3',
    'Café': 'assets/audio/cafe.mp3',
    'Ocean': 'assets/audio/ocean.mp3',
    'Fire': 'assets/audio/fire.mp3',
  };

  /// Play a sound by name
  Future<bool> play(String soundName) async {
    final assetPath = _soundAssets[soundName];
    if (assetPath == null) {
      _handleError('Unknown sound: $soundName');
      return false;
    }

    // Don't reload if same sound is already playing
    if (_currentSound == soundName && _isPlaying) {
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Clean up existing player completely
      await _cleanup();

      // Create fresh player
      _player = AudioPlayer();
      debugPrint('AmbientSound: Created AudioPlayer');

      // Set up state listener
      _playerStateSubscription = _player!.playerStateStream.listen(
        (state) {
          debugPrint(
              'AmbientSound: ${state.processingState} / playing=${state.playing}');

          final newIsPlaying =
              state.playing && state.processingState == ProcessingState.ready;

          if (_isPlaying != newIsPlaying) {
            _isPlaying = newIsPlaying;
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('AmbientSound: Stream error - $e');
        },
      );

      // Use setAsset directly - this is the standard way
      debugPrint('AmbientSound: Loading $assetPath...');

      // Use AudioSource.asset for better compatibility
      await _player!
          .setAudioSource(
        AudioSource.asset(assetPath),
        preload: true,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('AmbientSound: TIMEOUT loading asset');
          throw TimeoutException('Loading timed out');
        },
      );

      debugPrint('AmbientSound: Loaded!');

      // Configure and play - set volume to maximum
      await _player!.setVolume(1.0);
      await _player!.setLoopMode(LoopMode.one);

      debugPrint('AmbientSound: Calling play()...');
      _player!.play(); // Don't await play - it can block

      _currentSound = soundName;
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();

      debugPrint('AmbientSound: Success - playing $soundName');
      return true;
    } on TimeoutException {
      debugPrint('AmbientSound: Timeout exception');
      _handleError('Loading timed out');
      return false;
    } catch (e, stack) {
      debugPrint('AmbientSound: Exception - $e');
      debugPrint('$stack');
      _handleError('Could not play sound');
      return false;
    }
  }

  Future<void> _cleanup() async {
    try {
      await _playerStateSubscription?.cancel();
      _playerStateSubscription = null;
      await _player?.stop();
      await _player?.dispose();
      _player = null;
    } catch (e) {
      debugPrint('AmbientSound: Cleanup error - $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    debugPrint('AmbientSound: Stopping...');
    await _cleanup();
    _currentSound = null;
    _isPlaying = false;
    _isLoading = false;
    notifyListeners();
    debugPrint('AmbientSound: Stopped');
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Handle errors
  void _handleError(String message) {
    _errorMessage = message;
    _isLoading = false;
    _currentSound = null;
    _isPlaying = false;
    _cleanup();
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
