import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';
import '../services/media_scanner.dart';
import '../services/thumbnail_service.dart';
import '../services/playback_manager.dart';
import '../services/favorites_service.dart';
import '../services/bookmarks_service.dart';
import '../services/queue_service.dart';
import '../services/audio_player_service.dart';
import '../services/controls_manager.dart';
import '../services/settings_service.dart';
import '../services/media_controls_service.dart';
import '../services/last_played_service.dart';
import '../services/playback_history_service.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:math';
import 'dart:typed_data';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayerService().player;
  final PlaybackManager _playbackManager = PlaybackManager();
  final ControlsManager _controlsManager = ControlsManager();
  final SettingsService _settings = SettingsService();
  final VolumeController _volumeController = VolumeController.instance;
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
  bool _isLoadingFromQueue = false;
  double _currentVolume = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
    _scanMediaFiles();
    FavoritesService().initialize();
    FavoritesService().addListener(_onFavoritesChanged);
    BookmarksService().initialize();
    BookmarksService().addListener(_onBookmarksChanged);
    QueueService().addListener(_onQueueChanged);
    _checkExistingQueue();
    _initializeControls();
    _setupMediaControls();

    // Load last played song
    _loadLastPlayedSong();
  }

  Future<void> _loadLastPlayedSong() async {
    final last = await LastPlayedService.loadLastPlayed();
    if (last != null) {
      try {
        final item = MediaItem.fromJson(
          Map<String, dynamic>.from(last['item']),
        );
        final index = last['index'] as int;
        final playlistData = last['playlist'] as List<Map<String, dynamic>>?;

        // Update PlaybackManager so MiniPlayer can show the last played song
        _playbackManager.updateCurrentlyPlaying(item);

        // Restore full playlist if available
        List<MediaItem> playlist = [item];
        int currentIndex = 0;

        if (playlistData != null && playlistData.isNotEmpty) {
          playlist = playlistData
              .map((json) => MediaItem.fromJson(json))
              .toList();
          // Ensure index is within bounds
          currentIndex = index < playlist.length ? index : 0;
        }

        setState(() {
          _playlist = playlist;
          _currentIndex = currentIndex;
          _isInFolderView = false;
        });

        // Update QueueService so next/previous buttons work
        QueueService().setQueue(playlist, startIndex: currentIndex);

        // Load the audio file into the player so play button works
        try {
          await _audioPlayer.setFilePath(playlist[currentIndex].path);

          // Update audio service notification
          AudioPlayerService().updateCurrentMediaItem(
            title: item.title,
            artist: item.artist,
            duration: _audioPlayer.duration,
          );
        } catch (e) {
          // File might not exist anymore
        }

        // Update metadata for lock screen
        MediaControlsService.updateMetadata(
          title: item.title,
          artist: item.artist,
          album: item.album,
          thumbnailPath: item.thumbnailPath,
          playing: false,
        );
      } catch (e) {
        // Error loading last played song
      }
    }
  }

  void _setupMediaControls() {
    MediaControlsService.setupMediaControls(
      player: _audioPlayer,
      onNext: () {
        _playNext();
      },
      onPrevious: () {
        _playPrevious();
      },
      onClose: _closeApp,
      onSeek: (position) async {
        await _audioPlayer.seek(position);
      },
    );
  }

  void _closeApp() {
    // Stop playback
    _audioPlayer.stop();
    // Dispose media controls
    MediaControlsService.dispose();
    // Exit the app

    // Save last played song
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      LastPlayedService.saveLastPlayed(_playlist[_currentIndex], _currentIndex);
    }
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Future<void> _initializeControls() async {
    await _controlsManager.initialize();
    await _settings.initialize();
    _currentVolume = await _volumeController.getVolume();
  }

  void _onFavoritesChanged() {
    setState(() {});
  }

  void _onBookmarksChanged() {
    setState(() {});
  }

  void _onQueueChanged() {
    // When queue changes externally (e.g., from playlists), load and play it
    // Skip if we're already processing a queue change to prevent infinite loop
    if (_isLoadingFromQueue) return;

    final queueService = QueueService();
    // Check if queue actually changed by comparing lists
    if (queueService.hasQueue &&
        (queueService.queue.length != _playlist.length ||
            queueService.currentIndex != _currentIndex)) {
      _isLoadingFromQueue = true;

      setState(() {
        _playlist = List.from(queueService.queue);
        _currentIndex = queueService.currentIndex;
        _isInFolderView = false;
      });

      // Auto-play the selected item
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        _playAudioFromQueue(_currentIndex);
      }

      // Use a post-frame callback to reset the flag
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoadingFromQueue = false;
      });
    }
  }

  void _checkExistingQueue() {
    // Check if there's already a queue set (e.g., from playlists)
    final queueService = QueueService();
    if (queueService.hasQueue) {
      setState(() {
        _playlist = List.from(queueService.queue);
        _currentIndex = queueService.currentIndex;
        _isInFolderView = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentSong();
    FavoritesService().removeListener(_onFavoritesChanged);
    BookmarksService().removeListener(_onBookmarksChanged);
    QueueService().removeListener(_onQueueChanged);
    _controlsManager.dispose();
    // Don't dispose the singleton audio player
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    print('Lifecycle state changed to: $state');

    // Save when app goes to background or paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveCurrentSong();
    }

    // Ensure shake detection is running when app becomes active
    if (state == AppLifecycleState.resumed) {
      // Just verify it's running, don't stop/restart
      await _controlsManager.ensureShakeDetectionRunning();
    }
  }

  void _saveCurrentSong() {
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      LastPlayedService.saveLastPlayed(
        _playlist[_currentIndex],
        _currentIndex,
        _playlist,
      );
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.durationStream.listen((duration) {
      setState(() {
        _duration = duration ?? Duration.zero;
      });
      _playbackManager.updateDuration(duration ?? Duration.zero);

      // Update metadata with duration for lock screen timeline
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        final media = _playlist[_currentIndex];
        MediaControlsService.updateMetadata(
          title: media.title,
          artist: media.artist,
          album: media.album,
          duration: duration,
          thumbnailPath: media.thumbnailPath,
          playing: _isPlaying,
        );
      }
    });

    _audioPlayer.positionStream.listen((position) {
      _position = position;
      _playbackManager.updatePosition(position);
      if (_showFullPlayer && mounted) {
        setState(() {});
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });

      // Update wakelock for shake detection when screen is locked
      _controlsManager.updateWakeLock(state.playing);
      _playbackManager.updatePlayingState(state.playing);

      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> _scanMediaFiles({bool forceRescan = false}) async {
    setState(() => _isLoading = true);
    try {
      final folders = await MediaScanner.scanAudioFiles(
        forceRescan: forceRescan,
      );
      setState(() {
        _folders = folders;
        _isLoading = false;
      });

      if (forceRescan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media library refreshed'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
    // Update queue service without triggering auto-play
    _isLoadingFromQueue = true; // Prevent auto-play when opening folder
    QueueService().setQueue(folder.mediaFiles);
    // Reset flag after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _isLoadingFromQueue = false;
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
    QueueService().setCurrentIndex(index);

    try {
      // Update metadata BEFORE starting playback
      final media = _playlist[index];
      MediaControlsService.updateMetadata(
        title: media.title,
        artist: media.artist,
        album: media.album,
        thumbnailPath: media.thumbnailPath,
        playing: true,
      );

      await _audioPlayer.setFilePath(_playlist[index].path);

      // Update audio service notification
      AudioPlayerService().updateCurrentMediaItem(
        title: media.title,
        artist: media.artist,
        duration: _audioPlayer.duration,
      );

      await _audioPlayer.play();

      // Save as last played song and add to history
      LastPlayedService.saveLastPlayed(media, index, _playlist);
      PlaybackHistoryService().addToHistory(media);
    } catch (e) {
      _showError('Error playing audio: $e');
    }
  }

  Future<void> _playAudioFromQueue(int index) async {
    // Play audio without updating QueueService (to avoid triggering listener)
    if (index < 0 || index >= _playlist.length) return;

    setState(() => _currentIndex = index);

    // Save as last played song and add to history
    LastPlayedService.saveLastPlayed(_playlist[index], index, _playlist);
    PlaybackHistoryService().addToHistory(_playlist[index]);
    _playbackManager.updateCurrentlyPlaying(_playlist[index]);
    // Don't call QueueService().setCurrentIndex() here

    try {
      // Update metadata BEFORE starting playback
      final media = _playlist[index];
      MediaControlsService.updateMetadata(
        title: media.title,
        artist: media.artist,
        album: media.album,
        thumbnailPath: media.thumbnailPath,
        playing: true,
      );

      await _audioPlayer.setFilePath(_playlist[index].path);

      // Update audio service notification
      AudioPlayerService().updateCurrentMediaItem(
        title: media.title,
        artist: media.artist,
        duration: _audioPlayer.duration,
      );

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          if (!_isInFolderView) ...[
            GestureDetector(
              onTap: _backToFolders,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.40),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder_copy_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isInFolderView
                      ? 'Music Folders'
                      : _currentFolder?.name ?? 'Playlist',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isInFolderView
                      ? '${_folders.length} ${_folders.length == 1 ? "folder" : "folders"} found'
                      : '${_playlist.length} ${_playlist.length == 1 ? "song" : "songs"}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isInFolderView) ...[
            GestureDetector(
              onTap: () => _scanMediaFiles(forceRescan: true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.orange, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Rescan',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildHeaderIconPill(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh library',
              onTap: () => _scanMediaFiles(forceRescan: true),
            ),
            const SizedBox(width: 6),
            _buildHeaderIconPill(
              icon: _isShuffle
                  ? Icons.shuffle_on_rounded
                  : Icons.shuffle_rounded,
              isActive: _isShuffle,
              tooltip: 'Shuffle',
              onTap: _toggleShuffle,
            ),
            const SizedBox(width: 6),
            _buildHeaderIconPill(
              icon: _repeatMode == RepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              isActive: _repeatMode != RepeatMode.off,
              tooltip: 'Repeat',
              onTap: _toggleRepeat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderIconPill({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.orange.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isActive
                  ? Colors.orange.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isActive
                ? Colors.orange
                : Colors.white.withValues(alpha: 0.75),
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF181818).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.orange,
              size: 44,
            ),
            const SizedBox(height: 20),
            const Text(
              'Scanning Audio Files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Discovering music tracks across your storage...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersView() {
    if (_folders.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF181818).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.folder_off_rounded,
                  size: 34,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Audio Files Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No audio files were detected on your storage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _scanMediaFiles(forceRescan: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Scan Device',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

    return RefreshIndicator(
      color: Colors.orange,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _scanMediaFiles(forceRescan: true),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 2, bottom: _currentIndex >= 0 ? 96 : 24),
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          return _buildFolderCard(folder);
        },
      ),
    );
  }

  Widget _buildFolderCard(FolderItem folder) {
    final isFavorite = FavoritesService().isFolderFavorite(folder.path);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 1. Subtle illuminated mesh gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.85, -0.2),
                    radius: 1.4,
                    colors: [
                      Colors.orange.withValues(alpha: 0.16),
                      Colors.orange.withValues(alpha: 0.03),
                      const Color(0xFF111111),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Crystal dark frosted tint
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF181818).withValues(alpha: 0.70),
                      const Color(0xFF0E0E0E).withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Specular shine
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),

            // 4. Foreground content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.orange.withValues(alpha: 0.15),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                onTap: () => _openFolder(folder),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // 3D Crystal Orange Folder Badge
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.42),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Folder info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              folder.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${folder.fileCount} ${folder.fileCount == 1 ? "SONG" : "SONGS"}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Favorite button
                      _buildGlassIconButton(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: isFavorite
                            ? Colors.redAccent
                            : Colors.white.withValues(alpha: 0.50),
                        onPressed: () async {
                          await FavoritesService().toggleFolderFavorite(
                            folder.path,
                            folder.mediaFiles,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  FavoritesService().isFolderFavorite(
                                        folder.path,
                                      )
                                      ? 'Added ${folder.fileCount} songs to favorites'
                                      : 'Removed ${folder.fileCount} songs from favorites',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 6),

                      // More menu
                      _buildFolderPopupMenu(folder),
                      const SizedBox(width: 6),

                      // Chevron arrow
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.40),
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
    );
  }

  Widget _buildFolderPopupMenu(FolderItem folder) {
    return Theme(
      data: Theme.of(context).copyWith(cardColor: const Color(0xFF1E1E1E)),
      child: PopupMenuButton<String>(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: Colors.white.withValues(alpha: 0.65),
            size: 19,
          ),
        ),
        padding: EdgeInsets.zero,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        onSelected: (value) {
          if (value == 'add_all_to_queue') {
            QueueService().addAllToQueue(folder.mediaFiles);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${folder.fileCount} songs to queue'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'add_all_to_queue',
            child: Row(
              children: [
                const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add all to queue',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.90)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistView() {
    return RefreshIndicator(
      color: Colors.orange,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () => _scanMediaFiles(forceRescan: true),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 2, bottom: _currentIndex >= 0 ? 96 : 24),
        itemCount: _playlist.length,
        itemBuilder: (context, index) {
          final item = _playlist[index];
          return _buildSongCard(item, index);
        },
      ),
    );
  }

  Widget _buildSongCard(MediaItem item, int index) {
    final isPlaying = index == _currentIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPlaying
              ? Colors.orange.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.12),
          width: isPlaying ? 1.4 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (isPlaying)
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 1. Mesh gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.85, -0.2),
                    radius: 1.4,
                    colors: [
                      isPlaying
                          ? Colors.orange.withValues(alpha: 0.28)
                          : Colors.orange.withValues(alpha: 0.12),
                      isPlaying
                          ? Colors.orange.withValues(alpha: 0.08)
                          : Colors.orange.withValues(alpha: 0.02),
                      const Color(0xFF111111),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Crystal dark frosted tint
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isPlaying
                              ? const Color(0xFF221A12)
                              : const Color(0xFF181818))
                          .withValues(alpha: 0.75),
                      const Color(0xFF0C0C0C).withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 3. Specular shine
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: isPlaying ? 0.14 : 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),

            // 4. Foreground content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: Colors.orange.withValues(alpha: 0.20),
                highlightColor: Colors.white.withValues(alpha: 0.04),
                onTap: () => _playAudio(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Audio thumbnail with crystal border
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: isPlaying
                                ? Colors.orange.withValues(alpha: 0.60)
                                : Colors.white.withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AudioThumbnail(
                            audioPath: item.path,
                            size: 50,
                            showPlayIcon: isPlaying && _isPlaying,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),

                      // Song title & artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: isPlaying ? Colors.orange : Colors.white,
                                fontWeight: isPlaying
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14.5,
                                letterSpacing: 0.1,
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
                                    color: Colors.orange.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.orange.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.music_note_rounded,
                                        color: Colors.orange,
                                        size: 11,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'TRACK',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.artist ?? 'Unknown Artist',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.60,
                                      ),
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

                      // Playing volume/sound indicator
                      if (isPlaying)
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.50),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.pause_rounded,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),

                      // Song popup menu
                      _buildSongPopupMenu(item),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongPopupMenu(MediaItem item) {
    return Theme(
      data: Theme.of(context).copyWith(cardColor: const Color(0xFF1E1E1E)),
      child: PopupMenuButton<String>(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            color: Colors.white.withValues(alpha: 0.60),
            size: 18,
          ),
        ),
        padding: EdgeInsets.zero,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        onSelected: (value) {
          if (value == 'play_next') {
            QueueService().addNext(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${item.title}" will play next'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (value == 'add_to_queue') {
            QueueService().addToQueue(item);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${item.title}" to queue'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          } else if (value == 'add_favorite') {
            FavoritesService().toggleFavorite(item);
            final isFavorite = FavoritesService().isFavorite(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isFavorite ? 'Added to favorites' : 'Removed from favorites',
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'play_next',
            child: Row(
              children: [
                const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Play next',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.90)),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'add_to_queue',
            child: Row(
              children: [
                const Icon(
                  Icons.queue_music_rounded,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add to queue',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.90)),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'add_favorite',
            child: Row(
              children: [
                Icon(
                  FavoritesService().isFavorite(item.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  FavoritesService().isFavorite(item.id)
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.90)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final currentItem = _playlist[_currentIndex];

    return Positioned(
      left: 12,
      right: 12,
      bottom: 10 + bottomPadding,
      child: GestureDetector(
        onTap: () => setState(() => _showFullPlayer = true),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. Ambient orange glow
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.85, 0.0),
                        radius: 1.3,
                        colors: [
                          Colors.orange.withValues(alpha: 0.22),
                          Colors.orange.withValues(alpha: 0.05),
                          const Color(0xFF101010),
                        ],
                        stops: const [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Dark frosted tint
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E1E1E).withValues(alpha: 0.88),
                          const Color(0xFF101010).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // 3. Specular shine
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),

                // 4. Progress bar at top edge
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 2.5,
                  child: StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? _position;
                      final progress = _duration.inSeconds > 0
                          ? (pos.inSeconds / _duration.inSeconds).clamp(
                              0.0,
                              1.0,
                            )
                          : 0.0;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              Container(
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.orangeAccent,
                                      Colors.orange,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // 5. Controls and content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: AudioThumbnail(
                            audioPath: currentItem.path,
                            size: 48,
                            showPlayIcon: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Artist
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentItem.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentItem.artist ?? 'Unknown Artist',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.60),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Previous button
                      _buildMiniPlayerIcon(
                        icon: Icons.skip_previous_rounded,
                        color: _currentIndex > 0
                            ? Colors.orange
                            : Colors.white.withValues(alpha: 0.25),
                        onTap: _currentIndex > 0 ? _playPrevious : null,
                        size: 22,
                      ),
                      const SizedBox(width: 6),

                      // Play/Pause button
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Next button
                      _buildMiniPlayerIcon(
                        icon: Icons.skip_next_rounded,
                        color: Colors.orange,
                        onTap: _playNext,
                        size: 22,
                      ),
                      const SizedBox(width: 4),

                      // Bookmark button
                      _buildMiniPlayerIcon(
                        icon: BookmarksService().isBookmarked(currentItem.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: BookmarksService().isBookmarked(currentItem.id)
                            ? Colors.orange
                            : Colors.white.withValues(alpha: 0.50),
                        onTap: () async {
                          await BookmarksService().toggleBookmark(currentItem);
                          if (mounted) setState(() {});
                        },
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayerIcon({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    double size = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  Widget _buildFullPlayer() {
    final currentItem = _playlist[_currentIndex];
    final isFav = FavoritesService().isFavorite(currentItem.id);
    final isBookmarked = BookmarksService().isBookmarked(currentItem.id);

    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF201610), Color(0xFF121212), Color(0xFF0A0A0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showFullPlayer = false),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Large album art with gesture controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GestureDetector(
                  onHorizontalDragEnd: (details) async {
                    if (!_settings.gesturesEnabled) return;
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity > 500) {
                      await _controlsManager.executeGestureAction(
                        _settings.swipeLeftToRight,
                      );
                    } else if (velocity < -500) {
                      await _controlsManager.executeGestureAction(
                        _settings.swipeRightToLeft,
                      );
                    }
                  },
                  onVerticalDragUpdate: (details) {
                    if (!_settings.gesturesEnabled) return;
                    final delta = -details.delta.dy / 300;
                    final newVolume = (_currentVolume + delta).clamp(0.0, 1.0);
                    _volumeController.setVolume(newVolume);
                    setState(() {
                      _currentVolume = newVolume;
                    });
                  },
                  onVerticalDragEnd: (details) async {
                    if (!_settings.gesturesEnabled) return;
                    if (_settings.scrollVertically == 'volume') return;
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity > 500) {
                      await _controlsManager.executeGestureAction(
                        _settings.swipeTopToBottom,
                      );
                    } else if (velocity < -500) {
                      await _controlsManager.executeGestureAction(
                        _settings.swipeBottomToTop,
                      );
                    }
                  },
                  onDoubleTapDown: (details) async {
                    if (!_settings.gesturesEnabled) return;
                    final size = MediaQuery.of(context).size;
                    final tapX = details.localPosition.dx;
                    final albumArtSize = size.width - 64;

                    if (tapX < albumArtSize / 3) {
                      await _controlsManager.executeGestureAction(
                        _settings.doubleTapLeft,
                      );
                    } else if (tapX > 2 * albumArtSize / 3) {
                      await _controlsManager.executeGestureAction(
                        _settings.doubleTapRight,
                      );
                    } else {
                      await _controlsManager.executeGestureAction(
                        _settings.doubleTapCenter,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.20),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AudioThumbnail(
                        audioPath: currentItem.path,
                        size: 300,
                        showPlayIcon: false,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Waveform visualization placeholder (animated bars)
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    36,
                    (index) => Container(
                      width: 3.5,
                      height: _isPlaying
                          ? (14 + ((index * 7) % 28)).toDouble()
                          : 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orangeAccent,
                            Colors.orange.withValues(
                              alpha: _isPlaying ? 0.7 : 0.3,
                            ),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Song title and artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      currentItem.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentItem.artist ?? 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Favorite and Bookmark buttons in 3D crystal pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await FavoritesService().toggleFavorite(
                              currentItem,
                            );
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? Colors.redAccent.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isFav
                                    ? Colors.redAccent.withValues(alpha: 0.40)
                                    : Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? Colors.redAccent
                                      : Colors.white.withValues(alpha: 0.70),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isFav ? 'Favorite' : 'Add to Fav',
                                  style: TextStyle(
                                    color: isFav
                                        ? Colors.redAccent
                                        : Colors.white.withValues(alpha: 0.80),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () async {
                            await BookmarksService().toggleBookmark(
                              currentItem,
                            );
                            if (mounted) setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isBookmarked
                                  ? Colors.orange.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isBookmarked
                                    ? Colors.orange.withValues(alpha: 0.40)
                                    : Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: isBookmarked
                                      ? Colors.orange
                                      : Colors.white.withValues(alpha: 0.70),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isBookmarked ? 'Bookmarked' : 'Bookmark',
                                  style: TextStyle(
                                    color: isBookmarked
                                        ? Colors.orange
                                        : Colors.white.withValues(alpha: 0.80),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: Colors.orange,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: Colors.orange,
                        overlayColor: Colors.orange.withValues(alpha: 0.20),
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
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
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

              const SizedBox(height: 12),

              // Control buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    _buildFullPlayerControlIcon(
                      icon: _isShuffle
                          ? Icons.shuffle_on_rounded
                          : Icons.shuffle_rounded,
                      isActive: _isShuffle,
                      onTap: _toggleShuffle,
                      size: 24,
                    ),

                    // Previous
                    _buildFullPlayerControlIcon(
                      icon: Icons.skip_previous_rounded,
                      color: _currentIndex > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      onTap: _currentIndex > 0 ? _playPrevious : null,
                      size: 32,
                    ),

                    // Play/Pause
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    // Next
                    _buildFullPlayerControlIcon(
                      icon: Icons.skip_next_rounded,
                      color: Colors.white,
                      onTap: _playNext,
                      size: 32,
                    ),

                    // Repeat
                    _buildFullPlayerControlIcon(
                      icon: _repeatMode == RepeatMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      isActive: _repeatMode != RepeatMode.off,
                      onTap: _toggleRepeat,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullPlayerControlIcon({
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
    bool isActive = false,
    double size = 26,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.orange.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? Colors.orange.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isActive
              ? Colors.orange
              : color ?? Colors.white.withValues(alpha: 0.75),
          size: size,
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
    final cached = ThumbnailService.getCachedAudioThumbnail(widget.audioPath);
    if (cached != null ||
        ThumbnailService.hasCachedAudioThumbnail(widget.audioPath)) {
      _thumbnailData = cached;
      _isLoading = false;
    } else {
      _loadThumbnail();
    }
  }

  @override
  void didUpdateWidget(AudioThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      final cached = ThumbnailService.getCachedAudioThumbnail(widget.audioPath);
      if (cached != null ||
          ThumbnailService.hasCachedAudioThumbnail(widget.audioPath)) {
        _thumbnailData = cached;
        _isLoading = false;
      } else {
        _isLoading = true;
        _loadThumbnail();
      }
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
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withValues(alpha: 0.25),
              Colors.orange.withValues(alpha: 0.08),
              const Color(0xFF181818),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.orange,
          size: widget.size * 0.5,
        ),
      );
    }

    if (_thumbnailData != null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: ResizeImage(
              MemoryImage(_thumbnailData!),
              width: (widget.size * 2).toInt(),
              height: (widget.size * 2).toInt(),
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: widget.showPlayIcon
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.orange,
                  size: widget.size * 0.55,
                ),
              )
            : null,
      );
    }

    // Fallback to warm amber glass background
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.28),
            Colors.orange.withValues(alpha: 0.10),
            const Color(0xFF161616),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Icon(
        widget.showPlayIcon
            ? Icons.play_arrow_rounded
            : Icons.music_note_rounded,
        color: Colors.orange,
        size: widget.size * 0.5,
      ),
    );
  }
}
