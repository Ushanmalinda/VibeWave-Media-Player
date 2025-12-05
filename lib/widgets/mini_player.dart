import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/playback_manager.dart';
import '../services/thumbnail_service.dart';
import '../services/favorites_service.dart';
import '../services/queue_service.dart';
import '../models/media_item.dart';
import 'package:just_audio/just_audio.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;
  final AudioPlayer audioPlayer;

  const MiniPlayer({super.key, required this.onTap, required this.audioPlayer});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final PlaybackManager _playbackManager = PlaybackManager();
  final FavoritesService _favoritesService = FavoritesService();
  final QueueService _queueService = QueueService();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _playbackManager.addListener(_onPlaybackChanged);
    _favoritesService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _playbackManager.removeListener(_onPlaybackChanged);
    _favoritesService.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    if (_playbackManager.isPlaying) {
      await widget.audioPlayer.pause();
    } else {
      await widget.audioPlayer.play();
    }
  }

  Future<void> _skipNext() async {
    final queue = _queueService.queue;
    final currentIndex = _queueService.currentIndex;

    if (currentIndex < queue.length - 1) {
      final nextItem = queue[currentIndex + 1];
      try {
        await widget.audioPlayer.setFilePath(nextItem.path);
        await widget.audioPlayer.play();
        _queueService.setCurrentIndex(currentIndex + 1);
        _playbackManager.updateCurrentlyPlaying(nextItem);
      } catch (e) {
        // Error playing next track
      }
    }
  }

  Future<void> _skipPrevious() async {
    final queue = _queueService.queue;
    final currentIndex = _queueService.currentIndex;

    if (currentIndex > 0) {
      final previousItem = queue[currentIndex - 1];
      try {
        await widget.audioPlayer.setFilePath(previousItem.path);
        await widget.audioPlayer.play();
        _queueService.setCurrentIndex(currentIndex - 1);
        _playbackManager.updateCurrentlyPlaying(previousItem);
      } catch (e) {
        // Error playing previous track
      }
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await widget.audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  Future<void> _toggleFavorite(MediaItem item) async {
    await _favoritesService.toggleFavorite(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favoritesService.isFavorite(item.id)
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showQueueDialog() {
    final queue = _queueService.queue;
    final currentIndex = _queueService.currentIndex;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.queue_music_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Queue (${queue.length} songs)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final item = queue[index];
                  final isCurrent = index == currentIndex;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Colors.orange
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.play_arrow_rounded
                            : Icons.music_note_rounded,
                        color: isCurrent ? Colors.white : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isCurrent ? Colors.orange : Colors.white,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.artist ?? 'Unknown Artist',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _playbackManager.currentlyPlaying;

    if (currentItem == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No music playing',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to browse your library',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.library_music_rounded,
                color: Colors.orange,
              ),
              iconSize: 28,
              onPressed: widget.onTap,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF2a2a2a), const Color(0xFF1f1f1f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main player content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Animated Thumbnail with pulse effect
                  StreamBuilder<PlayerState>(
                    stream: widget.audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isPlaying)
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          _buildThumbnail(currentItem),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentItem.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.album_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                currentItem.artist ?? 'Unknown Artist',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mute button
                      IconButton(
                        icon: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        iconSize: 22,
                        onPressed: _toggleMute,
                      ),
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          _favoritesService.isFavorite(currentItem.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favoritesService.isFavorite(currentItem.id)
                              ? Colors.red
                              : Colors.white.withOpacity(0.7),
                        ),
                        iconSize: 22,
                        onPressed: () => _toggleFavorite(currentItem),
                      ),
                      // Queue button
                      IconButton(
                        icon: Icon(
                          Icons.queue_music_rounded,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        iconSize: 22,
                        onPressed: _showQueueDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Progress bar with time
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: StreamBuilder<Duration>(
                stream: widget.audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = widget.audioPlayer.duration ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.withOpacity(0.9),
                          ),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Control buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.skip_previous_rounded,
                    onPressed: _skipPrevious,
                    size: 32,
                  ),
                  StreamBuilder<PlayerState>(
                    stream: widget.audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing ?? false;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 32,
                          onPressed: _togglePlayPause,
                        ),
                      );
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.skip_next_rounded,
                    onPressed: _skipNext,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      iconSize: size,
      onPressed: onPressed,
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.type == MediaType.audio) {
      return FutureBuilder<Uint8List?>(
        future: ThumbnailService.getAudioThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  snapshot.data!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.4),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.4), Colors.blue.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
