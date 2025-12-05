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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'type': type == MediaType.audio ? 'audio' : 'video',
      'duration': duration?.inMilliseconds,
      'artist': artist,
      'album': album,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      type: json['type'] == 'audio' ? MediaType.audio : MediaType.video,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }
}

enum MediaType { audio, video }

enum RepeatMode { off, all, one }
