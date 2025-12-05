import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/bookmarks_service.dart';
import '../services/thumbnail_service.dart';
import '../models/media_item.dart';

class BookmarksScreen extends StatefulWidget {
  final String searchQuery;

  const BookmarksScreen({super.key, this.searchQuery = ''});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    BookmarksService().initialize();
    BookmarksService().addListener(_onBookmarksChanged);
  }

  @override
  void dispose() {
    BookmarksService().removeListener(_onBookmarksChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    setState(() {});
  }

  void _showRemoveDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Remove Bookmark?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${item.title}" from bookmarks?',
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
              await BookmarksService().removeBookmark(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.title}" from bookmarks'),
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
    final bookmarks = BookmarksService().bookmarks;
    final audioBookmarks = _getFilteredItems(
      bookmarks.where((item) => item.type == MediaType.audio).toList(),
    );
    final videoBookmarks = _getFilteredItems(
      bookmarks.where((item) => item.type == MediaType.video).toList(),
    );

    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_rounded,
              size: 100,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Bookmarks Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bookmark your favorite tracks\nfor quick access',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (audioBookmarks.isEmpty &&
        videoBookmarks.isEmpty &&
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
        if (audioBookmarks.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Music (${audioBookmarks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...audioBookmarks.map((item) => _buildBookmarkItem(item)),
          const SizedBox(height: 24),
        ],
        // Video Section
        if (videoBookmarks.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              Text(
                'Videos (${videoBookmarks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...videoBookmarks.map((item) => _buildBookmarkItem(item)),
        ],
      ],
    );
  }

  Widget _buildBookmarkItem(MediaItem item) {
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
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
          icon: const Icon(Icons.bookmark, color: Colors.orange, size: 28),
          onPressed: () async {
            await BookmarksService().removeBookmark(item.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed from bookmarks'),
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
