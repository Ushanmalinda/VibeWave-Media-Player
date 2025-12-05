import 'dart:io';
import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';

class ThumbnailService {
  // Cache for audio thumbnails to prevent reloading
  static final Map<String, Uint8List?> _audioThumbnailCache = {};

  static Future<Uint8List?> getAudioThumbnail(String audioPath) async {
    // Return cached thumbnail if available
    if (_audioThumbnailCache.containsKey(audioPath)) {
      return _audioThumbnailCache[audioPath];
    }

    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        _audioThumbnailCache[audioPath] = null;
        return null;
      }

      // Read audio tags including artwork
      final tag = await AudioTags.read(audioPath);

      if (tag != null && tag.pictures.isNotEmpty) {
        // Cache and return the first picture (album art)
        final thumbnail = tag.pictures.first.bytes;
        _audioThumbnailCache[audioPath] = thumbnail;
        return thumbnail;
      }

      _audioThumbnailCache[audioPath] = null;
      return null;
    } catch (e) {
      // Silently handle errors - some files may have corrupted metadata
      _audioThumbnailCache[audioPath] = null;
      return null;
    }
  }

  static Future<String?> getVideoThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = videoPath
          .split('/')
          .last
          .replaceAll(RegExp(r'[^\w\s]+'), '_');
      final thumbnailPath = '${tempDir.path}/thumb_$fileName.jpg';

      // Check if thumbnail already exists
      if (await File(thumbnailPath).exists()) {
        return thumbnailPath;
      }

      // Generate thumbnail
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 75,
      );

      return thumbnail;
    } catch (e) {
      // Silently handle errors - some files may have corrupted metadata
      return null;
    }
  }
}
