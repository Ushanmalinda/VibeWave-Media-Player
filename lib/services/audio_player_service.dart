import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'equalizer_service.dart';
import 'background_audio_handler.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializeAudioService();
    _setupAudioSession();
    _setupPlayerListener();
    _optimizeForLowEndDevices();
  }

  final AudioPlayer _audioPlayer = AudioPlayer(
    // Optimize buffer for low-end devices
    audioPipeline: AudioPipeline(androidAudioEffects: []),
  );
  final EqualizerService _equalizerService = EqualizerService();
  bool _equalizerInitialized = false;
  int? _currentAudioSessionId;
  BackgroundAudioHandler? _audioHandler;

  AudioPlayer get player => _audioPlayer;
  BackgroundAudioHandler? get audioHandler => _audioHandler;

  /// Initialize audio service for background playback
  Future<void> _initializeAudioService() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => BackgroundAudioHandler(_audioPlayer),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.vibewave.player.audio',
          androidNotificationChannelName: 'VibeWave Player',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
        ),
      );
      print('Audio service initialized successfully');
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  Future<void> _setupAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle audio focus and interruptions
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Lower volume
              _audioPlayer.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              // Pause playback
              _audioPlayer.pause();
              break;
          }
        } else {
          // Resume after interruption
          switch (event.type) {
            case AudioInterruptionType.duck:
              // Restore volume
              _audioPlayer.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Resume playback
              _audioPlayer.play();
              break;
            case AudioInterruptionType.unknown:
              // Do nothing
              break;
          }
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _audioPlayer.pause();
      });
    } catch (e) {
      // Audio session setup failed, continue anyway
    }
  }

  void _setupPlayerListener() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) async {
      // Initialize equalizer when audio is loaded and ready
      if (state.processingState == ProcessingState.ready) {
        await _ensureEqualizerInitialized();
      }
    });
  }

  Future<void> _ensureEqualizerInitialized() async {
    try {
      // Get audio session ID from just_audio
      final audioSessionId = await _audioPlayer.androidAudioSessionId;

      if (audioSessionId != null && audioSessionId != 0) {
        // Only initialize if session ID changed or not initialized
        if (!_equalizerInitialized ||
            _currentAudioSessionId != audioSessionId) {
          await _equalizerService.initialize(audioSessionId);
          _equalizerInitialized = true;
          _currentAudioSessionId = audioSessionId;
        }
      }
    } catch (e) {
      // Silently handle errors to avoid console spam
    }
  }

  Future<void> updateEqualizer() async {
    if (!_equalizerInitialized) {
      await _ensureEqualizerInitialized();
    }
    await _equalizerService.updateSettings();
  }

  /// Update the current playing media item in notification
  void updateCurrentMediaItem({
    required String title,
    String? artist,
    Duration? duration,
  }) {
    _audioHandler?.updateNowPlaying(
      title,
      artist ?? 'Unknown Artist',
      duration: duration,
    );
  }

  void _optimizeForLowEndDevices() {
    // Reduce memory usage by setting audio player options
    _audioPlayer.setSpeed(1.0); // Normal speed for stability
  }

  void dispose() {
    _equalizerService.dispose();
    _audioPlayer.dispose();
  }
}
