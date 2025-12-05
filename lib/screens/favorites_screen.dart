import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/media_item.dart';
import 'dart:typed_data';
import '../services/thumbnail_service.dart';

class FavoritesScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final String searchQuery;

  const FavoritesScreen({super.key, this.onNavigate, this.searchQuery = ''});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    setState(() {});
  }

  void _showRemoveDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Remove from Favorites?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${item.title}" from favorites?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _favoritesService.removeFavorite(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.title}" from favorites'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<MediaItem> _getFilteredItems(List<MediaItem> items) {
    if (widget.searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      final titleLower = item.title.toLowerCase();
      final artistLower = (item.artist ?? '').toLowerCase();
      final queryLower = widget.searchQuery.toLowerCase();
      return titleLower.contains(queryLower) ||
          artistLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoritesService.favoriteItems;
    final audioFavorites = _getFilteredItems(
      favorites.where((item) => item.type == MediaType.audio).toList(),
    );
    final videoFavorites = _getFilteredItems(
      favorites.where((item) => item.type == MediaType.video).toList(),
    );

    if (favorites.isEmpty) {
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 100,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Heart your favorite songs and videos\nto see them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onNavigate?.call(1);
                  },
                  icon: const Icon(Icons.music_note_rounded),
                  label: const Text('Browse Music'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (audioFavorites.isEmpty &&
        videoFavorites.isEmpty &&
        widget.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Audio Section
        if (audioFavorites.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Music (${audioFavorites.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...audioFavorites.map((item) => _buildFavoriteItem(item)),
          const SizedBox(height: 24),
        ],
        // Video Section
        if (videoFavorites.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Text(
                'Videos (${videoFavorites.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...videoFavorites.map((item) => _buildFavoriteItem(item)),
        ],
      ],
    );
  }

  Widget _buildFavoriteItem(MediaItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2a2a2a),
      child: ListTile(
        onLongPress: () => _showRemoveDialog(item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: _buildThumbnail(item),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.artist ?? 'Unknown Artist',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
          onPressed: () async {
            await _favoritesService.removeFavorite(item.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed from favorites'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.type == MediaType.audio) {
      return FutureBuilder<Uint8List?>(
        future: ThumbnailService.getAudioThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                snapshot.data!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            );
          }
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.orange,
              size: 28,
            ),
          );
        },
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
    );
  }
}
