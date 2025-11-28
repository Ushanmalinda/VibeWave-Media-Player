import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../services/media_scanner.dart';
import '../services/thumbnail_service.dart';
import '../services/playback_manager.dart';
import 'dart:math';
import 'dart:typed_data';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaybackManager _playbackManager = PlaybackManager();
  List<FolderItem> _folders = [];
  List<MediaItem> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _showFullPlayer = false;
  bool _isLoading = true;
  bool _isInFolderView = true;
  FolderItem? _currentFolder;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _scanMediaFiles();
  }

  void _setupAudioPlayer() {
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
      _playbackManager.updateDuration(duration ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
      _playbackManager.updatePosition(position);
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
      _playbackManager.updatePlayingState(state.playing);

      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _scanMediaFiles() async {
    setState(() => _isLoading = true);
    try {
      final folders = await MediaScanner.scanAudioFiles();
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
      _playlist = folder.mediaFiles;
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

  Future<void> _playAudio(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    setState(() => _currentIndex = index);
    _playbackManager.updateCurrentlyPlaying(_playlist[index]);

    try {
      await _audioPlayer.setFilePath(_playlist[index].path);
      await _audioPlayer.play();
    } catch (e) {
      _showError('Error playing audio: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _playNext() async {
    if (_playlist.isEmpty) return;

    if (_repeatMode == RepeatMode.one) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    int nextIndex;
    if (_isShuffle) {
      nextIndex = Random().nextInt(_playlist.length);
    } else if (_currentIndex < _playlist.length - 1) {
      nextIndex = _currentIndex + 1;
    } else if (_repeatMode == RepeatMode.all) {
      nextIndex = 0;
    } else {
      return;
    }

    await _playAudio(nextIndex);
  }

  Future<void> _playPrevious() async {
    if (_position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      await _playAudio(_currentIndex - 1);
    }
  }

  void _toggleShuffle() {
    setState(() => _isShuffle = !_isShuffle);
  }

  void _toggleRepeat() {
    setState(() {
      switch (_repeatMode) {
        case RepeatMode.off:
          _repeatMode = RepeatMode.all;
          break;
        case RepeatMode.all:
          _repeatMode = RepeatMode.one;
          break;
        case RepeatMode.one:
          _repeatMode = RepeatMode.off;
          break;
      }
    });
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
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingView()
                    : _isInFolderView
                    ? _buildFoldersView()
                    : _buildPlaylistView(),
              ),
            ],
          ),
          if (_currentIndex >= 0) _buildMiniPlayer(),
          if (_showFullPlayer && _currentIndex >= 0) _buildFullPlayer(),
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
                  : _currentFolder?.name ?? 'Playlist',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (!_isInFolderView) ...[
            IconButton(
              icon: Icon(
                _isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle,
                color: _isShuffle
                    ? Colors.orange
                    : Colors.white.withOpacity(0.7),
              ),
              onPressed: _toggleShuffle,
            ),
            IconButton(
              icon: Icon(
                _repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: _repeatMode != RepeatMode.off
                    ? Colors.orange
                    : Colors.white.withOpacity(0.7),
              ),
              onPressed: _toggleRepeat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'Scanning for audio files...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
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
            Icon(
              Icons.folder_off_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No audio files found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap refresh to scan again',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
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
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Colors.orange,
                size: 32,
              ),
            ),
            title: Text(
              folder.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${folder.fileCount} ${folder.fileCount == 1 ? "song" : "songs"}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
            onTap: () => _openFolder(folder),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistView() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: _currentIndex >= 0 ? 80 : 16),
      itemCount: _playlist.length,
      itemBuilder: (context, index) {
        final item = _playlist[index];
        final isPlaying = index == _currentIndex;
        return Container(
          decoration: BoxDecoration(
            color: isPlaying ? Colors.orange.withOpacity(0.15) : null,
            border: Border(
              left: BorderSide(
                color: isPlaying ? Colors.orange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AudioThumbnail(
                audioPath: item.path,
                size: 48,
                showPlayIcon: isPlaying && _isPlaying,
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                color: isPlaying ? Colors.orange : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.artist ?? 'Unknown Artist',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _playAudio(index),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() => _showFullPlayer = true),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: _duration.inSeconds > 0
                      ? _position.inSeconds / _duration.inSeconds
                      : 0,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.orange,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AudioThumbnail(
                          audioPath: _playlist[_currentIndex].path,
                          size: 48,
                          showPlayIcon: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _playlist[_currentIndex].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _playlist[_currentIndex].artist ??
                                  'Unknown Artist',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: _currentIndex > 0
                              ? Colors.orange
                              : Colors.white.withOpacity(0.3),
                        ),
                        onPressed: _currentIndex > 0 ? _playPrevious : null,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          size: 40,
                          color: Colors.orange,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.orange,
                        ),
                        onPressed: _playNext,
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

  Widget _buildFullPlayer() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF1a1a1a),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _showFullPlayer = false),
                    ),
                    const Spacer(),
                    Text(
                      'Now Playing',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Large album art
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AudioThumbnail(
                    audioPath: _playlist[_currentIndex].path,
                    size: 320,
                    showPlayIcon: false,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Waveform visualization placeholder (animated bars)
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    40,
                    (index) => Container(
                      width: 3,
                      height: _isPlaying
                          ? (20 + (index % 3) * 15).toDouble()
                          : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(
                          _isPlaying ? 0.6 : 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Song title and artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      _playlist[_currentIndex].title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _playlist[_currentIndex].artist ?? 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Progress slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: Colors.orange,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.orange,
                        overlayColor: Colors.orange.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _position.inSeconds.toDouble(),
                        max: _duration.inSeconds > 0
                            ? _duration.inSeconds.toDouble()
                            : 1,
                        onChanged: (value) async {
                          await _audioPlayer.seek(
                            Duration(seconds: value.toInt()),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        _isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle,
                        color: _isShuffle
                            ? Colors.orange
                            : Colors.white.withOpacity(0.5),
                      ),
                      onPressed: _toggleShuffle,
                      iconSize: 26,
                    ),

                    // Previous
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: _currentIndex > 0
                            ? Colors.orange
                            : Colors.white.withOpacity(0.3),
                      ),
                      onPressed: _currentIndex > 0 ? _playPrevious : null,
                      iconSize: 42,
                    ),

                    // Play/Pause
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                        iconSize: 36,
                      ),
                    ),

                    // Next
                    IconButton(
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.orange,
                      ),
                      onPressed: _playNext,
                      iconSize: 42,
                    ),

                    // Repeat
                    IconButton(
                      icon: Icon(
                        _repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        color: _repeatMode != RepeatMode.off
                            ? Colors.orange
                            : Colors.white.withOpacity(0.5),
                      ),
                      onPressed: _toggleRepeat,
                      iconSize: 26,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for displaying audio thumbnails with album art
class AudioThumbnail extends StatefulWidget {
  final String audioPath;
  final double size;
  final bool showPlayIcon;

  const AudioThumbnail({
    super.key,
    required this.audioPath,
    this.size = 48,
    this.showPlayIcon = false,
  });

  @override
  State<AudioThumbnail> createState() => _AudioThumbnailState();
}

class _AudioThumbnailState extends State<AudioThumbnail> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(AudioThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the path changes
    if (oldWidget.audioPath != widget.audioPath) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final thumbnail = await ThumbnailService.getAudioThumbnail(
      widget.audioPath,
    );
    if (mounted) {
      setState(() {
        _thumbnailData = thumbnail;
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
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      );
    }

    if (_thumbnailData != null) {
      // Display album art
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: MemoryImage(_thumbnailData!),
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
            Theme.of(context).colorScheme.tertiary,
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
        widget.showPlayIcon
            ? Icons.play_arrow_rounded
            : Icons.music_note_rounded,
        color: Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }
}
