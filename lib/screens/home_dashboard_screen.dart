import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/playback_manager.dart';
import '../services/media_scanner.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../services/playback_history_service.dart';
import '../services/thumbnail_service.dart';
import '../services/media_controls_service.dart';
import '../services/last_played_service.dart';
import 'video_player_screen.dart';
import '../services/queue_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/mini_player.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeDashboardScreen({super.key, this.onNavigate});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final PlaybackManager _playbackManager = PlaybackManager();
  final FavoritesService _favoritesService = FavoritesService();
  final PlaybackHistoryService _historyService = PlaybackHistoryService();

  int _audioCount = 0;
  int _videoCount = 0;
  int _favoritesCount = 0;
  bool _isLoadingMedia = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _favoritesService.addListener(_onFavoritesChanged);
    _historyService.addListener(_onHistoryChanged);
    _requestPermissionsEarly();
    _loadMediaCounts();
  }

  Future<void> _requestPermissionsEarly() async {
    // Request permissions as soon as the dashboard loads to avoid conflicts
    await MediaScanner.requestPermissions();
  }

  Future<void> _loadMediaCounts() async {
    if (!mounted) return;
    try {
      final audioFolders = await MediaScanner.scanAudioFiles();
      final videoFolders = await MediaScanner.scanVideoFiles();

      // Count total files
      int totalAudioFiles = 0;
      for (var folder in audioFolders) {
        totalAudioFiles += folder.mediaFiles.length;
      }

      int totalVideoFiles = 0;
      for (var folder in videoFolders) {
        totalVideoFiles += folder.mediaFiles.length;
      }

      await _favoritesService.initialize();
      await _historyService.initialize();

      if (_playbackManager.currentlyPlaying == null &&
          _historyService.history.isNotEmpty) {
        _playbackManager.updateCurrentlyPlaying(_historyService.history.first);
      }

      if (mounted) {
        setState(() {
          _audioCount = totalAudioFiles;
          _videoCount = totalVideoFiles;
          _favoritesCount = _favoritesService.favoriteIds.length;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _favoritesService.removeListener(_onFavoritesChanged);
    _historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _favoritesCount = _favoritesService.favoriteIds.length;
      });
    }
  }

  void _onHistoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now Playing section (isolated with RepaintBoundary so playback ticks don't repaint dashboard)
            const SizedBox(height: 12),
            RepaintBoundary(
              child: MiniPlayer(
                audioPlayer: AudioPlayerService().player,
                onTap: () {
                  final current = _playbackManager.currentlyPlaying ??
                      _historyService.history.firstOrNull;
                  if (current != null && current.type == MediaType.video) {
                    VideoPlayerScreen.playExternalVideo(
                      current,
                      autoFullScreen: true,
                      openedFromExternal: true,
                    );
                  } else {
                    widget.onNavigate?.call(1);
                  }
                },
                onPlayVideo: (video) {
                  VideoPlayerScreen.playExternalVideo(
                    video,
                    autoFullScreen: true,
                    openedFromExternal: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Quick access section (isolated with RepaintBoundary for 60/120fps scrolling)
            const SizedBox(height: 12),
            RepaintBoundary(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          icon: Icons.music_note_rounded,
                          title: 'Music',
                          subtitle:
                              '$_audioCount ${_audioCount == 1 ? 'song' : 'songs'}',
                          color: Colors.orange,
                          isLoading: _isLoadingMedia,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAccessCard(
                          icon: Icons.video_library_rounded,
                          title: 'Videos',
                          subtitle:
                              '$_videoCount ${_videoCount == 1 ? 'video' : 'videos'}',
                          color: Colors.blue,
                          isLoading: _isLoadingMedia,
                          onTap: () => widget.onNavigate?.call(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAccessCard(
                          icon: Icons.favorite_rounded,
                          title: 'Favorites',
                          subtitle:
                              '$_favoritesCount ${_favoritesCount == 1 ? 'favorite' : 'favorites'}',
                          color: Colors.red,
                          onTap: () => widget.onNavigate?.call(5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAccessCard(
                          icon: Icons.queue_music_rounded,
                          title: 'Queue',
                          subtitle: 'Now playing',
                          color: Colors.purple,
                          onTap: () => widget.onNavigate?.call(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Play History section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: Colors.orange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent History',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_historyService.history.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      await _historyService.clearHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playback history cleared'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentHistorySection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistorySection() {
    final history = _historyService.history;
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
            ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 26,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No Recent Play History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Songs and videos you play will appear here',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

    // Show up to 10 recent items
    final displayItems = history.take(10).toList();

    return RepaintBoundary(
      child: Column(
        children: displayItems.map((item) => _buildHistoryItem(item)).toList(),
      ),
    );
  }

  Widget _buildHistoryItem(MediaItem item) {
    final isAudio = item.type == MediaType.audio;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: (isAudio ? Colors.orange : Colors.blue).withValues(
                alpha: 0.08,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 1. Color-graded ambient glow matching application UI (orange for songs, blue for videos)
              Positioned.fill(
                child: _buildHistoryMeshGradient(isAudio),
              ),

              // 2. Crystal glass dark frosted tint overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF161616).withValues(alpha: 0.65),
                        const Color(0xFF0A0A0A).withValues(alpha: 0.82),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 3. Crystal glass specular top shine
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),

              // 4. Foreground content ListTile wrapped in Material for ripple / ink splashes
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: _HistoryThumbnail(item: item),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAudio
                              ? Colors.orange.withValues(alpha: 0.22)
                              : Colors.blue.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: (isAudio ? Colors.orange : Colors.blue)
                                .withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAudio
                                  ? Icons.music_note_rounded
                                  : Icons.videocam_rounded,
                              color: isAudio ? Colors.orange : Colors.blue,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isAudio ? 'SONG' : 'VIDEO',
                              style: TextStyle(
                                color: isAudio ? Colors.orange : Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.artist ?? (isAudio ? 'Audio track' : 'Video file'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onTap: () => _playHistoryItem(item),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHistoryMeshGradient(bool isAudio) {
    final accentColor = isAudio ? Colors.orange : Colors.blue;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.85, -0.1),
          radius: 1.5,
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.05),
            const Color(0xFF111111),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }



  Future<void> _playHistoryItem(MediaItem item) async {
    if (item.type == MediaType.audio) {
      // 1. Immediately inform PlaybackManager that active media is now this song
      // This immediately switches MiniPlayer to audio mode and disposes any video controller cleanly.
      PlaybackManager().updateCurrentlyPlaying(item);
      PlaybackManager().updatePlayingState(false);

      // 2. Add to history & save last played
      await _historyService.addToHistory(item);
      await LastPlayedService.saveLastPlayed(item, 0);

      // 3. Update queue so next/previous buttons work
      final queue = QueueService().queue;
      final existingIndex =
          queue.indexWhere((m) => m.id == item.id || m.path == item.path);
      if (existingIndex >= 0) {
        QueueService().setCurrentIndex(existingIndex);
      } else {
        QueueService().setQueue([item], startIndex: 0);
      }

      // 4. Load audio file and start playback
      try {
        await AudioPlayerService().player.stop();
        await AudioPlayerService().player.setFilePath(item.path);
        AudioPlayerService().updateCurrentMediaItem(
          title: item.title,
          artist: item.artist,
          duration: AudioPlayerService().player.duration,
        );
        MediaControlsService.updateMetadata(
          title: item.title,
          artist: item.artist,
          album: item.album,
          thumbnailPath: item.thumbnailPath,
          playing: true,
        );
        await AudioPlayerService().player.play();
        PlaybackManager().updatePlayingState(true);
      } catch (e) {
        debugPrint('Error playing audio from history: $e');
      }
    } else {
      // Pause any ongoing audio playback
      try {
        if (AudioPlayerService().player.playing) {
          await AudioPlayerService().player.pause();
        }
      } catch (_) {}

      // Set video as currently playing & active in MiniPlayer on dashboard
      PlaybackManager().updateCurrentlyPlaying(item);
      PlaybackManager().updatePlayingState(true);
      await _historyService.addToHistory(item);
      await LastPlayedService.saveLastPlayed(item, 0);
    }

    // Smoothly scroll up to the mini player so the user immediately sees playback
    if (_scrollController.hasClients && _scrollController.offset > 40) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    if (mounted) setState(() {});
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 1. Color-graded illuminated ambient glow matching the app UI
              Positioned.fill(
                child: _buildMeshGradient(color),
              ),

              // 2. Crystal glass dark frosted tint overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF161616).withValues(alpha: 0.60),
                        const Color(0xFF0A0A0A).withValues(alpha: 0.78),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 3. Crystal glass specular top shine
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),

              // 4. Foreground content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isLoading)
                      SizedBox(
                        height: 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Scanning...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeshGradient(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.3,
          colors: [
            color.withValues(alpha: 0.45),
            color.withValues(alpha: 0.15),
            const Color(0xFF101010),
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatefulWidget {
  final MediaItem item;

  const _HistoryThumbnail({required this.item});

  @override
  State<_HistoryThumbnail> createState() => _HistoryThumbnailState();
}

class _HistoryThumbnailState extends State<_HistoryThumbnail> {
  Uint8List? _audioThumb;
  String? _videoThumb;

  @override
  void initState() {
    super.initState();
    _checkCacheAndLoad();
  }

  @override
  void didUpdateWidget(_HistoryThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path) {
      _checkCacheAndLoad();
    }
  }

  void _checkCacheAndLoad() {
    final item = widget.item;
    if (item.type == MediaType.audio) {
      if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
        return;
      }
      final cached = ThumbnailService.getCachedAudioThumbnail(item.path);
      if (cached != null) {
        _audioThumb = cached;
        return;
      }
      ThumbnailService.getAudioThumbnail(item.path).then((data) {
        if (mounted && data != null) {
          setState(() => _audioThumb = data);
        }
      });
    } else {
      if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
        return;
      }
      final cached = ThumbnailService.getCachedVideoThumbnail(item.path);
      if (cached != null) {
        _videoThumb = cached;
        return;
      }
      ThumbnailService.getVideoThumbnail(item.path).then((path) {
        if (mounted && path != null) {
          setState(() => _videoThumb = path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.type == MediaType.audio) {
      if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
        return _buildThumbContainer(
          Image.file(
            File(item.thumbnailPath!),
            width: 50,
            height: 50,
            cacheWidth: 100,
            cacheHeight: 100,
            fit: BoxFit.cover,
          ),
        );
      }
      if (_audioThumb != null) {
        return _buildThumbContainer(
          Image.memory(
            _audioThumb!,
            width: 50,
            height: 50,
            cacheWidth: 100,
            cacheHeight: 100,
            fit: BoxFit.cover,
          ),
        );
      }
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.35),
              Colors.orange.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: Colors.orange,
          size: 24,
        ),
      );
    } else {
      if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
        return _buildThumbContainer(
          Image.file(
            File(item.thumbnailPath!),
            width: 50,
            height: 50,
            cacheWidth: 100,
            cacheHeight: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultVideoThumb(),
          ),
        );
      }
      if (_videoThumb != null && File(_videoThumb!).existsSync()) {
        return _buildThumbContainer(
          Image.file(
            File(_videoThumb!),
            width: 50,
            height: 50,
            cacheWidth: 100,
            cacheHeight: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultVideoThumb(),
          ),
        );
      }
      return _defaultVideoThumb();
    }
  }

  Widget _buildThumbContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  Widget _defaultVideoThumb() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.35),
            Colors.blue.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.blue, size: 24),
    );
  }
}
