class MediaItem {
  final String id;
  final String title;
  final String path;
  final MediaType type;
  final Duration? duration;
  final String? artist;
  final String? album;
  final String? thumbnailPath;

  MediaItem({
    required this.id,
    required this.title,
    required this.path,
    required this.type,
    this.duration,
    this.artist,
    this.album,
    this.thumbnailPath,
  });
}

enum MediaType { audio, video }

enum RepeatMode { off, all, one }
