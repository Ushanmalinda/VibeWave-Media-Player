import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/playlist_service.dart';
import '../services/media_scanner.dart';
import '../services/thumbnail_service.dart';
import '../services/queue_service.dart';
import '../models/playlist.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';

class PlaylistsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final String searchQuery;

  const PlaylistsScreen({super.key, this.onNavigate, this.searchQuery = ''});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<MediaItem> _allMedia = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _playlistService.addListener(_onPlaylistsChanged);
  }

  @override
  void dispose() {
    _playlistService.removeListener(_onPlaylistsChanged);
    super.dispose();
  }

  void _onPlaylistsChanged() {
    setState(() {});
  }

  Future<void> _initialize() async {
    await _playlistService.initialize();
    await _loadAllMedia();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAllMedia() async {
    final audioFolders = await MediaScanner.scanAudioFiles();
    final videoFolders = await MediaScanner.scanVideoFiles();

    final List<MediaItem> allItems = [];

    // Extract media items from audio folders
    for (var folder in audioFolders) {
      allItems.addAll(folder.mediaFiles);
    }

    // Extract media items from video folders
    for (var folder in videoFolders) {
      allItems.addAll(folder.mediaFiles);
    }

    setState(() {
      _allMedia = allItems;
    });
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
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
              if (controller.text.trim().isNotEmpty) {
                await _playlistService.createPlaylist(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Playlist "${controller.text.trim()}" created',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Delete Playlist?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "${playlist.name}"? This action cannot be undone.',
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
              await _playlistService.deletePlaylist(playlist.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${playlist.name}" deleted'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(Playlist? playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(
          playlist: playlist,
          allMedia: _allMedia,
          onNavigate: widget.onNavigate,
        ),
      ),
    );
  }

  List<Playlist> _getFilteredPlaylists(List<Playlist> playlists) {
    if (widget.searchQuery.isEmpty) {
      return playlists;
    }
    return playlists.where((p) {
      final nameLower = p.name.toLowerCase();
      final queryLower = widget.searchQuery.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    final playlists = _playlistService.playlists;
    final filteredPlaylists = _getFilteredPlaylists(playlists);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Default Playlist
        Card(
          key: const ValueKey('playlist_all_media'),
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF2a2a2a),
          child: ListTile(
            onTap: () => _openPlaylist(null),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.8),
                    Colors.orange.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.library_music_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            title: const Text(
              'Default Playlist',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${_allMedia.length} items',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.orange,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        // Create Playlist Button
        ElevatedButton.icon(
          onPressed: _showCreatePlaylistDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Playlist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 16),

        // User Playlists
        if (filteredPlaylists.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.playlist_add_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredPlaylists.map((playlist) {
            final items = _playlistService.getPlaylistItems(
              playlist.id,
              _allMedia,
            );
            return Card(
              key: ValueKey('playlist_${playlist.id}'),
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF2a2a2a),
              child: ListTile(
                onTap: () => _openPlaylist(playlist),
                onLongPress: () => _showDeletePlaylistDialog(playlist),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.playlist_play_rounded,
                    color: Colors.purple,
                    size: 32,
                  ),
                ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${items.length} items',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeletePlaylistDialog(playlist),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.purple,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// Playlist Detail Screen
class PlaylistDetailScreen extends StatefulWidget {
  final Playlist? playlist; // null for "Default Playlist"
  final List<MediaItem> allMedia;
  final Function(int)? onNavigate;

  const PlaylistDetailScreen({
    super.key,
    this.playlist,
    required this.allMedia,
    this.onNavigate,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final QueueService _queueService = QueueService();

  @override
  void initState() {
    super.initState();
    _playlistService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _playlistService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    setState(() {});
  }

  Future<void> _playMedia(MediaItem item, List<MediaItem> allItems) async {
    if (item.type == MediaType.audio) {
      // Play audio - set queue and navigate to audio player
      final audioItems =
          allItems.where((i) => i.type == MediaType.audio).toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      final index = audioItems.indexWhere((i) => i.id == item.id);

      // Set queue
      _queueService.setQueue(audioItems, startIndex: index >= 0 ? index : 0);

      // Navigate to audio player screen
      if (context.mounted) {
        // Close playlist detail screen
        Navigator.pop(context);

        // Navigate to audio player (index 1) using callback
        if (widget.onNavigate != null) {
          widget.onNavigate!(1);
        }

        final playlistName = widget.playlist?.name ?? 'Default Playlist';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing from "$playlistName"'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (item.type == MediaType.video) {
      // For videos, just show a message for now
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video playback from playlist - Coming soon'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<MediaItem> _getPlaylistItems() {
    if (widget.playlist == null) {
      // Default Playlist - show everything sorted
      final items = List<MediaItem>.from(widget.allMedia);
      items.sort((a, b) => a.title.compareTo(b.title));
      return items;
    }
    return _playlistService.getPlaylistItems(
      widget.playlist!.id,
      widget.allMedia,
    );
  }

  void _showAddMediaDialog() {
    if (widget.playlist == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AddMediaFolderView(
          playlist: widget.playlist!,
          allMedia: widget.allMedia,
          playlistService: _playlistService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _getPlaylistItems();
    final audioItems = items
        .where((item) => item.type == MediaType.audio)
        .toList();
    final videoItems = items
        .where((item) => item.type == MediaType.video)
        .toList();

    // Sort alphabetically
    audioItems.sort((a, b) => a.title.compareTo(b.title));
    videoItems.sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist?.name ?? 'Default Playlist'),
        backgroundColor: const Color(0xFF2a2a2a),
        actions: [
          if (widget.playlist != null)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _showAddMediaDialog,
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.playlist == null
                        ? 'No media files found'
                        : 'Playlist is empty',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                    ),
                  ),
                  if (widget.playlist != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddMediaDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Audio Section
                if (audioItems.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Music (${audioItems.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...audioItems.map((item) => _buildMediaItem(item)),
                  const SizedBox(height: 24),
                ],
                // Video Section
                if (videoItems.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Videos (${videoItems.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...videoItems.map((item) => _buildMediaItem(item)),
                ],
              ],
            ),
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    return Card(
      key: ValueKey('media_${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2a2a2a),
      child: ListTile(
        onTap: () => _playMedia(item, _getPlaylistItems()),
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
        trailing: widget.playlist != null
            ? IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await _playlistService.removeFromPlaylist(
                    widget.playlist!.id,
                    item.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${item.title}" from playlist'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              )
            : null,
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

// Add Media to Playlist Screen with Folder Structure
class _AddMediaFolderView extends StatefulWidget {
  final Playlist playlist;
  final List<MediaItem> allMedia;
  final PlaylistService playlistService;

  const _AddMediaFolderView({
    required this.playlist,
    required this.allMedia,
    required this.playlistService,
  });

  @override
  State<_AddMediaFolderView> createState() => _AddMediaFolderViewState();
}

class _AddMediaFolderViewState extends State<_AddMediaFolderView> {
  List<FolderItem> _audioFolders = [];
  List<FolderItem> _videoFolders = [];
  bool _isLoading = true;
  bool _showAudio = true;
  String? _selectedFolderPath;
  final Set<String> _selectedMediaIds = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final audioFolders = await MediaScanner.scanAudioFiles();
      final videoFolders = await MediaScanner.scanVideoFiles();

      setState(() {
        _audioFolders = audioFolders;
        _videoFolders = videoFolders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<FolderItem> get _currentFolders =>
      _showAudio ? _audioFolders : _videoFolders;

  List<MediaItem> get _playlistItems => widget.playlistService.getPlaylistItems(
    widget.playlist.id,
    widget.allMedia,
  );

  bool _isInPlaylist(String mediaId) {
    return _playlistItems.any((item) => item.id == mediaId);
  }

  Future<void> _addSelectedToPlaylist() async {
    if (_selectedMediaIds.isEmpty) return;

    for (final mediaId in _selectedMediaIds) {
      await widget.playlistService.addToPlaylist(widget.playlist.id, mediaId);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_selectedMediaIds.length} items to playlist'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addFolderToPlaylist(FolderItem folder) async {
    int addedCount = 0;
    for (final media in folder.mediaFiles) {
      if (!_isInPlaylist(media.id)) {
        await widget.playlistService.addToPlaylist(
          widget.playlist.id,
          media.id,
        );
        addedCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $addedCount items from "${folder.name}"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _selectedFolderPath = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2a2a2a),
        title: Text(
          _selectedFolderPath == null ? 'Add to Playlist' : 'Select Songs',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_selectedFolderPath != null) {
              setState(() {
                _selectedFolderPath = null;
                _selectedMediaIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_selectedFolderPath != null && _selectedMediaIds.isNotEmpty)
            TextButton(
              onPressed: _addSelectedToPlaylist,
              child: Text(
                'ADD (${_selectedMediaIds.length})',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                if (_selectedFolderPath == null) ...[
                  // Audio/Video toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _showAudio = true),
                            icon: const Icon(Icons.music_note),
                            label: Text('Audio (${_audioFolders.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _showAudio
                                  ? Colors.orange
                                  : const Color(0xFF2a2a2a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _showAudio = false),
                            icon: const Icon(Icons.videocam),
                            label: Text('Video (${_videoFolders.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_showAudio
                                  ? Colors.blue
                                  : const Color(0xFF2a2a2a),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: _selectedFolderPath == null
                      ? _buildFolderList()
                      : _buildMediaList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFolderList() {
    if (_currentFolders.isEmpty) {
      return Center(
        child: Text(
          'No ${_showAudio ? "audio" : "video"} folders found',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _currentFolders.length,
      itemBuilder: (context, index) {
        final folder = _currentFolders[index];
        final availableCount = folder.mediaFiles
            .where((m) => !_isInPlaylist(m.id))
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF2a2a2a),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (_showAudio ? Colors.orange : Colors.blue).withOpacity(
                  0.2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: _showAudio ? Colors.orange : Colors.blue,
                size: 28,
              ),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${folder.fileCount} items${availableCount < folder.fileCount ? " ($availableCount available)" : ""}',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (availableCount > 0)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.orange),
                    tooltip: 'Add all',
                    onPressed: () => _addFolderToPlaylist(folder),
                  ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            onTap: () {
              setState(() => _selectedFolderPath = folder.path);
            },
          ),
        );
      },
    );
  }

  Widget _buildMediaList() {
    final folder = _currentFolders.firstWhere(
      (f) => f.path == _selectedFolderPath,
      orElse: () => _currentFolders.first,
    );
    final availableMedia = folder.mediaFiles
        .where((m) => !_isInPlaylist(m.id))
        .toList();

    if (availableMedia.isEmpty) {
      return Center(
        child: Text(
          'All items from this folder are already in the playlist',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: availableMedia.length,
      itemBuilder: (context, index) {
        final media = availableMedia[index];
        final isSelected = _selectedMediaIds.contains(media.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? Colors.orange.withOpacity(0.2)
              : const Color(0xFF2a2a2a),
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              activeColor: Colors.orange,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedMediaIds.add(media.id);
                  } else {
                    _selectedMediaIds.remove(media.id);
                  }
                });
              },
            ),
            title: Text(
              media.title,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              media.artist ?? 'Unknown Artist',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              media.type == MediaType.audio ? Icons.music_note : Icons.videocam,
              color: media.type == MediaType.audio
                  ? Colors.orange
                  : Colors.blue,
            ),
            onTap: () {
              setState(() {
                if (_selectedMediaIds.contains(media.id)) {
                  _selectedMediaIds.remove(media.id);
                } else {
                  _selectedMediaIds.add(media.id);
                }
              });
            },
          ),
        );
      },
    );
  }
}
