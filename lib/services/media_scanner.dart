import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/folder_item.dart';
import 'thumbnail_service.dart';

class MediaScanner {
  static const platform = MethodChannel('com.example.media_player_app/storage');
  static bool _isRequestingPermissions = false;
  static bool? _hasPermissions;
  static List<FolderItem>? _cachedAudioFolders;
  static List<FolderItem>? _cachedVideoFolders;
  static const String _audioCacheKey = 'cached_audio_folders_v3';
  static const String _videoCacheKey = 'cached_video_folders_v3';
  static const String _lastScanTimeKey = 'last_scan_time';

  static final List<String> _audioExtensions = [
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wma',
    '.alac',
    '.aiff',
    '.mid',
    '.midi',
    '.amr',
    '.m4b',
    '.m4p',
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
    '.ts',
    '.mpg',
    '.mpeg',
    '.vob',
    '.ogv',
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
        // Request storage for Android <= 12 and media permissions for Android >= 13
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.audio,
          Permission.videos,
        ].request();

        _hasPermissions = (statuses[Permission.storage]?.isGranted ?? false) ||
            ((statuses[Permission.audio]?.isGranted ?? false) &&
                (statuses[Permission.videos]?.isGranted ?? false));
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

  static Future<List<FolderItem>> scanAudioFiles({
    bool forceRescan = false,
  }) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    // Return cached data if available and not forcing rescan
    if (!forceRescan && _cachedAudioFolders != null) {
      return _cachedAudioFolders!;
    }

    // Try to load from persistent storage
    if (!forceRescan) {
      final cached = await _loadCachedFolders(_audioCacheKey);
      if (cached != null && cached.isNotEmpty) {
        _cachedAudioFolders = cached;
        return cached;
      }
    }

    // Perform scan
    final folders = await _scanMediaFiles(MediaType.audio);
    _cachedAudioFolders = folders;

    // Save to cache
    await _saveCachedFolders(_audioCacheKey, folders);

