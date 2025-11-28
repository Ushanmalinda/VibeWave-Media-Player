import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../services/media_scanner.dart';
import '../services/thumbnail_service.dart';

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
  FolderItem? _currentFolder;

  @override
  void initState() {
    super.initState();
    _scanMediaFiles();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
    setState(() {
      _isInFolderView = true;
      _currentFolder = null;
    });
  }

  Future<void> _playVideo(int index) async {
    if (index < 0 || index >= _videoList.length) return;

    await _controller?.dispose();
    setState(() => _currentIndex = index);

    try {
      _controller = VideoPlayerController.file(File(_videoList[index].path));
      await _controller!.initialize();

      _controller!.addListener(() {
        if (_controller!.value.position == _controller!.value.duration) {
          _playNext();
        }
        setState(() {
          _isPlaying = _controller!.value.isPlaying;
        });
      });

      await _controller!.play();
      setState(() {});
    } catch (e) {
      _showError('Error playing video: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;

    if (_isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _videoList.length - 1) {
      await _playVideo(_currentIndex + 1);
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      await _playVideo(_currentIndex - 1);
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
    return Scaffold(
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
              onPressed: _scanMediaFiles,
              child: const Icon(Icons.refresh),
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openFolder(folder),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        width: double.infinity,
        height: 300,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            if (_showControls)
              Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _videoList[_currentIndex].title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 60,
                      ),
                      color: Colors.white,
                      onPressed: _togglePlayPause,
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(_controller!.value.position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _controller!.value.position.inSeconds
                                      .toDouble(),
                                  max: _controller!.value.duration.inSeconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    _controller!.seekTo(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              Text(
                                _formatDuration(_controller!.value.duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              color: Colors.white,
                              onPressed: _currentIndex > 0
                                  ? _playPrevious
                                  : null,
                            ),
                            const SizedBox(width: 40),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              color: Colors.white,
                              onPressed: _currentIndex < _videoList.length - 1
                                  ? _playNext
                                  : null,
                            ),
                          ],
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

  Widget _buildVideoListView() {
    return ListView.builder(
      itemCount: _videoList.length,
      itemBuilder: (context, index) {
        final item = _videoList[index];
        final isPlaying = index == _currentIndex;

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
