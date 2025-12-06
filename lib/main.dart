import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
