import 'package:flutter/material.dart';
import '../models/media_item.dart';

class PlaybackManager extends ChangeNotifier {
  static final PlaybackManager _instance = PlaybackManager._internal();
  factory PlaybackManager() => _instance;
  PlaybackManager._internal();

  MediaItem? _currentlyPlaying;
  bool _isPlaying = false;
  bool _isFullVideoActive = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  MediaItem? get currentlyPlaying => _currentlyPlaying;
  bool get isPlaying => _isPlaying;
  bool get isFullVideoActive => _isFullVideoActive;
  Duration get position => _position;
  Duration get duration => _duration;

  void setFullVideoActive(bool active) {
    if (_isFullVideoActive != active) {
      _isFullVideoActive = active;
      notifyListeners();
    }
  }

  void updateCurrentlyPlaying(MediaItem? item) {
    _currentlyPlaying = item;
    notifyListeners();
  }

  void updatePlayingState(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void updatePosition(Duration position) {
    _position = position;
    // Avoid notifyListeners() here: position ticks fire 20 times/sec and would cause 20 full-screen rebuilds/sec
  }

  void updateDuration(Duration duration) {
    if (_duration != duration) {
      _duration = duration;
      notifyListeners();
    }
  }

  void clearPlayback() {
    _currentlyPlaying = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }
}
