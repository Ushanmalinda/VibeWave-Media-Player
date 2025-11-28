import 'media_item.dart';

class FolderItem {
  final String name;
  final String path;
  final List<MediaItem> mediaFiles;
  final int fileCount;

  FolderItem({required this.name, required this.path, required this.mediaFiles})
    : fileCount = mediaFiles.length;

  bool get isEmpty => mediaFiles.isEmpty;
}
