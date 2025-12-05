class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> mediaIds; // List of media item IDs

  Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.mediaIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'mediaIds': mediaIds,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mediaIds: List<String>.from(json['mediaIds'] as List),
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? mediaIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      mediaIds: mediaIds ?? this.mediaIds,
    );
  }
}
