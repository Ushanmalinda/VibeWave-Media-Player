import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../services/media_scanner.dart';
import '../services/thumbnail_service.dart';
import '../services/favorites_service.dart';
import '../services/bookmarks_service.dart';
import '../services/queue_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  List<FolderItem> _folders = [];
  List<MediaItem> _videoList = [];
  VideoPlayerController? _controller;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _isInFolderView = true;
  bool _isFullScreen = false;
  bool _isLocked = false;
  double _playbackSpeed = 1.0;
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  Timer? _hideControlsTimer;
  Timer? _positionUpdateTimer;
  FolderItem? _currentFolder;
  final FavoritesService _favoritesService = FavoritesService();
  final BookmarksService _bookmarksService = BookmarksService();
  final QueueService _queueService = QueueService();
  final ValueNotifier<int> _fullscreenUpdateNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _scanMediaFiles();
    _favoritesService.addListener(_onFavoritesChanged);
    _bookmarksService.addListener(_onFavoritesChanged);
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _positionUpdateTimer?.cancel();
    _fullscreenUpdateNotifier.dispose();
    _favoritesService.removeListener(_onFavoritesChanged);
    _controller?.dispose();
    _exitFullScreen();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_isLocked && _showControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _startPositionUpdateTimer() {
    _positionUpdateTimer?.cancel();
    if (_isPlaying) {
      _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (
        timer,
      ) {
        if (mounted &&
            _controller != null &&
            _controller!.value.isInitialized) {
          setState(() {});
        }
      });
    }
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      }
    });
  }

  void _enterFullScreen() {
    setState(() {
      _isFullScreen = true;
      _showControls = true; // Ensure controls are shown initially
    });

    Navigator.of(context, rootNavigator: true)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                _FullScreenVideoWidget(videoPlayerState: this),
          ),
        )
        .then((_) {
          if (_isFullScreen) {
            _exitFullScreen();
          }
        });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _startHideControlsTimer(); // Start timer after entering fullscreen
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (_isFullScreen) {
      setState(() => _isFullScreen = false);
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _changePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    setState(() => _playbackSpeed = speeds[nextIndex]);
    _controller?.setPlaybackSpeed(_playbackSpeed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playback speed: ${_playbackSpeed}x'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _seekForward() {
    final currentPosition = _controller?.value.position ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final maxPosition = _controller?.value.duration ?? Duration.zero;
    _controller?.seekTo(newPosition > maxPosition ? maxPosition : newPosition);
  }

  void _seekBackward() {
    final currentPosition = _controller?.value.position ?? Duration.zero;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller?.seekTo(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  Future<void> _scanMediaFiles() async {
    setState(() => _isLoading = true);
    try {
      final folders = await MediaScanner.scanVideoFiles();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error scanning files: $e');
    }
  }

  void _openFolder(FolderItem folder) {
    setState(() {
      _currentFolder = folder;
      _videoList = folder.mediaFiles;
      _isInFolderView = false;
      _currentIndex = -1;
    });
  }

  void _backToFolders() {
    // Pause and dispose video when going back to folders
    _controller?.pause();
    setState(() {
      _isPlaying = false;
      _isInFolderView = true;
      _currentFolder = null;
    });
  }

  Future<void> _playVideo(int index) async {
    if (index < 0 || index >= _videoList.length) return;

    // Properly dispose old controller
    final oldController = _controller;
    _controller = null;
    await oldController?.pause();
    await oldController?.dispose();

    setState(() => _currentIndex = index);

    try {
      _controller = VideoPlayerController.file(
        File(_videoList[index].path),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();

      _controller!.addListener(() {
        if (!mounted) return;

        // Check for end of video
        if (_controller!.value.position >= _controller!.value.duration &&
            _controller!.value.duration > Duration.zero) {
          _playNext();
        }

        // Update UI when playing state changes
        final isNowPlaying = _controller!.value.isPlaying;
        if (_isPlaying != isNowPlaying) {
          setState(() {
            _isPlaying = isNowPlaying;
          });
          _startPositionUpdateTimer();
        }
      });

      await _controller!.play();
      _startPositionUpdateTimer();
      if (mounted) {
        setState(() {});
        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error playing video: $e');
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;

    if (_isPlaying) {
      await _controller!.pause();
      _hideControlsTimer?.cancel();
      _positionUpdateTimer?.cancel();
    } else {
      await _controller!.play();
      _startHideControlsTimer();
      _startPositionUpdateTimer();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _videoList.length - 1) {
      await _playVideo(_currentIndex + 1);
      // Show controls when changing video
      if (_isFullScreen) {
        setState(() {
          _showControls = true;
        });
        _startHideControlsTimer();
      }
      // Notify fullscreen to rebuild
      _fullscreenUpdateNotifier.value++;
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      await _playVideo(_currentIndex - 1);
      // Show controls when changing video
      if (_isFullScreen) {
        setState(() {
          _showControls = true;
        });
        _startHideControlsTimer();
      }
      // Notify fullscreen to rebuild
      _fullscreenUpdateNotifier.value++;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isInFolderView, // Allow pop only if not in folder view
      onPopInvoked: (didPop) async {
        if (!didPop && _isInFolderView) {
          // This means we're in folder view and system wants to pop
          // Just allow normal navigation back (exit app or go to previous screen)
          return;
        }
        if (!didPop && !_isInFolderView) {
          // We're in video list view, go back to folders instead of exiting
          _backToFolders();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(),
            if (_controller != null &&
                _controller!.value.isInitialized &&
                !_isInFolderView)
              _buildVideoPlayer(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _isInFolderView
                  ? _buildFoldersView()
                  : _buildVideoListView(),
            ),
          ],
        ),
        floatingActionButton: !_isInFolderView
            ? null
            : FloatingActionButton(
                heroTag: 'video_player_fab',
                onPressed: _scanMediaFiles,
                child: const Icon(Icons.refresh),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isInFolderView)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToFolders,
            ),
          Expanded(
            child: Text(
              _isInFolderView
                  ? 'Folders (${_folders.length})'
                  : _currentFolder?.name ?? 'Videos',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Scanning for video files...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersView() {
    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_rounded, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No video files found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap refresh to scan again',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        final isFolderFavorite = _favoritesService.isFolderFavorite(
          folder.path,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.video_library_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${folder.fileCount} ${folder.fileCount == 1 ? "video" : "videos"}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFolderFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFolderFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () async {
                    final wasAlreadyFavorite = _favoritesService
                        .isFolderFavorite(folder.path);
                    await _favoritesService.toggleFolderFavorite(
                      folder.path,
                      folder.mediaFiles,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            wasAlreadyFavorite
                                ? 'Removed ${folder.fileCount} videos from favorites'
                                : 'Added ${folder.fileCount} videos to favorites',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'add_all_to_queue') {
                      _queueService.addAllToQueue(folder.mediaFiles);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${folder.fileCount} videos to queue',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_all_to_queue',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music),
                          SizedBox(width: 8),
                          Text('Add all to queue'),
                        ],
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openFolder(folder),
          ),
        );
      },
    );
  }

  Widget _buildFullscreenPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: RepaintBoundary(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          _buildPlayerControls(isFullscreen: true),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: RepaintBoundary(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
            _buildPlayerControls(isFullscreen: false),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControls({required bool isFullscreen}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Lock button (always visible)
        if (!_isLocked)
          Positioned(
            top: 16,
            left: 16,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: const Icon(
                  Icons.lock_open,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => setState(() => _isLocked = true),
              ),
            ),
          ),

        if (_isLocked)
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.lock, color: Colors.orange, size: 28),
              onPressed: () => setState(() => _isLocked = false),
            ),
          ),

        // Main controls (hidden when locked)
        if (_showControls && !_isLocked)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (isFullscreen)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _exitFullScreen,
                        ),
                      Expanded(
                        child: Text(
                          _currentIndex >= 0 &&
                                  _currentIndex < _videoList.length
                              ? _videoList[_currentIndex].title
                              : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_currentIndex >= 0 &&
                          _currentIndex < _videoList.length)
                        IconButton(
                          icon: Icon(
                            _favoritesService.isFavorite(
                                  _videoList[_currentIndex].id,
                                )
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _favoritesService.isFavorite(
                                  _videoList[_currentIndex].id,
                                )
                                ? Colors.red
                                : Colors.white,
                          ),
                          onPressed: () {
                            _favoritesService.toggleFavorite(
                              _videoList[_currentIndex],
                            );
                          },
                        ),
                      if (_currentIndex >= 0 &&
                          _currentIndex < _videoList.length)
                        IconButton(
                          icon: Icon(
                            _bookmarksService.isBookmarked(
                                  _videoList[_currentIndex].id,
                                )
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color:
                                _bookmarksService.isBookmarked(
                                  _videoList[_currentIndex].id,
                                )
                                ? Colors.orange
                                : Colors.white,
                          ),
                          onPressed: () async {
                            await _bookmarksService.toggleBookmark(
                              _videoList[_currentIndex],
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _bookmarksService.isBookmarked(
                                          _videoList[_currentIndex].id,
                                        )
                                        ? 'Added to bookmarks'
                                        : 'Removed from bookmarks',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'speed') {
                            _changePlaybackSpeed();
                          } else if (value == 'rotate') {
                            _toggleFullScreen();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'speed',
                            child: Row(
                              children: [
                                const Icon(Icons.speed),
                                const SizedBox(width: 8),
                                Text('Speed: ${_playbackSpeed}x'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'rotate',
                            child: Row(
                              children: [
                                Icon(
                                  isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isFullscreen
                                      ? 'Exit Fullscreen'
                                      : 'Enter Fullscreen',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 40),
                      color: Colors.white,
                      onPressed: _seekBackward,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                      ),
                      color: Colors.white,
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.forward_10, size: 40),
                      color: Colors.white,
                      onPressed: _seekForward,
                    ),
                  ],
                ),

                // Bottom controls
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value: _controller!
                                    .value
                                    .position
                                    .inMilliseconds
                                    .toDouble()
                                    .clamp(
                                      0.0,
                                      _controller!.value.duration.inMilliseconds
                                          .toDouble(),
                                    ),
                                min: 0.0,
                                max: _controller!.value.duration.inMilliseconds
                                    .toDouble()
                                    .clamp(1.0, double.infinity),
                                onChanged: (value) {
                                  _controller!.seekTo(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                                activeColor: Colors.orange,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                ),
                                onPressed: _currentIndex > 0
                                    ? _playPrevious
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                ),
                                onPressed: _currentIndex < _videoList.length - 1
                                    ? _playNext
                                    : null,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleFullScreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVideoListView() {
    return ListView.builder(
      itemCount: _videoList.length,
      itemBuilder: (context, index) {
        final item = _videoList[index];
        final isPlaying = index == _currentIndex;
        final isFavorite = _favoritesService.isFavorite(item.id);

        return ListTile(
          leading: VideoThumbnail(
            videoPath: item.path,
            size: 48,
            showPlayIcon: isPlaying,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
              color: isPlaying ? Theme.of(context).colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  final wasAlreadyFavorite = _favoritesService.isFavorite(
                    item.id,
                  );
                  await _favoritesService.toggleFavorite(item);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasAlreadyFavorite
                              ? 'Removed from favorites'
                              : 'Added to favorites',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'play_next') {
                    _queueService.addNext(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to play next'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (value == 'add_to_queue') {
                    _queueService.addToQueue(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to queue'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'play_next',
                    child: Row(
                      children: [
                        Icon(Icons.skip_next),
                        SizedBox(width: 8),
                        Text('Play Next'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_to_queue',
                    child: Row(
                      children: [
                        Icon(Icons.queue_music),
                        SizedBox(width: 8),
                        Text('Add to queue'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _playVideo(index),
        );
      },
    );
  }
}

// Helper widget for displaying video thumbnails
class VideoThumbnail extends StatefulWidget {
  final String videoPath;
  final double size;
  final bool showPlayIcon;

  const VideoThumbnail({
    super.key,
    required this.videoPath,
    this.size = 48,
    this.showPlayIcon = false,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the path changes
    if (oldWidget.videoPath != widget.videoPath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final thumbnail = await ThumbnailService.getVideoThumbnail(
      widget.videoPath,
    );
    if (mounted) {
      setState(() {
        _thumbnailPath = thumbnail;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show gradient while loading
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      );
    }

    if (_thumbnailPath != null) {
      // Display video thumbnail
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: FileImage(File(_thumbnailPath!)),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: widget.showPlayIcon
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              )
            : null,
      );
    }

    // Fallback to gradient background
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        widget.showPlayIcon ? Icons.play_arrow_rounded : Icons.videocam_rounded,
        color: Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }
}

// Fullscreen Video Player Widget
class _FullScreenVideoWidget extends StatefulWidget {
  final _VideoPlayerScreenState videoPlayerState;

  const _FullScreenVideoWidget({required this.videoPlayerState});

  @override
  State<_FullScreenVideoWidget> createState() => _FullScreenVideoWidgetState();
}

class _FullScreenVideoWidgetState extends State<_FullScreenVideoWidget> {
  bool _localShowControls = true;
  Timer? _localHideTimer;
  Timer? _localUpdateTimer;
  double? _dragStartY;
  double? _dragStartBrightness;
  double? _dragStartVolume;
  double? _dragStartX;
  Duration? _dragStartPosition;
  bool _showBrightnessIndicator = false;
  bool _showVolumeIndicator = false;
  bool _showSeekIndicator = false;
  int _seekSeconds = 0;
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  double? _originalBrightness;
  double? _originalVolume;
  final VolumeController _volumeController = VolumeController();

  @override
  void initState() {
    super.initState();
    // Listen to video changes
    widget.videoPlayerState._fullscreenUpdateNotifier.addListener(
      _onVideoChanged,
    );
    // Start hide timer for fullscreen
    _startLocalHideTimer();
    // Start update timer for progress bar
    _startLocalUpdateTimer();
    // Get current brightness and volume, save them
    _getCurrentBrightness();
    _getCurrentVolume();
  }

  Future<void> _getCurrentBrightness() async {
    try {
      final brightness = await ScreenBrightness().current;
      setState(() {
        _currentBrightness = brightness;
        // Save original brightness when entering fullscreen
        if (_originalBrightness == null) {
          _originalBrightness = brightness;
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _getCurrentVolume() async {
    try {
      final volume = await _volumeController.getVolume();
      setState(() {
        _currentVolume = volume;
        // Save original volume when entering fullscreen
        if (_originalVolume == null) {
          _originalVolume = volume;
        }
      });
      // Set to show media volume only, not system UI
      _volumeController.showSystemUI = false;
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness.clamp(0.0, 1.0));
      setState(() {
        _currentBrightness = brightness.clamp(0.0, 1.0);
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      _volumeController.setVolume(volume.clamp(0.0, 1.0), showSystemUI: false);
      setState(() {
        _currentVolume = volume.clamp(0.0, 1.0);
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _restoreOriginalBrightness() async {
    if (_originalBrightness != null) {
      try {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _restoreOriginalVolume() async {
    if (_originalVolume != null) {
      try {
        _volumeController.setVolume(_originalVolume!);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  @override
  void dispose() {
    _localHideTimer?.cancel();
    _localUpdateTimer?.cancel();
    // Restore original brightness and volume when exiting fullscreen
    _restoreOriginalBrightness();
    _restoreOriginalVolume();
    widget.videoPlayerState._fullscreenUpdateNotifier.removeListener(
      _onVideoChanged,
    );
    super.dispose();
  }

  void _onVideoChanged() {
    if (mounted) {
      setState(() {
        _localShowControls = true;
      });
      _startLocalHideTimer();
    }
  }

  void _startLocalHideTimer() {
    _localHideTimer?.cancel();
    if (!widget.videoPlayerState._isLocked && _localShowControls) {
      _localHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _localShowControls = false;
          });
        }
      });
    }
  }

  void _startLocalUpdateTimer() {
    _localUpdateTimer?.cancel();
    _localUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      if (mounted &&
          widget.videoPlayerState._controller != null &&
          widget.videoPlayerState._controller!.value.isInitialized) {
        setState(() {});
      }
    });
  }

  void _toggleLocalControls() {
    if (widget.videoPlayerState._isLocked) return;
    setState(() {
      _localShowControls = !_localShowControls;
      // Update parent state too
      widget.videoPlayerState._showControls = _localShowControls;
      if (_localShowControls) {
        _startLocalHideTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Temporarily update parent's _showControls to match local state
    widget.videoPlayerState._showControls = _localShowControls;

    return WillPopScope(
      onWillPop: () async {
        widget.videoPlayerState._exitFullScreen();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video player (bottom layer)
            widget.videoPlayerState._buildFullscreenPlayer(),

            // Gesture detection layer (only active when controls are hidden)
            if (!_localShowControls)
              GestureDetector(
                onHorizontalDragStart: (details) {
                  if (widget.videoPlayerState._controller != null &&
                      widget
                          .videoPlayerState
                          ._controller!
                          .value
                          .isInitialized) {
                    _dragStartX = details.globalPosition.dx;
                    _dragStartPosition =
                        widget.videoPlayerState._controller!.value.position;
                    setState(() {
                      _showSeekIndicator = true;
                      _seekSeconds = 0;
                    });
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (_dragStartX != null &&
                      _dragStartPosition != null &&
                      widget.videoPlayerState._controller != null &&
                      widget
                          .videoPlayerState
                          ._controller!
                          .value
                          .isInitialized) {
                    final delta = details.globalPosition.dx - _dragStartX!;
                    final screenWidth = MediaQuery.of(context).size.width;
                    // Every 10% of screen width = 5 seconds
                    final seconds = (delta / screenWidth * 50).round();
                    setState(() {
                      _seekSeconds = seconds;
                    });

                    // Real-time seek while dragging
                    final newPosition =
                        _dragStartPosition! + Duration(seconds: seconds);
                    final duration =
                        widget.videoPlayerState._controller!.value.duration;
                    final clampedPosition = Duration(
                      milliseconds: newPosition.inMilliseconds.clamp(
                        0,
                        duration.inMilliseconds,
                      ),
                    );
                    widget.videoPlayerState._controller!.seekTo(
                      clampedPosition,
                    );
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (_dragStartPosition != null &&
                      _seekSeconds != 0 &&
                      widget.videoPlayerState._controller != null &&
                      widget
                          .videoPlayerState
                          ._controller!
                          .value
                          .isInitialized) {
                    final newPosition =
                        _dragStartPosition! + Duration(seconds: _seekSeconds);
                    final duration =
                        widget.videoPlayerState._controller!.value.duration;
                    final clampedPosition = Duration(
                      milliseconds: newPosition.inMilliseconds.clamp(
                        0,
                        duration.inMilliseconds,
                      ),
                    );
                    widget.videoPlayerState._controller!.seekTo(
                      clampedPosition,
                    );
                  }
                  setState(() {
                    _showSeekIndicator = false;
                    _dragStartX = null;
                    _dragStartPosition = null;
                    _seekSeconds = 0;
                  });
                },
                onVerticalDragStart: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isLeftSide =
                      details.globalPosition.dx < screenWidth / 2;

                  if (isLeftSide) {
                    // Brightness control on left side
                    _dragStartY = details.globalPosition.dy;
                    _dragStartBrightness = _currentBrightness;
                    setState(() {
                      _showBrightnessIndicator = true;
                    });
                  } else {
                    // Volume control on right side
                    _dragStartY = details.globalPosition.dy;
                    _dragStartVolume = _currentVolume;
                    setState(() {
                      _showVolumeIndicator = true;
                    });
                  }
                },
                onVerticalDragUpdate: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isLeftSide =
                      details.globalPosition.dx < screenWidth / 2;

                  if (isLeftSide &&
                      _dragStartY != null &&
                      _dragStartBrightness != null) {
                    // Brightness control
                    final delta = _dragStartY! - details.globalPosition.dy;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final brightnessDelta = delta / screenHeight;
                    final newBrightness =
                        (_dragStartBrightness! + brightnessDelta).clamp(
                          0.0,
                          1.0,
                        );
                    _setBrightness(newBrightness);
                  } else if (!isLeftSide &&
                      _dragStartY != null &&
                      _dragStartVolume != null) {
                    // Volume control
                    final delta = _dragStartY! - details.globalPosition.dy;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final volumeDelta = delta / screenHeight;
                    final newVolume = (_dragStartVolume! + volumeDelta).clamp(
                      0.0,
                      1.0,
                    );
                    _setVolume(newVolume);
                  }
                },
                onVerticalDragEnd: (details) {
                  setState(() {
                    _showBrightnessIndicator = false;
                    _showVolumeIndicator = false;
                    _dragStartY = null;
                    _dragStartBrightness = null;
                    _dragStartVolume = null;
                  });
                },
                onTap: _toggleLocalControls,
                onDoubleTap: () {
                  if (widget.videoPlayerState._controller != null &&
                      widget
                          .videoPlayerState
                          ._controller!
                          .value
                          .isInitialized) {
                    widget.videoPlayerState._togglePlayPause();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            // Brightness indicator
            if (_showBrightnessIndicator)
              Positioned(
                left: 20,
                top: MediaQuery.of(context).size.height / 2 - 75,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.brightness_6,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_currentBrightness * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        width: 40,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: LinearProgressIndicator(
                            value: _currentBrightness,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Volume indicator
            if (_showVolumeIndicator)
              Positioned(
                right: 20,
                top: MediaQuery.of(context).size.height / 2 - 75,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentVolume > 0.5
                            ? Icons.volume_up
                            : _currentVolume > 0
                            ? Icons.volume_down
                            : Icons.volume_off,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_currentVolume * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        width: 40,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: LinearProgressIndicator(
                            value: _currentVolume,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Seek indicator
            if (_showSeekIndicator)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _seekSeconds >= 0
                            ? Icons.fast_forward
                            : Icons.fast_rewind,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_seekSeconds >= 0 ? '+' : ''}${_seekSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Old Fullscreen Video Player Widget (unused, can be removed)
class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onExit;
  final String videoTitle;
  final String videoId;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onChangeSpeed;
  final bool isPlaying;
  final double playbackSpeed;
  final bool canGoNext;
  final bool canGoPrevious;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _FullscreenVideoPlayer({
    required this.controller,
    required this.onExit,
    required this.videoTitle,
    required this.videoId,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onTogglePlayPause,
    required this.onChangeSpeed,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.canGoNext,
    required this.canGoPrevious,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  bool _showControls = true;
  bool _isLocked = false;
  Timer? _hideControlsTimer;
  Timer? _updateTimer;
  final FavoritesService _favoritesService = FavoritesService();
  final BookmarksService _bookmarksService = BookmarksService();

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
    _startUpdateTimer();
    _favoritesService.addListener(_onUpdate);
    _bookmarksService.addListener(_onUpdate);
  }

  @override
  void didUpdateWidget(_FullscreenVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Show controls and restart timers when video changes
    if (oldWidget.videoId != widget.videoId) {
      setState(() {
        _showControls = true;
      });
      _startHideControlsTimer();
      _startUpdateTimer();
    }
    // Restart update timer if playing state changed
    else if (oldWidget.isPlaying != widget.isPlaying) {
      _startUpdateTimer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _updateTimer?.cancel();
    _favoritesService.removeListener(_onUpdate);
    _bookmarksService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    // Always run timer to keep UI updated, but update more frequently when playing
    _updateTimer = Timer.periodic(
      widget.isPlaying
          ? const Duration(milliseconds: 500)
          : const Duration(milliseconds: 100),
      (timer) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (widget.isPlaying && !_isLocked) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && widget.isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Lock button (always visible)
            if (!_isLocked)
              Positioned(
                top: 16,
                left: 16,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(
                      Icons.lock_open,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _isLocked = true),
                  ),
                ),
              ),

            if (_isLocked)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.lock, color: Colors.orange, size: 28),
                  onPressed: () => setState(() => _isLocked = false),
                ),
              ),

            // Main controls (hidden when locked)
            if (_showControls && !_isLocked)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: widget.onExit,
                          ),
                          Expanded(
                            child: Text(
                              widget.videoTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _favoritesService.isFavorite(widget.videoId)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  _favoritesService.isFavorite(widget.videoId)
                                  ? Colors.red
                                  : Colors.white,
                            ),
                            onPressed: () {
                              // Favorite toggle handled by parent
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _bookmarksService.isBookmarked(widget.videoId)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color:
                                  _bookmarksService.isBookmarked(widget.videoId)
                                  ? Colors.orange
                                  : Colors.white,
                            ),
                            onPressed: () {
                              // Bookmark toggle handled by parent
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            onSelected: (value) {
                              if (value == 'speed') {
                                widget.onChangeSpeed();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'speed',
                                child: Row(
                                  children: [
                                    const Icon(Icons.speed),
                                    const SizedBox(width: 8),
                                    Text('Speed: ${widget.playbackSpeed}x'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Center controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, size: 40),
                          color: Colors.white,
                          onPressed: widget.onSeekBackward,
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(
                            widget.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                          ),
                          color: Colors.white,
                          onPressed: widget.onTogglePlayPause,
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.forward_10, size: 40),
                          color: Colors.white,
                          onPressed: widget.onSeekForward,
                        ),
                      ],
                    ),

                    // Bottom controls
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(
                                  widget.controller.value.position,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: widget
                                        .controller
                                        .value
                                        .position
                                        .inSeconds
                                        .toDouble()
                                        .clamp(
                                          0.0,
                                          widget
                                              .controller
                                              .value
                                              .duration
                                              .inSeconds
                                              .toDouble(),
                                        ),
                                    max: widget
                                        .controller
                                        .value
                                        .duration
                                        .inSeconds
                                        .toDouble(),
                                    onChanged: (value) {
                                      widget.controller.seekTo(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                    activeColor: Colors.orange,
                                    inactiveColor: Colors.white.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  widget.controller.value.duration,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                    ),
                                    onPressed: widget.canGoPrevious
                                        ? widget.onPrevious
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                    ),
                                    onPressed: widget.canGoNext
                                        ? widget.onNext
                                        : null,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onExit,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
