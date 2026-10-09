import 'dart:ui';
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
import '../services/playback_history_service.dart';
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
    if (last != null && last['item'] != null) {
      try {
        final item = MediaItem.fromJson(
          Map<String, dynamic>.from(last['item']),
        );
        _playbackManager.updateCurrentlyPlaying(item);
        return;
      } catch (e) {
        // Error loading last played song
      }
    }

    // Fallback: Check playback history so last played video or song appears
    try {
      await PlaybackHistoryService().initialize();
      if (PlaybackHistoryService().history.isNotEmpty) {
        _playbackManager.updateCurrentlyPlaying(
          PlaybackHistoryService().history.first,
        );
      }
    } catch (_) {}
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
    if (_selectedDrawerIndex == 2 && index != 2) {
      VideoPlayerScreen.activeState?.pauseVideo();
      PlaybackManager().setFullVideoActive(false);
    }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_selectedDrawerIndex != 0) {
            // If not on home dashboard, go back to home
            if (_selectedDrawerIndex == 2) {
              VideoPlayerScreen.activeState?.pauseVideo();
              PlaybackManager().setFullVideoActive(false);
            }
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
        drawerScrimColor: Colors.black.withValues(alpha: 0.45),
        extendBodyBehindAppBar: true,
        appBar: _VibeWaveAppBar(
          selectedIndex: _selectedDrawerIndex,
          isSearching: _isSearching,
          searchController: _searchController,
          searchQuery: _searchQuery,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          onSearchToggle: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = '';
            }
          }),
          onClearBookmarks: () => _showClearBookmarksDialog(context),
          onClearFavorites: () => _showClearFavoritesDialog(context),
          onClearQueue: () => _showClearQueueDialog(context),
          onDeletePlaylists: () => _showDeleteAllPlaylistsDialog(context),
        ),
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(6, 0),
                  ),
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(28),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414).withValues(alpha: 0.76),
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.2,
                        ),
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildDrawerHeader(),
                        const SizedBox(height: 6),
                        _buildDrawerItem(
                          icon: Icons.home_rounded,
                          title: 'Home',
                          isSelected: _selectedDrawerIndex == 0,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(0);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.library_music_rounded,
                          title: 'My Music',
                          isSelected: _selectedDrawerIndex == 1,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(1);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.video_library_rounded,
                          title: 'My Videos',
                          isSelected: _selectedDrawerIndex == 2,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(2);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.graphic_eq_rounded,
                          title: 'Sound Effects',
                          isSelected: _selectedDrawerIndex == 3,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(3);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.bookmark_rounded,
                          title: 'Bookmarks',
                          isSelected: _selectedDrawerIndex == 4,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(4);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.favorite_rounded,
                          title: 'Favorites',
                          isSelected: _selectedDrawerIndex == 5,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(5);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.queue_music_rounded,
                          title: 'Queue',
                          isSelected: _selectedDrawerIndex == 6,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(6);
                          },
                        ),
                        _buildDrawerDivider(),
                        _buildDrawerSectionTitle('PLAYLISTS'),
                        _buildDrawerItem(
                          icon: Icons.playlist_play_rounded,
                          title: 'Playlists',
                          trailing: Icons.arrow_forward_ios_rounded,
                          isOrange: true,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(7);
                          },
                        ),
                        _buildDrawerDivider(),
                        _buildDrawerItem(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          isSelected: _selectedDrawerIndex == 8,
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToScreen(8);
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
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
          index: _selectedDrawerIndex,
          children: List.generate(
            _screens.length,
            (i) => _wrapScreen(i, _screens[i]),
          ),
        ),
      ),
    );
  }

  Widget _wrapScreen(int index, Widget screen) {
    if (index == 0) return screen;
    return Builder(
      builder: (context) {
        final double topPadding =
            MediaQuery.of(context).padding.top + kToolbarHeight + 8;
        return Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: screen,
        );
      },
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 3D Crystal Logo Badge
              SizedBox(
                width: 50,
                height: 50,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VibeWave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Media Player',
                      style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Version badge with subtle crystal glass pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                const SizedBox(width: 6),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.60),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
    final bool active = isSelected || isOrange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF241C16).withValues(alpha: 0.85)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.orange.withValues(alpha: 0.45)
              : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.orange.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // 3D Crystal Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.orange.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: active
                          ? Colors.orange.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.09),
                      width: 1.0,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: active
                        ? Colors.orange
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: active
                          ? Colors.orange
                          : Colors.white.withValues(alpha: 0.90),
                      fontSize: 14.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                // Trailing
                if (isSelected)
                  Container(
                    width: 6,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.60),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                else if (trailing != null)
                  Icon(
                    trailing,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VibeWave Custom Floating Glass AppBar
// Modelled after the deptx_app CustomAppBar design:
//  • Floating pill container with 28px radius
//  • BackdropFilter blur (glassmorphism) — elevated on scroll
//  • Home tab: logo + two-line "Welcome to VibeWave" greeting
//  • Other tabs: centered title + menu button left + action pills right
//  • Action pills: search / overflow in rounded icon containers
// ─────────────────────────────────────────────────────────────────────────────
class _VibeWaveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final bool isSearching;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchToggle;
  final VoidCallback onClearBookmarks;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearQueue;
  final VoidCallback onDeletePlaylists;

  // Whether we show the search / overflow actions
  bool get _hasActions =>
      selectedIndex == 4 ||
      selectedIndex == 5 ||
      selectedIndex == 6 ||
      selectedIndex == 7;

  const _VibeWaveAppBar({
    required this.selectedIndex,
    required this.isSearching,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchToggle,
    required this.onClearBookmarks,
    required this.onClearFavorites,
    required this.onClearQueue,
    required this.onDeletePlaylists,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  String _titleFor(int index) {
    switch (index) {
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
        return 'VibeWave';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Frosted Crystal Glass Status Bar overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: statusBarHeight,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414).withValues(alpha: 0.50),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Floating Glass App Bar Pill
        Padding(
          padding: EdgeInsets.only(
            top: statusBarHeight + 4,
            left: 12,
            right: 12,
            bottom: 4,
          ),
          child: Container(
            height: kToolbarHeight - 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.06),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  height: kToolbarHeight - 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.85),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: selectedIndex == 0 && !isSearching
                      ? _buildHomeHeader(context)
                      : _buildStandardHeader(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Home tab: logo + Welcome to VibeWave greeting ──
  Widget _buildHomeHeader(BuildContext context) {
    return Row(
      children: [
        // Menu button
        Builder(
          builder: (ctx) => _ActionPill(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Logo + greeting text
        Image.asset('assets/images/logo.png', width: 34, height: 34),
        const SizedBox(width: 10),
        const Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Welcome to VibeWave',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Text('🎵', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Standard tab: menu left | centered title | action pills right ──
  Widget _buildStandardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: menu button (fixed width for balance)
        SizedBox(
          width: 82,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (ctx) => _ActionPill(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Center: search field or title
        Expanded(
          child: isSearching && _hasActions
              ? TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: selectedIndex == 4
                        ? 'Search bookmarks...'
                        : selectedIndex == 5
                        ? 'Search favorites...'
                        : selectedIndex == 6
                        ? 'Search queue...'
                        : 'Search playlists...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onSearchChanged,
                )
              : Text(
                  _titleFor(selectedIndex),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
        ),

        // Right: action pills (fixed width for balance)
        SizedBox(
          width: 82,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasActions) ...[
                _ActionPill(
                  onTap: onSearchToggle,
                  child: Icon(
                    isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (_hasActions)
                _OverflowPill(
                  selectedIndex: selectedIndex,
                  onClearBookmarks: onClearBookmarks,
                  onClearFavorites: onClearFavorites,
                  onClearQueue: onClearQueue,
                  onDeletePlaylists: onDeletePlaylists,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Rounded icon pill button (matches deptx _buildActionPill) ──────────────
class _ActionPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ActionPill({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
        child: Center(child: child),
      ),
    );
  }
}

// ── Overflow action pill (⋮ menu) ────────────────────────────────────────────
class _OverflowPill extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onClearBookmarks;
  final VoidCallback onClearFavorites;
  final VoidCallback onClearQueue;
  final VoidCallback onDeletePlaylists;

  const _OverflowPill({
    required this.selectedIndex,
    required this.onClearBookmarks,
    required this.onClearFavorites,
    required this.onClearQueue,
    required this.onDeletePlaylists,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Container(
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
        child: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
          size: 19,
        ),
      ),
      color: const Color(0xFF2a2a2a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        switch (value) {
          case 'clear_bookmarks':
            onClearBookmarks();
            break;
          case 'clear_favorites':
            onClearFavorites();
            break;
          case 'clear_queue':
            onClearQueue();
            break;
          case 'delete_playlists':
            onDeletePlaylists();
            break;
        }
      },
      itemBuilder: (_) {
        if (selectedIndex == 4) {
          return [
            _menuItem(
              'clear_bookmarks',
              Icons.delete_outline,
              'Clear all bookmarks',
            ),
          ];
        } else if (selectedIndex == 5) {
          return [
            _menuItem(
              'clear_favorites',
              Icons.delete_outline,
              'Clear all favorites',
            ),
          ];
        } else if (selectedIndex == 6) {
          return [
            _menuItem('clear_queue', Icons.delete_outline, 'Clear queue'),
          ];
        } else {
          return [
            _menuItem(
              'delete_playlists',
              Icons.delete_sweep,
              'Delete all playlists',
            ),
          ];
        }
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
