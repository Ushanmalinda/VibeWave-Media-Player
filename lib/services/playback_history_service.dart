import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import 'last_played_service.dart';

class PlaybackHistoryService extends ChangeNotifier {
  static final PlaybackHistoryService _instance =
      PlaybackHistoryService._internal();
  factory PlaybackHistoryService() => _instance;
  PlaybackHistoryService._internal();

  static const String _storageKey = 'playback_history';
  final List<MediaItem> _history = [];
  bool _isInitialized = false;

  List<MediaItem> get history => List.unmodifiable(_history);

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_storageKey) ?? [];
      _history.clear();
      for (final itemStr in historyJson) {
        try {
          final map = json.decode(itemStr) as Map<String, dynamic>;
          _history.add(MediaItem.fromJson(map));
        } catch (_) {}
      }

      // If history is still empty, seed it with last played item if available
      if (_history.isEmpty) {
        final last = await LastPlayedService.loadLastPlayed();
        if (last != null && last['item'] != null) {
          try {
            final item = MediaItem.fromJson(
              Map<String, dynamic>.from(last['item']),
            );
            _history.add(item);
            await _save();
          } catch (_) {}
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addToHistory(MediaItem item) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      // Remove any existing instance with same id or path
      _history.removeWhere((i) => i.id == item.id || i.path == item.path);
      // Insert at the front
      _history.insert(0, item);
      // Limit to 30 items
      if (_history.length > 30) {
        _history.removeRange(30, _history.length);
      }
      await _save();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> removeFromHistory(String id) async {
    try {
      _history.removeWhere((i) => i.id == id);
      await _save();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _save();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _history.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (_) {}
  }
}
