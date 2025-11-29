import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../models/media_item.dart';
import '../models/folder_item.dart';

class MediaScanner {
  static const platform = MethodChannel('com.example.media_player_app/storage');
  static bool _isRequestingPermissions = false;
  static bool? _hasPermissions;

  static final List<String> _audioExtensions = [
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wma',
  ];

  static final List<String> _videoExtensions = [
    '.mp4',
    '.mkv',
    '.avi',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp',
  ];

  static Future<bool> requestPermissions() async {
    // If already requesting, wait for the current request to complete
    if (_isRequestingPermissions) {
      // Wait for up to 5 seconds for the permission request to complete
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_isRequestingPermissions) {
          return _hasPermissions ?? false;
        }
      }
      return false;
    }

    // If we already have cached permission status, return it
    if (_hasPermissions != null) {
      return _hasPermissions!;
    }

    if (Platform.isAndroid) {
      _isRequestingPermissions = true;
      try {
        // Check current status first
        final storageStatus = await Permission.storage.status;
        final manageStorageStatus =
            await Permission.manageExternalStorage.status;

        if (storageStatus.isGranted || manageStorageStatus.isGranted) {
          _hasPermissions = true;
          return true;
        }

        // Request permissions one at a time to avoid conflicts
        final storage = await Permission.storage.request();
        if (storage.isGranted) {
          _hasPermissions = true;
          return true;
        }

        final manageStorage = await Permission.manageExternalStorage.request();
        _hasPermissions = manageStorage.isGranted;
        return _hasPermissions!;
      } catch (e) {
        // Silently handle permission errors
        _hasPermissions = false;
        return false;
      } finally {
        _isRequestingPermissions = false;
      }
    }

    _hasPermissions = true;
    return true;
  }

  static Future<List<FolderItem>> scanAudioFiles() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];
    return await _scanMediaFiles(MediaType.audio);
  }

  static Future<List<FolderItem>> scanVideoFiles() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];
    return await _scanMediaFiles(MediaType.video);
  }

  static Future<List<FolderItem>> _scanMediaFiles(MediaType type) async {
    final Map<String, List<MediaItem>> folderMap = {};
    final extensions = type == MediaType.audio
        ? _audioExtensions
        : _videoExtensions;

    try {
      final directories = await _getMediaDirectories();
      for (var dir in directories) {
        if (await dir.exists()) {
          await _scanDirectory(dir, folderMap, extensions, type);
        }
      }
    } catch (e) {
      // Silently handle scanning errors
    }

    final folders = folderMap.entries
        .map(
          (entry) => FolderItem(
            name: p.basename(entry.key),
            path: entry.key,
            mediaFiles: entry.value,
          ),
        )
        .where((folder) => folder.fileCount > 0)
        .toList();

    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  }

  static Future<List<Directory>> _getMediaDirectories() async {
    final List<Directory> directories = [];

    if (Platform.isAndroid) {
      // Get all storage paths from native Android code
      try {
        final List<dynamic> storagePaths = await platform.invokeMethod(
          'getStoragePaths',
        );

        for (var storagePath in storagePaths) {
          final path = storagePath.toString();

          final storage = Directory(path);
          if (await storage.exists()) {
            // Add common media directories for each storage volume
            directories.addAll([
              Directory('$path/Music'),
              Directory('$path/Download'),
              Directory('$path/Downloads'),
              Directory('$path/Movies'),
              Directory('$path/DCIM'),
              Directory('$path/Video'),
              Directory('$path/Videos'),
              Directory('$path/Audio'),
              Directory('$path/Podcasts'),
              storage, // Root of storage
            ]);
          }
        }
      } catch (e) {
        // Fallback to default internal storage if native method fails
        final externalStorage = Directory('/storage/emulated/0');
        if (await externalStorage.exists()) {
          directories.addAll([
            Directory('${externalStorage.path}/Music'),
            Directory('${externalStorage.path}/Download'),
            Directory('${externalStorage.path}/Downloads'),
            Directory('${externalStorage.path}/Movies'),
            Directory('${externalStorage.path}/DCIM'),
            Directory('${externalStorage.path}/Video'),
            Directory('${externalStorage.path}/Videos'),
            Directory('${externalStorage.path}/Audio'),
            Directory('${externalStorage.path}/Podcasts'),
            externalStorage,
          ]);
        }
      }
    }
    return directories;
  }

  static Future<void> _scanDirectory(
    Directory dir,
    Map<String, List<MediaItem>> folderMap,
    List<String> extensions,
    MediaType type,
  ) async {
    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (extensions.contains(ext)) {
            final folderPath = p.dirname(entity.path);
            final title = p.basenameWithoutExtension(entity.path);

            final mediaItem = MediaItem(
              id: entity.path,
              title: title,
              path: entity.path,
              type: type,
              artist: _extractArtistFromPath(entity.path),
              album: p.basename(folderPath),
            );

            folderMap.putIfAbsent(folderPath, () => []);
            folderMap[folderPath]!.add(mediaItem);
          }
        } else if (entity is Directory) {
          final dirName = p.basename(entity.path).toLowerCase();
          if (!dirName.startsWith('.') &&
              dirName != 'android' &&
              dirName != 'data') {
            await _scanDirectory(entity, folderMap, extensions, type);
          }
        }
      }
    } on FileSystemException {
      // Skip inaccessible directories (permission denied, etc.)
    } catch (e) {
      // Skip other errors silently
    }
  }

  static String _extractArtistFromPath(String path) {
    final parts = path.split('/');
    if (parts.length >= 3) {
      final musicIndex = parts.indexWhere(
        (p) => p.toLowerCase() == 'music' || p.toLowerCase() == 'audio',
      );
      if (musicIndex >= 0 && musicIndex < parts.length - 2) {
        return parts[musicIndex + 1];
      }
    }
    return 'Unknown Artist';
  }
}
