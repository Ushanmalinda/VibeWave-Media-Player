import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/media_item.dart';

class PlaylistService extends ChangeNotifier {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  List<Playlist> _playlists = [];
  bool _isInitialized = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadPlaylists();
    _isInitialized = true;
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists') ?? '[]';
      final List<dynamic> decoded = json.decode(playlistsJson);
      _playlists = decoded
          .map((item) => Playlist.fromJson(item as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      // Error loading playlists
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = json.encode(
        _playlists.map((playlist) => playlist.toJson()).toList(),
      );
      await prefs.setString('playlists', playlistsJson);
    } catch (e) {
      // Error saving playlists
    }
  }

  Future<void> createPlaylist(String name) async {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      mediaIds: [],
    );
    _playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(name: newName);
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> addToPlaylist(String playlistId, String mediaId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      if (!_playlists[index].mediaIds.contains(mediaId)) {
        final updatedMediaIds = [..._playlists[index].mediaIds, mediaId];
        _playlists[index] = _playlists[index].copyWith(
          mediaIds: updatedMediaIds,
        );
        await _savePlaylists();
        notifyListeners();
      }
    }
  }

  Future<void> removeFromPlaylist(String playlistId, String mediaId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final updatedMediaIds = _playlists[index].mediaIds
          .where((id) => id != mediaId)
          .toList();
      _playlists[index] = _playlists[index].copyWith(mediaIds: updatedMediaIds);
      await _savePlaylists();
      notifyListeners();
    }
  }

  bool isInPlaylist(String playlistId, String mediaId) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () =>
          Playlist(id: '', name: '', createdAt: DateTime.now(), mediaIds: []),
    );
    return playlist.mediaIds.contains(mediaId);
  }

  Playlist? getPlaylistById(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  List<MediaItem> getPlaylistItems(
    String playlistId,
    List<MediaItem> allMedia,
  ) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];

    return allMedia
        .where((media) => playlist.mediaIds.contains(media.id))
        .toList();
  }
}
