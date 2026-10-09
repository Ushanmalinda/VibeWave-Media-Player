import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../services/playback_manager.dart';
import '../services/thumbnail_service.dart';
import '../services/favorites_service.dart';
import '../services/queue_service.dart';
import '../services/playback_history_service.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;
  final AudioPlayer audioPlayer;
  final Function(MediaItem)? onPlayVideo;

  const MiniPlayer({
    super.key,
    required this.onTap,
    required this.audioPlayer,
    this.onPlayVideo,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final PlaybackManager _playbackManager = PlaybackManager();
  final FavoritesService _favoritesService = FavoritesService();
  final QueueService _queueService = QueueService();
  final PlaybackHistoryService _historyService = PlaybackHistoryService();
  bool _isMuted = false;

  // Video controller & state for mini video playback on dashboard
  VideoPlayerController? _videoController;
  String? _currentVideoPath;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;
  Timer? _hideVideoControlsTimer;
  StreamSubscription<bool>? _audioPlayingSubscription;

  @override
  void initState() {
    super.initState();
    _playbackManager.addListener(_onPlaybackChanged);
    _favoritesService.addListener(_onFavoritesChanged);
    _historyService.addListener(_onHistoryChanged);

    // Auto-pause video if audio playback starts & sync playing state
    _audioPlayingSubscription =
        widget.audioPlayer.playingStream.listen((playing) {
      final current = _playbackManager.currentlyPlaying ??
          _historyService.history.firstOrNull;
      if (current != null && current.type == MediaType.audio) {
        _playbackManager.updatePlayingState(playing);
      }
      if (playing && _videoController?.value.isPlaying == true) {
        _videoController?.pause();
        if (mounted) setState(() {});
      }
    });

    // Initialize video controller if initial item is a video
    final initial = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (initial != null && initial.type == MediaType.video) {
      _initVideoController(initial.path, autoPlay: _playbackManager.isPlaying);
    }
  }

  @override
  void dispose() {
    _disposeVideoController();
    _audioPlayingSubscription?.cancel();
    _playbackManager.removeListener(_onPlaybackChanged);
    _favoritesService.removeListener(_onFavoritesChanged);
    _historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (!mounted) return;
    if (_playbackManager.isFullVideoActive) {
      if (_videoController != null) {
        _disposeVideoController();
      }
      setState(() {});
      return;
    }
    final current = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (current != null && current.type == MediaType.video) {
      _initVideoController(current.path, autoPlay: _playbackManager.isPlaying);
    } else {
      if (_videoController != null) {
        _disposeVideoController();
      }
    }
    setState(() {});
  }

  void _onHistoryChanged() {
    if (!mounted) return;
    if (_playbackManager.isFullVideoActive) {
      if (_videoController != null) {
        _disposeVideoController();
      }
      setState(() {});
      return;
    }
    final current = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (current != null && current.type == MediaType.video) {
      if (_currentVideoPath != current.path) {
        _initVideoController(current.path);
      }
    } else if (current != null && current.type == MediaType.audio) {
      if (_videoController != null) {
        _disposeVideoController();
      }
    }
    setState(() {});
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initVideoController(String path, {bool autoPlay = false}) async {
    if (_currentVideoPath == path && _videoController != null) {
      final ctrl = _videoController;
      if (ctrl == null) return;
      if (autoPlay && !ctrl.value.isPlaying) {
        if (widget.audioPlayer.playing) {
          await widget.audioPlayer.pause();
        }
        if (!mounted || _currentVideoPath != path || _videoController != ctrl) {
          return;
        }
        await ctrl.play();
        _playbackManager.updatePlayingState(true);
        _startHideVideoControlsTimer();
        if (mounted) setState(() {});
      }
      return;
    }

    _currentVideoPath = path;
    final old = _videoController;
    _videoController = null;
    _isVideoInitialized = false;
    await old?.pause();
    await old?.dispose();

    if (!mounted || _currentVideoPath != path) {
      return;
    }

    try {
      final controller = VideoPlayerController.file(
        File(path),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      _videoController = controller;
      await controller.initialize();

      if (!mounted || _currentVideoPath != path || _videoController != controller) {
        if (_videoController == controller) {
          _videoController = null;
        }
        await controller.dispose();
        return;
      }

      await controller.setVolume(_isMuted ? 0.0 : 1.0);

      // Seek to saved position if valid
      final savedPos = _playbackManager.position;
      if (savedPos > Duration.zero && savedPos < controller.value.duration) {
        await controller.seekTo(savedPos);
      }

      controller.addListener(_onVideoTick);

      if (autoPlay) {
        if (widget.audioPlayer.playing) {
          await widget.audioPlayer.pause();
        }
        if (!mounted || _currentVideoPath != path || _videoController != controller) {
          return;
        }
        await controller.play();
        _playbackManager.updatePlayingState(true);
        _startHideVideoControlsTimer();
      }

      if (mounted && _videoController == controller) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (_) {
      _isVideoInitialized = false;
      if (mounted) setState(() {});
    }
  }

  void _onVideoTick() {
    final ctrl = _videoController;
    if (!mounted || ctrl == null || !ctrl.value.isInitialized) return;
    final isPlaying = ctrl.value.isPlaying;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;

    if (_playbackManager.isPlaying != isPlaying) {
      _playbackManager.updatePlayingState(isPlaying);
    }
    _playbackManager.updatePosition(pos);
    _playbackManager.updateDuration(dur);
    if (mounted) setState(() {});
  }

  void _disposeVideoController() {
    _hideVideoControlsTimer?.cancel();
    _currentVideoPath = null;
    _isVideoInitialized = false;
    final c = _videoController;
    _videoController = null;
    c?.removeListener(_onVideoTick);
    c?.pause();
    c?.dispose();
  }

  void _startHideVideoControlsTimer() {
    _hideVideoControlsTimer?.cancel();
    _hideVideoControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController?.value.isPlaying == true) {
        setState(() => _showVideoControls = false);
      }
    });
  }

  Future<void> _toggleVideoPlayPause() async {
    final current = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (current == null) return;

    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      await _initVideoController(current.path, autoPlay: true);
      return;
    }

    if (ctrl.value.isPlaying) {
      await ctrl.pause();
      _playbackManager.updatePlayingState(false);
      _hideVideoControlsTimer?.cancel();
      if (mounted) setState(() => _showVideoControls = true);
    } else {
      if (widget.audioPlayer.playing) {
        await widget.audioPlayer.pause();
      }
      if (!mounted || _videoController != ctrl) return;
      await ctrl.play();
      _playbackManager.updatePlayingState(true);
      _startHideVideoControlsTimer();
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleVideoMute() async {
    setState(() => _isMuted = !_isMuted);
    await _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _openFullVideo(MediaItem item) {
    final ctrl = _videoController;
    if (ctrl != null && ctrl.value.isInitialized) {
      _playbackManager.updatePosition(ctrl.value.position);
      _playbackManager.updateDuration(ctrl.value.duration);
      ctrl.pause();
    }
    _disposeVideoController();
    _playbackManager.setFullVideoActive(true);
    if (widget.onPlayVideo != null) {
      widget.onPlayVideo!(item);
    } else {
      widget.onTap();
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (widget.audioPlayer.playing) {
        await widget.audioPlayer.pause();
        _playbackManager.updatePlayingState(false);
      } else {
        final current = _playbackManager.currentlyPlaying ??
            _historyService.history.firstOrNull;
        if (current != null &&
            current.type == MediaType.audio &&
            widget.audioPlayer.audioSource == null) {
          await widget.audioPlayer.setFilePath(current.path);
        }
        await widget.audioPlayer.play();
        _playbackManager.updatePlayingState(true);
      }
    } catch (e) {
      debugPrint('Error toggling audio playback: $e');
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


  Future<void> _skipPreviousVideo() async {
    final videoHistory = _historyService.history
        .where((m) => m.type == MediaType.video)
        .toList();
    final current = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (current != null && videoHistory.isNotEmpty) {
      final idx = videoHistory.indexWhere(
        (m) => m.id == current.id || m.path == current.path,
      );
      if (idx > 0) {
        final prev = videoHistory[idx - 1];
        _playbackManager.updateCurrentlyPlaying(prev);
        await _initVideoController(prev.path, autoPlay: true);
        return;
      }
    }
    if (current != null) {
      await _initVideoController(current.path, autoPlay: true);
    }
  }

  Future<void> _skipNextVideo() async {
    final videoHistory = _historyService.history
        .where((m) => m.type == MediaType.video)
        .toList();
    final current = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;
    if (current != null && videoHistory.isNotEmpty) {
      final idx = videoHistory.indexWhere(
        (m) => m.id == current.id || m.path == current.path,
      );
      if (idx >= 0 && idx < videoHistory.length - 1) {
        final next = videoHistory[idx + 1];
        _playbackManager.updateCurrentlyPlaying(next);
        await _initVideoController(next.path, autoPlay: true);
        return;
      }
    }
    if (current != null) {
      await _initVideoController(current.path, autoPlay: true);
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
                color: Colors.white.withValues(alpha: 0.3),
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
                            : Colors.orange.withValues(alpha: 0.2),
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
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
    final currentItem = _playbackManager.currentlyPlaying ??
        _historyService.history.firstOrNull;

    if (currentItem == null) {
      return _buildNoMediaCard();
    }

    if (currentItem.type == MediaType.video) {
      return _buildMiniVideoPlayer(currentItem);
    }

    return _buildMiniAudioPlayer(currentItem);
  }

  Widget _buildNoMediaCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF222222).withValues(alpha: 0.90),
                const Color(0xFF141414).withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.orange,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No media playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap to browse your library',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGlassActionBtn(
                  icon: Icons.library_music_rounded,
                  iconColor: Colors.orange,
                  onTap: widget.onTap,
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildMiniVideoPlayer(MediaItem item) {
    final ctrl = _videoController;
    final isInitialized = _isVideoInitialized &&
        ctrl != null &&
        ctrl.value.isInitialized;
    final isPlaying = isInitialized && ctrl.value.isPlaying;
    final position = isInitialized
        ? ctrl.value.position
        : _playbackManager.position;
    final duration = isInitialized
        ? ctrl.value.duration
        : _playbackManager.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Player Viewport or Large Thumbnail Preview
              Container(
                color: Colors.black,
                child: isInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: ctrl.value.aspectRatio,
                          child: VideoPlayer(ctrl),
                        ),
                      )
                    : _buildVideoLargePreview(item),
              ),

              // 2. Tap to toggle controls / double tap to play/pause
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showVideoControls = !_showVideoControls;
                  });
                  if (_showVideoControls && isPlaying) {
                    _startHideVideoControlsTimer();
                  }
                },
                onDoubleTap: _toggleVideoPlayPause,
                child: Container(color: Colors.transparent),
              ),

              // 3. Center Play/Pause button (visible when paused or when controls active)
              if (!isPlaying || _showVideoControls)
                Center(
                  child: GestureDetector(
                    onTap: _toggleVideoPlayPause,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.65),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.40),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),

              // 4. Top Header Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: (_showVideoControls || !isPlaying) ? 0 : -65,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Video Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam_rounded,
                              color: Colors.blue,
                              size: 11,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'VIDEO',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Title
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Bottom Controls Overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: (_showVideoControls || !isPlaying) ? 0 : -75,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scrubber progress slider & timestamps
                      Row(
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10,
                                ),
                                activeTrackColor: Colors.blue,
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.25),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: (val) {
                                  final ctrl = _videoController;
                                  if (ctrl != null &&
                                      ctrl.value.isInitialized) {
                                    final target = Duration(
                                      milliseconds: (val *
                                              ctrl
                                                  .value
                                                  .duration
                                                  .inMilliseconds)
                                          .round(),
                                    );
                                    ctrl.seekTo(target);
                                  }
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Quick buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniIconBtn(
                            icon: Icons.skip_previous_rounded,
                            onTap: _skipPreviousVideo,
                          ),
                          _buildMiniIconBtn(
                            icon: isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            iconColor: Colors.blue,
                            size: 26,
                            onTap: _toggleVideoPlayPause,
                          ),
                          _buildMiniIconBtn(
                            icon: Icons.skip_next_rounded,
                            onTap: _skipNextVideo,
                          ),
                          _buildMiniIconBtn(
                            icon: _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            iconColor: _isMuted
                                ? Colors.blue
                                : Colors.white.withValues(alpha: 0.8),
                            onTap: _toggleVideoMute,
                          ),
                          _buildMiniIconBtn(
                            icon: _favoritesService.isFavorite(item.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            iconColor: _favoritesService.isFavorite(item.id)
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.8),
                            onTap: () => _toggleFavorite(item),
                          ),
                          _buildMiniIconBtn(
                            icon: Icons.fullscreen_rounded,
                            size: 22,
                            onTap: () => _openFullVideo(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLargePreview(MediaItem item) {
    if (item.thumbnailPath != null &&
        File(item.thumbnailPath!).existsSync()) {
      return Image.file(
        File(item.thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _defaultVideoBg(),
      );
    }
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

  Widget _buildMiniIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white.withValues(alpha: 0.85),
          size: size,
        ),
      ),
    );
  }

  Widget _buildMiniAudioPlayer(MediaItem currentItem) {
    const accentColor = Colors.orange;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // 1. Color-graded ambient glow matching application UI (orange for songs)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.85, -0.2),
                      radius: 1.5,
                      colors: [
                        accentColor.withValues(alpha: 0.22),
                        accentColor.withValues(alpha: 0.05),
                        const Color(0xFF111111),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
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
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
              ),

              // 4. Foreground Player Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main media information & buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Animated / Glowing Thumbnail
                        StreamBuilder<PlayerState>(
                          stream: widget.audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data?.playing ?? false;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isPlaying)
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange
                                              .withValues(alpha: 0.45),
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
                        // Media info
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color:
                                            accentColor.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.music_note_rounded,
                                          size: 10,
                                          color: accentColor,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'SONG',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      currentItem.artist ?? 'Unknown Artist',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
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
                        // Action buttons in crystal glass pills
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGlassActionBtn(
                              icon: _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              iconColor: _isMuted
                                  ? Colors.orange
                                  : Colors.white.withValues(alpha: 0.8),
                              onTap: _toggleMute,
                            ),
                            const SizedBox(width: 6),
                            _buildGlassActionBtn(
                              icon: _favoritesService.isFavorite(currentItem.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              iconColor:
                                  _favoritesService.isFavorite(currentItem.id)
                                      ? Colors.red
                                      : Colors.white.withValues(alpha: 0.8),
                              onTap: () => _toggleFavorite(currentItem),
                            ),
                            const SizedBox(width: 6),
                            _buildGlassActionBtn(
                              icon: Icons.queue_music_rounded,
                              iconColor: Colors.white.withValues(alpha: 0.8),
                              onTap: _showQueueDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Progress bar with timestamps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _buildAudioProgress(),
                  ),

                  const SizedBox(height: 8),

                  // Bottom controls bar with translucent crystal glass finish
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
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
                                  colors: [
                                    Color(0xFFFF9800),
                                    Color(0xFFFF6F00),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.orange.withValues(alpha: 0.45),
                                    blurRadius: 10,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioProgress() {
    return _MiniAudioTimeline(audioPlayer: widget.audioPlayer);
  }




  Widget _defaultVideoBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C1F2E), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(MediaItem item) {
    Widget thumbImage;
    if (item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()) {
      thumbImage = Image.file(
        File(item.thumbnailPath!),
        width: 58,
        height: 58,
        cacheWidth: 120,
        cacheHeight: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultVideoThumb(),
      );
    } else {
      thumbImage = FutureBuilder<String?>(
        future: ThumbnailService.getVideoThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              File(snapshot.data!),
              width: 58,
              height: 58,
              cacheWidth: 120,
              cacheHeight: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _defaultVideoThumb(),
            );
          }
          return _defaultVideoThumb();
        },
      );
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: thumbImage),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultVideoThumb() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.4),
            Colors.blue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
    );
  }

  Widget _buildGlassActionBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
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
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  snapshot.data!,
                  width: 58,
                  height: 58,
                  cacheWidth: 120,
                  cacheHeight: 120,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.4),
                  Colors.orange.withValues(alpha: 0.2),
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
    return _buildVideoThumbnail(item);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

