import 'package:flutter/material.dart';
import '../models/media_item.dart';

class PlaybackManager extends ChangeNotifier {
  static final PlaybackManager _instance = PlaybackManager._internal();
  factory PlaybackManager() => _instance;
  PlaybackManager._internal();

  MediaItem? _currentlyPlaying;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  MediaItem? get currentlyPlaying => _currentlyPlaying;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

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
    notifyListeners();
  }

  void updateDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void clearPlayback() {
    _currentlyPlaying = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
  }
}
