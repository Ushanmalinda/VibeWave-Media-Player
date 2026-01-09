import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'services/media_controls_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize for low-end devices
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Request permissions before app starts
  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request only necessary media permissions
  Map<Permission, PermissionStatus> statuses = await [
    Permission.audio,
    Permission.videos,
  ].request();

  // Check if all permissions are granted
  bool allGranted = statuses.values.every((status) => status.isGranted);

  // If any permission is denied, close the app
  if (!allGranted) {
    SystemNavigator.pop(); // Close the app
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Clean up when app is detached or paused
    if (state == AppLifecycleState.detached) {
      _cleanupMediaSession();
    }
  }

  Future<void> _cleanupMediaSession() async {
    try {
      // Pause playback
      await AudioPlayerService().player.pause();
      // Dispose media controls
      await MediaControlsService.dispose();
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeWave Player',
      debugShowCheckedModeBanner: false,
      // Performance optimizations
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2a2a2a),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2a2a2a),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