class _MiniAudioTimeline extends StatefulWidget {
  final AudioPlayer audioPlayer;

  const _MiniAudioTimeline({required this.audioPlayer});

  @override
  State<_MiniAudioTimeline> createState() => _MiniAudioTimelineState();
}

class _MiniAudioTimelineState extends State<_MiniAudioTimeline> {
  bool _isDragging = false;
  double _dragFraction = 0.0;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _seekToFraction(double fraction) {
    final duration = widget.audioPlayer.duration ?? Duration.zero;
    if (duration > Duration.zero) {
      final targetMs =
          (fraction.clamp(0.0, 1.0) * duration.inMilliseconds).round();
      final target = Duration(milliseconds: targetMs);
      widget.audioPlayer.seek(target);
      PlaybackManager().updatePosition(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = widget.audioPlayer.duration ?? Duration.zero;
        final realProgress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        final displayFraction = _isDragging ? _dragFraction : realProgress;
        final displayPosition = _isDragging
            ? Duration(
                milliseconds:
                    (displayFraction * duration.inMilliseconds).round(),
              )
            : position;

        return LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (trackWidth > 0) {
                  final fraction =
                      (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  _seekToFraction(fraction);
                }
              },
              onHorizontalDragStart: (details) {
                if (trackWidth > 0) {
                  setState(() {
                    _isDragging = true;
                    _dragFraction =
                        (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  });
                }
              },
              onHorizontalDragUpdate: (details) {
                if (trackWidth > 0) {
                  setState(() {
                    _dragFraction =
                        (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  });
                }
              },
              onHorizontalDragEnd: (details) {
                if (_isDragging) {
                  _seekToFraction(_dragFraction);
                  setState(() {
                    _isDragging = false;
                  });
                }
              },
              onHorizontalDragCancel: () {
                if (_isDragging) {
                  setState(() {
                    _isDragging = false;
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Generous vertical touch area for effortless tapping/scrubbing
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      height: 12,
                      width: trackWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Background track
                          Container(
                            height: 4,
                            width: trackWidth,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Active progress track
                          Container(
                            height: 4,
                            width: (displayFraction * trackWidth)
                                .clamp(0.0, trackWidth),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Thumb handle indicator
                          Positioned(
                            left: ((displayFraction * trackWidth) - 5)
                                .clamp(0.0, (trackWidth - 10).clamp(0.0, double.infinity)),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withValues(alpha: 0.45),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(displayPosition),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
