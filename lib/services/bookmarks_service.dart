import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/media_item.dart';

class BookmarksService extends ChangeNotifier {
  static final BookmarksService _instance = BookmarksService._internal();
  factory BookmarksService() => _instance;
  BookmarksService._internal();

  List<MediaItem> _bookmarks = [];
  bool _isInitialized = false;

  List<MediaItem> get bookmarks => List.unmodifiable(_bookmarks);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadBookmarks();
    _isInitialized = true;
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString('bookmarks') ?? '[]';
      final List<dynamic> decoded = json.decode(bookmarksJson);
      _bookmarks = decoded
          .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = json.encode(
        _bookmarks.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('bookmarks', bookmarksJson);
    } catch (e) {
      print('Error saving bookmarks: $e');
    }
  }

  bool isBookmarked(String id) {
    return _bookmarks.any((item) => item.id == id);
  }

  Future<void> addBookmark(MediaItem item) async {
    if (!isBookmarked(item.id)) {
      _bookmarks.add(item);
      await _saveBookmarks();
      notifyListeners();
    }
  }

  Future<void> removeBookmark(String id) async {
    _bookmarks.removeWhere((item) => item.id == id);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> toggleBookmark(MediaItem item) async {
    if (isBookmarked(item.id)) {
      await removeBookmark(item.id);
    } else {
      await addBookmark(item);
    }
  }

  Future<void> clearAll() async {
    _bookmarks.clear();
    await _saveBookmarks();
    notifyListeners();
  }
}
