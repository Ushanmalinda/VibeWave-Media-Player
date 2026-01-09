import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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

  static const platform = MethodChannel('com.vibewave.player/shake');

  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _headsetSubscription;
  Timer? _sensorKeepAliveTimer;

  DateTime? _lastShakeTime;
  double _lastVolume = 0.5;
  DateTime? _lastHeadsetTap;
  int _headsetTapCount = 0;
  Timer? _headsetTapTimer;
  DateTime? _lastSensorEvent;

  // For shake direction detection
  double _lastAccelX = 0;
  double _lastAccelY = 0;
  double _lastAccelZ = 0;

  bool _isInitialized = false;
  bool _methodHandlerSet = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _settings.initialize();
    _lastVolume = await _volumeController.getVolume();

    // Set method call handler only once
    if (!_methodHandlerSet) {
      _setShakeMethodHandler();
      _methodHandlerSet = true;
    }

    _setupNativeShakeDetection();
    _setupVolumeListener();
    _setupHeadsetListener();

    _isInitialized = true;
  }

  void dispose() {
    _stopNativeShakeDetection();
    _accelerometerSubscription?.cancel();
    _volumeSubscription?.cancel();
    _headsetSubscription?.cancel();
    _headsetTapTimer?.cancel();
    _sensorKeepAliveTimer?.cancel();
  }

  // Set up method handler once (called only at initialization)
  void _setShakeMethodHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'shake') {
        final action = call.arguments['action'] as String;
        print('Shake event received from native: $action');
        print('About to execute action: $action');
        try {
          await _executeAction(action);
          print('Action executed successfully: $action');
        } catch (e) {
          print('ERROR executing action: $e');
        }
      }
    });
  }

  // Native shake detection (Android)
  Future<void> _setupNativeShakeDetection() async {
    print(
      '_setupNativeShakeDetection called, shakeEnabled: ${_settings.shakeEnabled}',
    );

    if (!_settings.shakeEnabled) {
      print('Shake detection is disabled in settings');
      return;
    }

    try {
      // Set sensitivity
      await platform.invokeMethod('setSensitivity', {
        'sensitivity': _settings.shakeSensitivity,
      });
      print('Set shake sensitivity to: ${_settings.shakeSensitivity}');

      // Start native shake detection
      await platform.invokeMethod('start');
      print('Native shake detection started successfully');
    } catch (e) {
      print('Native shake detection error: $e');
      print('Falling back to Flutter implementation');
      // Native shake detection not available, fall back to Flutter implementation
      _setupShakeDetection();
    }
  }

  Future<void> _stopNativeShakeDetection() async {
    try {
      await platform.invokeMethod('stop');
    } catch (e) {
      // Ignore errors
    }
  }

  // Shake Detection with Direction
  void _setupShakeDetection() {
    _accelerometerSubscription?.cancel();
    _sensorKeepAliveTimer?.cancel();

    _accelerometerSubscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(
            milliseconds: 50,
          ), // Faster sampling for better lock screen detection
        ).listen(
          (AccelerometerEvent event) {
            // Track last sensor event time
            _lastSensorEvent = DateTime.now();

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
                  now.difference(_lastShakeTime!).inMilliseconds > 300) {
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

                // Reset shake time after a short delay to allow immediate next shake
                Future.delayed(const Duration(milliseconds: 200), () {
                  _lastShakeTime = null;
                });
              }
            }

            // Store current values for next comparison
            _lastAccelX = event.x;
            _lastAccelY = event.y;
            _lastAccelZ = event.z;
          },
          onError: (error) {
            // If sensor stream errors, restart it
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_settings.shakeEnabled) {
                _setupShakeDetection();
              }
            });
          },
          cancelOnError: false,
        );

    // Start keep-alive timer to restart sensor if it stops receiving events
    _sensorKeepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_settings.shakeEnabled && _lastSensorEvent != null) {
        final now = DateTime.now();
        // If no sensor events for 2 seconds, restart the stream
        if (now.difference(_lastSensorEvent!).inSeconds > 2) {
          _setupShakeDetection();
        }
      }
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
    print('_executeAction called with: $action');
    final player = _audioService.player;
    print(
      'Player state - playing: ${player.playing}, position: ${player.position}',
    );

    switch (action) {
      case 'play_pause':
        print('Executing play_pause');
        if (player.playing) {
          await player.pause();
        } else {
          await player.play();
        }
        break;

      case 'next':
        print(
          'Executing next - currentIndex: ${_queueService.currentIndex}, queueLength: ${_queueService.queueLength}',
        );
        if (_queueService.currentIndex < _queueService.queueLength - 1) {
          print('Calling playNext()');
          _queueService.playNext();
          print('playNext() called successfully');
        } else {
          print('Cannot go next - already at last track');
        }
        break;

      case 'previous':
        print(
          'Executing previous - currentIndex: ${_queueService.currentIndex}',
        );
        if (_queueService.currentIndex > 0) {
          print('Calling playPrevious()');
          _queueService.playPrevious();
          print('playPrevious() called successfully');
        } else {
          print('Cannot go previous - already at first track');
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

  // Public method to ensure shake detection is running (doesn't restart if already running)
  Future<void> ensureShakeDetectionRunning() async {
    if (_settings.shakeEnabled) {
      // Only start if not already started - native service handles this gracefully
      await _setupNativeShakeDetection();
      print('Ensured shake detection is running');
    }
  }

  // Public method to re-enable shake detection (useful when screen is locked/unlocked)
  Future<void> restartShakeDetection() async {
    if (_settings.shakeEnabled) {
      // Stop and restart native shake detection
      await _stopNativeShakeDetection();
      await Future.delayed(const Duration(milliseconds: 100));
      await _setupNativeShakeDetection();
      print('Shake detection restarted');
    }
  }

  // Public method to manage wakelock based on playback state
  Future<void> updateWakeLock(bool isPlaying) async {
    if (_settings.shakeEnabled && isPlaying) {
      try {
        await WakelockPlus.enable();
      } catch (e) {
        // Wakelock not supported
      }
    } else {
      try {
        await WakelockPlus.disable();
      } catch (e) {
        // Ignore errors
      }
    }
  }
}
