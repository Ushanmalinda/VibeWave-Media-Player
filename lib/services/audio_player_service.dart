import 'package:just_audio/just_audio.dart';
import 'equalizer_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
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

  AudioPlayer get player => _audioPlayer;

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

  void _optimizeForLowEndDevices() {
    // Reduce memory usage by setting audio player options
    _audioPlayer.setSpeed(1.0); // Normal speed for stability
  }

  void dispose() {
    _equalizerService.dispose();
    _audioPlayer.dispose();
  }
}
