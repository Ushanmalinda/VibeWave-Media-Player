import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ThumbnailService {
  // Cache for audio thumbnails to prevent reloading
  static final Map<String, Uint8List?> _audioThumbnailCache = {};
  static final Map<String, String?> _audioThumbnailPathCache = {};
  static final Map<String, Future<Uint8List?>> _audioThumbnailInFlight = {};

  /// Synchronous memory cache query for zero-delay frame-1 rendering
  static Uint8List? getCachedAudioThumbnail(String audioPath) =>
      _audioThumbnailCache[audioPath];

  static bool hasCachedAudioThumbnail(String audioPath) =>
      _audioThumbnailCache.containsKey(audioPath);

  static String? getCachedVideoThumbnail(String videoPath) =>
      _videoThumbnailCache[videoPath];

  static bool hasCachedVideoThumbnail(String videoPath) =>
      _videoThumbnailCache.containsKey(videoPath);

  static Future<Uint8List?> getAudioThumbnail(String audioPath) async {
    // Return cached thumbnail if available
    if (_audioThumbnailCache.containsKey(audioPath)) {
      return _audioThumbnailCache[audioPath];
    }

    // Reuse in-flight request if already loading
    if (_audioThumbnailInFlight.containsKey(audioPath)) {
      return _audioThumbnailInFlight[audioPath]!;
    }

    final future = _loadAudioThumbnail(audioPath);
    _audioThumbnailInFlight[audioPath] = future;

    try {
      final thumbnail = await future;
      if (_audioThumbnailCache.length > 80) {
        _audioThumbnailCache.remove(_audioThumbnailCache.keys.first);
      }
      _audioThumbnailCache[audioPath] = thumbnail;
      return thumbnail;
    } catch (_) {
      _audioThumbnailCache[audioPath] = null;
      return null;
    } finally {
      _audioThumbnailInFlight.remove(audioPath);
    }
  }

  static Future<Uint8List?> _loadAudioThumbnail(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        return null;
      }

      // Read audio metadata in a background isolate to keep the UI thread silky-smooth
      return await Isolate.run(() {
        try {
          final file = File(audioPath);
          if (!file.existsSync()) return null;
          final metadata = readMetadata(file, getImage: true);
          if (metadata.pictures.isNotEmpty) {
            return metadata.pictures.first.bytes;
          }
          return null;
        } catch (_) {
          return null;
        }
      });
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAudioThumbnailPath(String audioPath) async {
    // Return cached path if available
    if (_audioThumbnailPathCache.containsKey(audioPath)) {
      return _audioThumbnailPathCache[audioPath];
    }

    try {
      // Get thumbnail bytes
      final thumbnailBytes = await getAudioThumbnail(audioPath);
      if (thumbnailBytes == null) {
        _audioThumbnailPathCache[audioPath] = null;
        return null;
      }

      // Create a unique filename using hash of the audio path
      final hash = md5.convert(utf8.encode(audioPath)).toString();
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/audio_thumb_$hash.jpg';

      // Check if thumbnail file already exists
      final thumbnailFile = File(thumbnailPath);
      if (!await thumbnailFile.exists()) {
        // Save thumbnail to file
        await thumbnailFile.writeAsBytes(thumbnailBytes);
      }

      _audioThumbnailPathCache[audioPath] = thumbnailPath;
      return thumbnailPath;
    } catch (e) {
      // Silently handle errors
      _audioThumbnailPathCache[audioPath] = null;
      return null;
    }
  }

  // Cache for video thumbnails to prevent repeated JNI decoding attempts
  static final Map<String, String?> _videoThumbnailCache = {};
  static final Map<String, Future<String?>> _videoThumbnailInFlight = {};

  static Future<String?> getVideoThumbnail(String videoPath) async {
    // Return cached thumbnail path (even if null) to avoid spamming native decoders
    if (_videoThumbnailCache.containsKey(videoPath)) {
      return _videoThumbnailCache[videoPath];
    }

    // Reuse in-flight request if already loading
    if (_videoThumbnailInFlight.containsKey(videoPath)) {
      return _videoThumbnailInFlight[videoPath]!;
    }

    final future = _generateVideoThumbnail(videoPath);
    _videoThumbnailInFlight[videoPath] = future;

    try {
      final result = await future;
      _videoThumbnailCache[videoPath] = result;
      return result;
    } catch (_) {
      _videoThumbnailCache[videoPath] = null;
      return null;
    } finally {
      _videoThumbnailInFlight.remove(videoPath);
    }
  }

  static Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        return null;
      }

      final hash = md5.convert(utf8.encode(videoPath)).toString();
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/thumb_$hash.jpg';

      // Check if thumbnail already exists on disk
      if (await File(thumbnailPath).exists()) {
        return thumbnailPath;
      }

      // Generate thumbnail - try at 1000ms (1s) first to avoid missing keyframe at 0ms
      XFile? thumbnail;
      try {
        thumbnail = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: thumbnailPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 200,
          quality: 75,
          timeMs: 1000,
        );
      } catch (_) {
        thumbnail = null;
      }

      // Fallback to 0ms if 1000ms didn't produce a file
      if (thumbnail == null || !await File(thumbnail.path).exists()) {
        try {
          thumbnail = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: thumbnailPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 200,
            quality: 75,
            timeMs: 0,
          );
        } catch (_) {
          thumbnail = null;
        }
      }

      if (thumbnail != null && await File(thumbnail.path).exists()) {
        return thumbnail.path;
      }
      return null;
    } catch (e) {
      // Silently handle errors - some files may have corrupted metadata or unsupported codecs
      return null;
    }
  }
}
