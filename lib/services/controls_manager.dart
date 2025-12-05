import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:volume_controller/volume_controller.dart';
import 'settings_service.dart';
import 'audio_player_service.dart';
import 'queue_service.dart';

class ControlsManager {
  static final ControlsManager _instance = ControlsManager._internal();
  factory ControlsManager() => _instance;
  ControlsManager._internal();

  final SettingsService _settings = SettingsService();
  final AudioPlayerService _audioService = AudioPlayerService();
  final QueueService _queueService = QueueService();
  final VolumeController _volumeController = VolumeController();

  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _headsetSubscription;

  DateTime? _lastShakeTime;
  double _lastVolume = 0.5;
  DateTime? _lastHeadsetTap;
  int _headsetTapCount = 0;
  Timer? _headsetTapTimer;

  // For shake direction detection
  double _lastAccelX = 0;
  double _lastAccelY = 0;
  double _lastAccelZ = 0;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _settings.initialize();
    _lastVolume = await _volumeController.getVolume();

    _setupShakeDetection();
    _setupVolumeListener();
    _setupHeadsetListener();

    _isInitialized = true;
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _volumeSubscription?.cancel();
    _headsetSubscription?.cancel();
    _headsetTapTimer?.cancel();
  }

  // Shake Detection with Direction
  void _setupShakeDetection() {
    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 100),
        ).listen((AccelerometerEvent event) {
          if (!_settings.shakeEnabled) return;

          // Calculate acceleration deltas for direction detection
          final deltaX = (event.x - _lastAccelX).abs();
          final deltaY = (event.y - _lastAccelY).abs();
          final deltaZ = (event.z - _lastAccelZ).abs();

          // Calculate overall shake intensity
          final double gForce = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          // Sensitivity: 1 = very sensitive (10), 5 = least sensitive (18)
          final double threshold = 10 + (_settings.shakeSensitivity * 2);

          if (gForce > threshold) {
            final now = DateTime.now();
            if (_lastShakeTime == null ||
                now.difference(_lastShakeTime!).inMilliseconds > 500) {
              _lastShakeTime = now;

              // Determine shake direction based on dominant axis
              // X-axis: left/right movement
              // Y-axis: up/down movement
              // Z-axis: forward/backward movement

              if (deltaX > deltaY && deltaX > deltaZ) {
                // Horizontal shake (left/right)
                if (event.x > _lastAccelX + 2) {
                  // Shake to right -> Next track
                  _handleShake('next');
                } else if (event.x < _lastAccelX - 2) {
                  // Shake to left -> Previous track
                  _handleShake('previous');
                } else {
                  // General shake -> Next track (fallback)
                  _handleShake('next');
                }
              } else {
                // Vertical or forward shake -> Next track (default behavior)
                _handleShake('next');
              }
            }
          }

          // Store current values for next comparison
          _lastAccelX = event.x;
          _lastAccelY = event.y;
          _lastAccelZ = event.z;
        });
  }

  void _handleShake(String action) {
    // Execute the shake action (next or previous)
    _executeAction(action);
  }

  // Volume Button Listener
  void _setupVolumeListener() {
    _volumeSubscription = _volumeController.listener((volume) {
      _handleVolumeChange(volume);
    });
  }

  void _handleVolumeChange(double newVolume) async {
    // Check for volume zero/non-zero actions
    if (_settings.pauseOnVolumeZero && newVolume == 0 && _lastVolume > 0) {
      if (_audioService.player.playing) {
        await _audioService.player.pause();
      }
    }

    if (_settings.playOnVolumeNonZero && newVolume > 0 && _lastVolume == 0) {
      if (!_audioService.player.playing) {
        await _audioService.player.play();
      }
    }

    // Check for track switch with volume buttons
    // Volume must be at least 2 points above min and 2 points below max (0.2 to 0.8 range)
    if (_settings.volumeButtonsTrackSwitch &&
        newVolume >= 0.2 &&
        newVolume <= 0.8) {
      // Note: True double-press detection of hardware volume buttons
      // requires native Android implementation via platform channels
      // This is a placeholder for that functionality
    }

    _lastVolume = newVolume;
  } // Headset Button Listener

  void _setupHeadsetListener() {
    // Use audio session to handle media button events
    AudioSession.instance.then((session) {
      session.configure(const AudioSessionConfiguration.music());
      session.becomingNoisyEventStream.listen((_) {
        // Handle headset disconnection
        if (_audioService.player.playing) {
          _audioService.player.pause();
        }
      });
    });

    // Listen for media button events through platform channel
    const platform = MethodChannel('com.example.media_player/media_buttons');
    try {
      platform.setMethodCallHandler((call) async {
        if (call.method == 'mediaButton') {
          _handleHeadsetTap();
        }
      });
    } catch (e) {
      // Platform channel not implemented, skip headset controls
    }
  }

  void _handleHeadsetTap() {
    final now = DateTime.now();

    // Reset tap count if more than 500ms since last tap
    if (_lastHeadsetTap == null ||
        now.difference(_lastHeadsetTap!).inMilliseconds > 500) {
      _headsetTapCount = 0;
    }

    _headsetTapCount++;
    _lastHeadsetTap = now;

    // Cancel existing timer
    _headsetTapTimer?.cancel();

    // Set timer to execute action after 300ms (waiting for more taps)
    _headsetTapTimer = Timer(const Duration(milliseconds: 300), () {
      switch (_headsetTapCount) {
        case 1:
          _executeAction(_settings.headsetSingleTap);
          break;
        case 2:
          _executeAction(_settings.headsetDoubleTap);
          break;
        case 3:
          _executeAction(_settings.headsetTripleTap);
          break;
      }
      _headsetTapCount = 0;
    });
  }

  // Execute action based on setting
  Future<void> _executeAction(String action) async {
    final player = _audioService.player;

    switch (action) {
      case 'play_pause':
        if (player.playing) {
          await player.pause();
        } else {
          await player.play();
        }
        break;

      case 'next':
        if (_queueService.currentIndex < _queueService.queueLength - 1) {
          _queueService.playNext();
        }
        break;

      case 'previous':
        if (_queueService.currentIndex > 0) {
          _queueService.playPrevious();
        }
        break;

      case 'rewind':
        final currentPosition = player.position;
        final newPosition = currentPosition - const Duration(seconds: 10);
        await player.seek(
          newPosition < Duration.zero ? Duration.zero : newPosition,
        );
        break;

      case 'forward':
        final currentPosition = player.position;
        final duration = player.duration ?? Duration.zero;
        final newPosition = currentPosition + const Duration(seconds: 10);
        await player.seek(newPosition > duration ? duration : newPosition);
        break;

      case 'volume':
        // Volume adjustment would typically be handled by system
        break;

      case 'none':
      default:
        // Do nothing
        break;
    }
  }

  // Public method to execute gesture actions
  Future<void> executeGestureAction(String action) async {
    if (_settings.gesturesEnabled) {
      await _executeAction(action);
    }
  }
}
