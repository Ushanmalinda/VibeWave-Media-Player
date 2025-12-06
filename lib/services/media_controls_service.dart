import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class MediaControlsService {
  static const platform = MethodChannel('com.vibewave.player/media_controls');

  static Future<void> setupMediaControls({
    required AudioPlayer player,
    required Function() onNext,
    required Function() onPrevious,
  }) async {
    // Listen to platform method calls
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'play':
          await player.play();
          break;
        case 'pause':
          await player.pause();
          break;
        case 'next':
          onNext();
          break;
        case 'previous':
          onPrevious();
          break;
      }
    });

    // Setup notification listener
    player.playingStream.listen((playing) {
      _updatePlaybackState(playing);
    });

    player.positionStream.listen((position) {
      _updatePosition(position);
    });
  }

  static Future<void> updateMetadata({
    required String title,
    String? artist,
    String? album,
    Duration? duration,
  }) async {
    try {
      await platform.invokeMethod('updateMetadata', {
        'title': title,
        'artist': artist ?? 'Unknown Artist',
        'album': album ?? 'Unknown Album',
        'duration': duration?.inMilliseconds ?? 0,
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  static Future<void> _updatePlaybackState(bool playing) async {
    try {
      await platform.invokeMethod('updatePlaybackState', {'playing': playing});
    } catch (e) {
      // Silently handle errors
    }
  }

  static Future<void> _updatePosition(Duration position) async {
    try {
      await platform.invokeMethod('updatePosition', {
        'position': position.inMilliseconds,
      });
    } catch (e) {
      // Silently handle errors
    }
  }

  static Future<void> dispose() async {
    try {
      await platform.invokeMethod('dispose');
    } catch (e) {
      // Silently handle errors
    }
  }
}
