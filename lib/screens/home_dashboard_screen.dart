import 'package:flutter/material.dart';
import '../services/playback_manager.dart';
import '../services/media_scanner.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeDashboardScreen({super.key, this.onNavigate});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final PlaybackManager _playbackManager = PlaybackManager();
  int _audioCount = 0;
  int _videoCount = 0;
  int _folderCount = 0;

  @override
  void initState() {
    super.initState();
    _playbackManager.addListener(_onPlaybackChanged);
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

      // Count total files by summing up all mediaFiles in each folder
      int totalAudioFiles = 0;
      for (var folder in audioFolders) {
        totalAudioFiles += folder.mediaFiles.length;
      }

      int totalVideoFiles = 0;
      for (var folder in videoFolders) {
        totalVideoFiles += folder.mediaFiles.length;
      }

      // Total folders
      final totalFolders = audioFolders.length + videoFolders.length;

      if (mounted) {
        setState(() {
          _audioCount = totalAudioFiles;
          _videoCount = totalVideoFiles;
          _folderCount = totalFolders;
        });
      }
    } catch (e) {
      // Error loading media counts
    }
  }

  @override
  void dispose() {
    _playbackManager.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/images/logo.png', width: 60, height: 60),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome to VibeWave Player',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your music and video collection at your fingertips',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick access section
            Text(
              'Quick Access',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.music_note_rounded,
                    title: 'Music',
                    subtitle: 'Browse songs',
                    color: Colors.orange,
                    onTap: () => widget.onNavigate?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.video_library_rounded,
                    title: 'Videos',
                    subtitle: 'Watch videos',
                    color: Colors.blue,
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
                    subtitle: 'Your likes',
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
            const SizedBox(height: 24),

            // Recently played section
            Text(
              'Now Playing',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            MiniPlayer(
              audioPlayer: AudioPlayerService().player,
              onTap: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(height: 24),

            // Statistics section
            Text(
              'Your Library',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2a2a2a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Icons.music_note_rounded,
                    label: 'Total Songs',
                    value: '$_audioCount',
                    color: Colors.orange,
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _buildStatRow(
                    icon: Icons.video_library_rounded,
                    label: 'Total Videos',
                    value: '$_videoCount',
                    color: Colors.blue,
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _buildStatRow(
                    icon: Icons.folder_rounded,
                    label: 'Folders',
                    value: '$_folderCount',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
