import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import 'dart:convert';

class LastPlayedService {
  static const _lastPlayedKey = 'last_played_media_item';
  static const _lastPlayedIndexKey = 'last_played_index';
  static const _lastPlayedPlaylistKey = 'last_played_playlist';

  static Future<void> saveLastPlayed(
    MediaItem item,
    int index, [
    List<MediaItem>? playlist,
  ]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Properly encode JSON
      final jsonString = json.encode(item.toJson());
      await prefs.setString(_lastPlayedKey, jsonString);
      await prefs.setInt(_lastPlayedIndexKey, index);

      // Save playlist if provided (limit to 50 songs to avoid storage issues)
      if (playlist != null && playlist.isNotEmpty) {
        final limitedPlaylist = playlist.length > 50
            ? playlist.sublist(0, 50)
            : playlist;
        final playlistJson = json.encode(
          limitedPlaylist.map((e) => e.toJson()).toList(),
        );
        await prefs.setString(_lastPlayedPlaylistKey, playlistJson);
      }
    } catch (e) {
      // Error saving last played song
    }
  }

  static Future<Map<String, dynamic>?> loadLastPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemString = prefs.getString(_lastPlayedKey);
      final index = prefs.getInt(_lastPlayedIndexKey);
      final playlistString = prefs.getString(_lastPlayedPlaylistKey);

      if (itemString != null && index != null) {
        final itemJson = json.decode(itemString) as Map<String, dynamic>;

        // Load playlist if available
        List<Map<String, dynamic>>? playlist;
        if (playlistString != null) {
          final playlistData = json.decode(playlistString) as List<dynamic>;
          playlist = playlistData
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }

        return {'item': itemJson, 'index': index, 'playlist': playlist};
      }
    } catch (e) {
      // Error loading last played song
    }
    return null;
  }
}
