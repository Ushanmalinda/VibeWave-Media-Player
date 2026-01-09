import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_dashboard_screen.dart';
import 'audio_player_screen.dart';
import 'video_player_screen.dart';
import 'equalizer_screen.dart';
import 'bookmarks_screen.dart';
import 'favorites_screen.dart';
import 'playlists_screen.dart';
import 'queue_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import '../services/favorites_service.dart';
import '../services/queue_service.dart';
import '../services/bookmarks_service.dart';
import '../services/playlist_service.dart';
import '../services/last_played_service.dart';
import '../services/playback_manager.dart';
import '../models/media_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDrawerIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _lastBackPressed;
  final PlaybackManager _playbackManager = PlaybackManager();

  @override
  void initState() {
    super.initState();
    _loadLastPlayedSong();
  }

  Future<void> _loadLastPlayedSong() async {
    final last = await LastPlayedService.loadLastPlayed();
    if (last != null) {
      try {
        final item = MediaItem.fromJson(
          Map<String, dynamic>.from(last['item']),
        );
        // Update PlaybackManager so MiniPlayer can show the last played song
        _playbackManager.updateCurrentlyPlaying(item);
      } catch (e) {
        // Error loading last played song
      }
    }
  }

  // Keep all screens alive to maintain playback state
  List<Widget> get _screens => [
    HomeDashboardScreen(onNavigate: _navigateToScreen),
    const AudioPlayerScreen(),
    const VideoPlayerScreen(),
    const EqualizerScreen(),
    BookmarksScreen(searchQuery: _searchQuery),
    FavoritesScreen(onNavigate: _navigateToScreen, searchQuery: _searchQuery),
    QueueScreen(onNavigate: _navigateToScreen, searchQuery: _searchQuery),
    PlaylistsScreen(onNavigate: _navigateToScreen, searchQuery: _searchQuery),
    const SettingsScreen(),
  ];

  void _navigateToScreen(int index) {
    setState(() {
      _selectedDrawerIndex = index;
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _showClearBookmarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Clear All Bookmarks?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will remove all bookmarked items. This action cannot be undone.',
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
              await BookmarksService().clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All bookmarks cleared'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearFavoritesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Clear All Favorites?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will remove all songs from your favorites. This action cannot be undone.',
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
              await FavoritesService().clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All favorites cleared'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearQueueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Clear Queue?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will remove all songs from the queue. This action cannot be undone.',
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
            onPressed: () {
              QueueService().clearQueue();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Queue cleared'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Clear Queue',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllPlaylistsDialog(BuildContext context) async {
    final playlistService = PlaylistService();
    await playlistService.initialize();
    final playlists = playlistService.playlists;

    if (playlists.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No playlists to delete'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: const Text(
            'Delete All Playlists?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will delete ${playlists.length} playlists. This action cannot be undone.',
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
                for (final p in List.of(playlists)) {
                  await playlistService.deletePlaylist(p.id);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All playlists deleted'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getTitle() {
    switch (_selectedDrawerIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'My Music';
      case 2:
        return 'My Videos';
      case 3:
        return 'Sound Effects';
      case 4:
        return 'Bookmarks';
      case 5:
        return 'Favorites';
      case 6:
        return 'Queue';
      case 7:
        return 'Playlists';
      case 8:
        return 'Settings';
      default:
        return 'Media Player';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_selectedDrawerIndex != 0) {
            // If not on home dashboard, go back to home
            setState(() {
              _selectedDrawerIndex = 0;
            });
          } else {
            // If on home dashboard, check for double back press to minimize
            final now = DateTime.now();
            final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
                _lastBackPressed == null ||
                now.difference(_lastBackPressed!) > const Duration(seconds: 2);

            if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Press back again to minimize app',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.grey[850],
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            } else {
              // Double back press detected - minimize app
              const platform = MethodChannel('android/back/pressed');
              try {
                await platform.invokeMethod('moveTaskToBack');
              } catch (e) {
                // Fallback
                SystemNavigator.pop();
              }
            }
          }
        }
      },
      child: Scaffold(
        drawerEnableOpenDragGesture: false,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title:
              _isSearching &&
                  (_selectedDrawerIndex == 4 ||
                      _selectedDrawerIndex == 5 ||
                      _selectedDrawerIndex == 6 ||
                      _selectedDrawerIndex == 7)
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _selectedDrawerIndex == 4
                        ? 'Search bookmarks...'
                        : _selectedDrawerIndex == 5
                        ? 'Search favorites...'
                        : _selectedDrawerIndex == 6
                        ? 'Search queue...'
                        : 'Search playlists...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
          backgroundColor: const Color(0xFF2a2a2a),
          elevation: 0,
          actions: [
            if (_selectedDrawerIndex == 4 ||
                _selectedDrawerIndex == 5 ||
                _selectedDrawerIndex == 6 ||
                _selectedDrawerIndex == 7)
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
            if (_selectedDrawerIndex == 4)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: const Color(0xFF2a2a2a),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearBookmarksDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear all bookmarks',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (_selectedDrawerIndex == 5)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: const Color(0xFF2a2a2a),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    _showClearFavoritesDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear all favorites',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (_selectedDrawerIndex == 6)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: const Color(0xFF2a2a2a),
                onSelected: (value) {
                  if (value == 'clear_queue') {
                    _showClearQueueDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_queue',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear queue',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (_selectedDrawerIndex == 7)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: const Color(0xFF2a2a2a),
                onSelected: (value) {
                  if (value == 'delete_all') {
                    _showDeleteAllPlaylistsDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete all playlists',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF1a1a1a),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF1a1a1a)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VibeWave Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.home_rounded,
                title: 'Home',
                isSelected: _selectedDrawerIndex == 0,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 0);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.library_music_rounded,
                title: 'My Music',
                isSelected: _selectedDrawerIndex == 1,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 1);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.video_library_rounded,
                title: 'My Videos',
                isSelected: _selectedDrawerIndex == 2,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 2);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.graphic_eq_rounded,
                title: 'Sound Effects',
                isSelected: _selectedDrawerIndex == 3,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 3);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.bookmark_rounded,
                title: 'Bookmarks',
                isSelected: _selectedDrawerIndex == 4,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 4);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.favorite_rounded,
                title: 'Favorites',
                isSelected: _selectedDrawerIndex == 5,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 5);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.queue_music_rounded,
                title: 'Queue',
                isSelected: _selectedDrawerIndex == 6,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 6);
                  Navigator.pop(context);
                },
              ),
              const Divider(
                color: Colors.white24,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text(
                  'PLAYLISTS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.playlist_play_rounded,
                title: 'Playlists',
                trailing: Icons.arrow_forward_ios,
                isOrange: true,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedDrawerIndex = 7;
                    _isSearching = false;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 16),
              const Divider(
                color: Colors.white24,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              _buildDrawerItem(
                icon: Icons.settings_rounded,
                title: 'Settings',
                isSelected: _selectedDrawerIndex == 8,
                onTap: () {
                  setState(() => _selectedDrawerIndex = 8);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.info_outline_rounded,
                title: 'About',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(index: _selectedDrawerIndex, children: _screens),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    IconData? trailing,
    bool isSelected = false,
    bool isOrange = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected || isOrange
            ? Colors.orange
            : Colors.white.withOpacity(0.8),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected || isOrange
              ? Colors.orange
              : Colors.white.withOpacity(0.9),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 15,
        ),
      ),
      trailing: trailing != null
          ? Icon(trailing, color: Colors.white.withOpacity(0.5), size: 20)
          : null,
      selected: isSelected,
      selectedTileColor: Colors.orange.withOpacity(0.1),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
