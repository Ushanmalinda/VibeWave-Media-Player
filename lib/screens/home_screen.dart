import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';
import 'audio_player_screen.dart';
import 'video_player_screen.dart';
import 'equalizer_screen.dart';
import 'bookmarks_screen.dart';
import 'favorites_screen.dart';
import 'queue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDrawerIndex = 0;

  // Keep all screens alive to maintain playback state
  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    AudioPlayerScreen(),
    VideoPlayerScreen(),
    EqualizerScreen(),
    BookmarksScreen(),
    FavoritesScreen(),
    QueueScreen(),
  ];

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
      default:
        return 'Media Player';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _getTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2a2a2a),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1a1a1a),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.8),
                    Colors.orange.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Media Player',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PLAYLISTS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Create playlist - Coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit playlists - Coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.playlist_play_rounded,
              title: 'Default',
              trailing: Icons.close_rounded,
              isOrange: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Default playlist'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(
              color: Colors.white24,
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings - Coming soon'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info_outline_rounded,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Media Player v1.0.0'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app_rounded,
              title: 'Exit',
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedDrawerIndex, children: _screens),
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