    return folders;
  }

  static Future<List<FolderItem>> scanVideoFiles({
    bool forceRescan = false,
  }) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    // Return cached data if available and not forcing rescan
    if (!forceRescan && _cachedVideoFolders != null) {
      return _cachedVideoFolders!;
    }

    // Try to load from persistent storage
    if (!forceRescan) {
      final cached = await _loadCachedFolders(_videoCacheKey);
      if (cached != null && cached.isNotEmpty) {
        _cachedVideoFolders = cached;
        return cached;
      }
    }

    // Perform scan
    final folders = await _scanMediaFiles(MediaType.video);
    _cachedVideoFolders = folders;

    // Save to cache
    await _saveCachedFolders(_videoCacheKey, folders);

    return folders;
  }

  static Future<void> clearCache() async {
    _cachedAudioFolders = null;
    _cachedVideoFolders = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_audio_folders');
    await prefs.remove('cached_video_folders');
    await prefs.remove('cached_audio_folders_v2');
    await prefs.remove('cached_video_folders_v2');
    await prefs.remove(_audioCacheKey);
    await prefs.remove(_videoCacheKey);
    await prefs.remove(_lastScanTimeKey);
  }

  static Future<void> _saveCachedFolders(
    String key,
    List<FolderItem> folders,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = folders
          .map(
            (folder) => {
              'name': folder.name,
              'path': folder.path,
              'mediaFiles': folder.mediaFiles
                  .map((media) => media.toJson())
                  .toList(),
            },
          )
          .toList();
      await prefs.setString(key, json.encode(jsonData));
      await prefs.setInt(
        _lastScanTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silently handle cache save errors
    }
  }

  static Future<List<FolderItem>?> _loadCachedFolders(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final List<dynamic> jsonData = json.decode(jsonString);
      final folders = jsonData
          .map(
            (folderJson) => FolderItem(
              name: folderJson['name'] as String,
              path: folderJson['path'] as String,
              mediaFiles: (folderJson['mediaFiles'] as List)
                  .map((mediaJson) => MediaItem.fromJson(mediaJson))
                  .toList(),
            ),
          )
          .toList();

      // Deduplicate files inside each folder in case old cache had duplicates
      for (var folder in folders) {
        final seenInFolder = <String>{};
        folder.mediaFiles.removeWhere((item) => !seenInFolder.add(item.path));
      }

      return folders.where((folder) => folder.fileCount > 0).toList();
    } catch (e) {
      // If cache is corrupted, return null to trigger rescan
      return null;
    }
  }

  static String _getCanonicalPath(String rawPath) {
    try {
      return File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {
      try {
        return Directory(rawPath).resolveSymbolicLinksSync();
      } catch (_) {
        return p.canonicalize(rawPath);
      }
    }
  }

  static Future<List<FolderItem>> _scanMediaFiles(MediaType type) async {
    final Map<String, List<MediaItem>> folderMap = {};
    final Set<String> seenFilePaths = {};
    final Set<String> visitedDirs = {};

    final extensions = type == MediaType.audio
        ? _audioExtensions
        : _videoExtensions;

    try {
      final directories = await _getMediaDirectories();
      for (var dir in directories) {
        if (await dir.exists()) {
          await _scanDirectory(
            dir,
            folderMap,
            seenFilePaths,
            visitedDirs,
            extensions,
            type,
          );
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
    final Set<String> uniquePaths = {};
    final List<Directory> directories = [];

    void addDir(String path) {
      final canonical = _getCanonicalPath(path);
      if (uniquePaths.add(canonical)) {
        directories.add(Directory(canonical));
      }
    }

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
            addDir('$path/Music');
            addDir('$path/Download');
            addDir('$path/Downloads');
            addDir('$path/Movies');
            addDir('$path/DCIM');
            addDir('$path/Video');
            addDir('$path/Videos');
            addDir('$path/Audio');
            addDir('$path/Podcasts');
            addDir(path); // Root of storage volume
          }
        }
      } catch (e) {
        // Fallback to default internal storage if native method fails
        final externalStorage = Directory('/storage/emulated/0');
        if (await externalStorage.exists()) {
          addDir('${externalStorage.path}/Music');
          addDir('${externalStorage.path}/Download');
          addDir('${externalStorage.path}/Downloads');
          addDir('${externalStorage.path}/Movies');
          addDir('${externalStorage.path}/DCIM');
          addDir('${externalStorage.path}/Video');
          addDir('${externalStorage.path}/Videos');
          addDir('${externalStorage.path}/Audio');
          addDir('${externalStorage.path}/Podcasts');
          addDir(externalStorage.path);
        }
      }
    }
    return directories;
  }

  static Future<void> _scanDirectory(
    Directory dir,
    Map<String, List<MediaItem>> folderMap,
    Set<String> seenFilePaths,
    Set<String> visitedDirs,
    List<String> extensions,
    MediaType type,
  ) async {
    final canonicalDirPath = _getCanonicalPath(dir.path);
    if (!visitedDirs.add(canonicalDirPath)) {
      return; // Already visited this directory
    }

    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (extensions.contains(ext)) {
            final canonicalFilePath = _getCanonicalPath(entity.path);
            if (!seenFilePaths.add(canonicalFilePath)) {
              continue; // Already processed this file
            }

            final folderPath = p.normalize(p.dirname(canonicalFilePath));
            final title = p.basenameWithoutExtension(canonicalFilePath);

            // Generate thumbnail path based on media type
            String? thumbnailPath;
            if (type == MediaType.audio) {
              thumbnailPath = await ThumbnailService.getAudioThumbnailPath(
                canonicalFilePath,
              );
            } else {
              thumbnailPath = await ThumbnailService.getVideoThumbnail(
                canonicalFilePath,
              );
            }

            final mediaItem = MediaItem(
              id: canonicalFilePath,
              title: title,
              path: canonicalFilePath,
              type: type,
              artist: _extractArtistFromPath(canonicalFilePath),
              album: p.basename(folderPath),
              thumbnailPath: thumbnailPath,
            );

            folderMap.putIfAbsent(folderPath, () => []);
            if (!folderMap[folderPath]!.any((item) => item.path == canonicalFilePath)) {
              folderMap[folderPath]!.add(mediaItem);
            }
          }
        } else if (entity is Directory) {
          final canonicalSubdir = _getCanonicalPath(entity.path);
          if (visitedDirs.contains(canonicalSubdir)) {
            continue; // Already scanned or queued
          }
          final dirName = p.basename(entity.path).toLowerCase();
          if (!dirName.startsWith('.') &&
              dirName != 'android' &&
              dirName != 'data') {
            await _scanDirectory(
              entity,
              folderMap,
              seenFilePaths,
              visitedDirs,
              extensions,
              type,
            );
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
    final parts = path.replaceAll(r'\', '/').split('/');
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
