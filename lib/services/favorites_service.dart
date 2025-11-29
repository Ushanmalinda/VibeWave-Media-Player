import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<String> _favoriteIds = {};
  final Map<String, MediaItem> _favoriteItems = {};
  final Set<String> _favoriteFolderPaths = {};
  bool _isInitialized = false;

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<MediaItem> get favoriteItems => _favoriteItems.values.toList();
  Set<String> get favoriteFolderPaths => Set.unmodifiable(_favoriteFolderPaths);

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      _favoriteIds.addAll(favorites);

      final folders = prefs.getStringList('favorite_folders') ?? [];
      _favoriteFolderPaths.addAll(folders);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  bool isFavorite(String mediaId) {
    return _favoriteIds.contains(mediaId);
  }

  Future<void> toggleFavorite(MediaItem item) async {
    if (_favoriteIds.contains(item.id)) {
      _favoriteIds.remove(item.id);
      _favoriteItems.remove(item.id);
    } else {
      _favoriteIds.add(item.id);
      _favoriteItems[item.id] = item;
    }

    await _saveFavorites();
    notifyListeners();
  }

  Future<void> addFavorite(MediaItem item) async {
    if (!_favoriteIds.contains(item.id)) {
      _favoriteIds.add(item.id);
      _favoriteItems[item.id] = item;
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String mediaId) async {
    if (_favoriteIds.remove(mediaId)) {
      _favoriteItems.remove(mediaId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favoriteIds.toList());
      await prefs.setStringList(
        'favorite_folders',
        _favoriteFolderPaths.toList(),
      );
    } catch (e) {
      // Silently handle save errors
    }
  }

  Future<void> clearAll() async {
    _favoriteIds.clear();
    _favoriteItems.clear();
    _favoriteFolderPaths.clear();
    await _saveFavorites();
    notifyListeners();
  }

  bool isFolderFavorite(String folderPath) {
    return _favoriteFolderPaths.contains(folderPath);
  }

  Future<void> toggleFolderFavorite(
    String folderPath,
    List<MediaItem> items,
  ) async {
    if (_favoriteFolderPaths.contains(folderPath)) {
      _favoriteFolderPaths.remove(folderPath);
      // Remove all items from this folder
      for (var item in items) {
        _favoriteIds.remove(item.id);
        _favoriteItems.remove(item.id);
      }
    } else {
      _favoriteFolderPaths.add(folderPath);
      // Add all items from this folder
      for (var item in items) {
        _favoriteIds.add(item.id);
        _favoriteItems[item.id] = item;
      }
    }
    await _saveFavorites();
    notifyListeners();
  }
}
