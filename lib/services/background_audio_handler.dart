import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Background audio handler to keep music playing when app is in background
/// This prevents Android from killing the app after 5 minutes
class BackgroundAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player;

  BackgroundAudioHandler(this._player) {
    // Listen to player state changes and update system
    _player.playingStream.listen((playing) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          processingState: AudioProcessingState.ready,
        ),
      );
    });

    // Update position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // This will be connected to your queue service
  }

  @override
  Future<void> skipToPrevious() async {
    // This will be connected to your queue service
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Update the current media item being played
  void updateNowPlaying(String title, String artist, {Duration? duration}) {
    mediaItem.add(
      MediaItem(
        id: title,
        title: title,
        artist: artist,
        duration: duration ?? Duration.zero,
      ),
    );
  }
}
