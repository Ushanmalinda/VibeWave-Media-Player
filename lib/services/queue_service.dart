import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

class QueueService extends ChangeNotifier {
  static final QueueService _instance = QueueService._internal();
  factory QueueService() => _instance;
  QueueService._internal();

  final List<MediaItem> _queue = [];
  int _currentIndex = -1;

  List<MediaItem> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  MediaItem? get currentItem =>
      _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;
  bool get hasQueue => _queue.isNotEmpty;
  int get queueLength => _queue.length;

  void setQueue(List<MediaItem> items, {int startIndex = 0}) {
    _queue.clear();
    _queue.addAll(items);
    _currentIndex = startIndex;
    notifyListeners();
  }

  void addToQueue(MediaItem item) {
    _queue.add(item);
    notifyListeners();
  }

  void addNext(MediaItem item) {
    // Add after current playing song
    final insertIndex = _currentIndex + 1;
    if (insertIndex <= _queue.length) {
      _queue.insert(insertIndex, item);
      notifyListeners();
    }
  }

  void addAllToQueue(List<MediaItem> items) {
    _queue.addAll(items);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex >= index) {
        _currentIndex = (_currentIndex - 1).clamp(-1, _queue.length - 1);
      }
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex >= 0 &&
        oldIndex < _queue.length &&
        newIndex >= 0 &&
        newIndex < _queue.length) {
      final item = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, item);

      if (_currentIndex == oldIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void playNext() {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
}
