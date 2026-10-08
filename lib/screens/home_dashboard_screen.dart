import 'dart:io';
import 'dart:ui';
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
  MediaItem? _sampleAudioItem;
  MediaItem? _sampleVideoItem;

  @override
  void initState() {
    super.initState();
    _playbackManager.addListener(_onPlaybackChanged);
    _favoritesService.addListener(_onFavoritesChanged);
    _historyService.addListener(_onHistoryChanged);
    _requestPermissionsEarly();
    // Delay loading counts to improve initial load speed
    Future.delayed(const Duration(milliseconds: 300), _loadMediaCounts);
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

      // Count total files and grab sample items for glass backgrounds
      int totalAudioFiles = 0;
      MediaItem? sampleAudio;
      for (var folder in audioFolders) {
        totalAudioFiles += folder.mediaFiles.length;
        if (sampleAudio == null && folder.mediaFiles.isNotEmpty) {
          sampleAudio = folder.mediaFiles.first;
        }
      }

      int totalVideoFiles = 0;
      MediaItem? sampleVideo;
      for (var folder in videoFolders) {
        totalVideoFiles += folder.mediaFiles.length;
        if (sampleVideo == null && folder.mediaFiles.isNotEmpty) {
          sampleVideo = folder.mediaFiles.first;
        }
      }

      await _favoritesService.initialize();
      await _historyService.initialize();

      if (mounted) {
        setState(() {
          _audioCount = totalAudioFiles;
          _videoCount = totalVideoFiles;
          _sampleAudioItem = sampleAudio;
          _sampleVideoItem = sampleVideo;
          _favoritesCount = _favoritesService.favoriteIds.length;
        });
      }
    } catch (e) {
      // Error loading media counts
    }
  }

  @override
  void dispose() {
    _playbackManager.removeListener(_onPlaybackChanged);
    _favoritesService.removeListener(_onFavoritesChanged);
    _historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (mounted) setState(() {});
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now Playing section
            Text(
              'Now Playing',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            MiniPlayer(
              audioPlayer: AudioPlayerService().player,
              onTap: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(height: 24),

            // Quick access section
            Text(
              'Quick Access',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.music_note_rounded,
                    title: 'Music',
                    subtitle:
                        '$_audioCount ${_audioCount == 1 ? 'song' : 'songs'}',
                    color: Colors.orange,
                    backgroundMedia: _historyService.history
                            .where((m) => m.type == MediaType.audio)
                            .firstOrNull ??
                        _sampleAudioItem,
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
                    backgroundMedia: _historyService.history
                            .where((m) => m.type == MediaType.video)
                            .firstOrNull ??
                        _sampleVideoItem,
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
                    backgroundMedia:
                        _favoritesService.favoriteItems.firstOrNull,
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
                    backgroundMedia: _playbackManager.currentlyPlaying ??
                        QueueService().queue.firstOrNull,
                    onTap: () => widget.onNavigate?.call(6),
                  ),
                ),
              ],
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
        ),
      );
    }

    // Show up to 10 recent items
    final displayItems = history.take(10).toList();

    return Column(
      children: displayItems.map((item) => _buildHistoryItem(item)).toList(),
    );
  }

  Widget _buildHistoryItem(MediaItem item) {
    final isAudio = item.type == MediaType.audio;

    return Container(
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
            color:
                (isAudio ? Colors.orange : Colors.blue).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 1. Current song/video background artwork
            Positioned.fill(
              child: _buildHistoryBackground(item),
            ),

            // 2. Crystal glass blur & dark frosted tint overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF141414).withValues(alpha: 0.68),
                        const Color(0xFF0A0A0A).withValues(alpha: 0.84),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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

            // 4. Foreground content ListTile
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              leading: _buildHistoryThumbnail(item),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBackground(MediaItem item) {
    if (item.type == MediaType.audio) {
      if (item.thumbnailPath != null &&
          File(item.thumbnailPath!).existsSync()) {
        return Image.file(
          File(item.thumbnailPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      return FutureBuilder<Uint8List?>(
        future: ThumbnailService.getAudioThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          }
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A1B0E), Color(0xFF141414)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        },
      );
    } else {
      return FutureBuilder<String?>(
        future: ThumbnailService.getVideoThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _defaultVideoBg(),
            );
          }
          return _defaultVideoBg();
        },
      );
    }
  }

  Widget _defaultVideoBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E1E2A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildHistoryThumbnail(MediaItem item) {
    if (item.type == MediaType.audio) {
      return FutureBuilder<Uint8List?>(
        future: ThumbnailService.getAudioThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
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
                child: Image.memory(
                  snapshot.data!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
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
        },
      );
    } else {
      return FutureBuilder<String?>(
        future: ThumbnailService.getVideoThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
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
                child: Image.file(
                  File(snapshot.data!),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultVideoThumb(),
                ),
              ),
            );
          }
          return _defaultVideoThumb();
        },
      );
    }
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
      child: const Icon(
        Icons.videocam_rounded,
        color: Colors.blue,
        size: 24,
      ),
    );
  }

  Future<void> _playHistoryItem(MediaItem item) async {
    if (item.type == MediaType.audio) {
      try {
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
        PlaybackManager().updateCurrentlyPlaying(item);
        await _historyService.addToHistory(item);
        await LastPlayedService.saveLastPlayed(item, 0);
      } catch (e) {
        // Fallback or navigate
      }
      widget.onNavigate?.call(1);
    } else {
      VideoPlayerScreen.playExternalVideo(item);
      widget.onNavigate?.call(2);
    }
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    MediaItem? backgroundMedia,
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
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // 1. Background: Real media artwork or illuminated Apple glowing mesh gradient
              Positioned.fill(
                child: _buildQuickAccessBackground(backgroundMedia, color),
              ),

              // 2. Crystal glass blur & dark frosted tint overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF141414).withValues(alpha: 0.65),
                          const Color(0xFF0A0A0A).withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildQuickAccessBackground(MediaItem? media, Color color) {
    if (media != null) {
      if (media.type == MediaType.audio) {
        if (media.thumbnailPath != null &&
            File(media.thumbnailPath!).existsSync()) {
          return Image.file(
            File(media.thumbnailPath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
        return FutureBuilder<Uint8List?>(
          future: ThumbnailService.getAudioThumbnail(media.path),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return _buildMeshGradient(color);
          },
        );
      } else {
        return FutureBuilder<String?>(
          future: ThumbnailService.getVideoThumbnail(media.path),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildMeshGradient(color),
              );
            }
            return _buildMeshGradient(color);
          },
        );
      }
    }
    return _buildMeshGradient(color);
  }

  Widget _buildMeshGradient(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.2,
          colors: [
            color.withValues(alpha: 0.50),
            color.withValues(alpha: 0.18),
            const Color(0xFF101010),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
