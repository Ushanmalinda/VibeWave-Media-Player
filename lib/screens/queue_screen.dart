import 'package:flutter/material.dart';
import '../services/queue_service.dart';
import '../models/media_item.dart';
import 'dart:typed_data';
import '../services/thumbnail_service.dart';

class QueueScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const QueueScreen({super.key, this.onNavigate});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final QueueService _queueService = QueueService();

  @override
  void initState() {
    super.initState();
    _queueService.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    _queueService.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queueService.queue;
    final currentIndex = _queueService.currentIndex;
    final audioQueue = queue
        .where((item) => item.type == MediaType.audio)
        .toList();
    final videoQueue = queue
        .where((item) => item.type == MediaType.video)
        .toList();

    if (queue.isEmpty) {
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.queue_music_rounded,
                  size: 100,
                  color: Colors.purple.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Queue is Empty',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Play some music to see\\nyour queue here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onNavigate?.call(1);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Playing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Queue info header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.purple.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.queue_music_rounded,
                color: Colors.purple,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Now Playing Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${queue.length} items (${audioQueue.length} music, ${videoQueue.length} videos)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Queue list with sections
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Audio Section
              if (audioQueue.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Music (${audioQueue.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...queue
                    .asMap()
                    .entries
                    .where((entry) => entry.value.type == MediaType.audio)
                    .map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isCurrentlyPlaying = index == currentIndex;
                      return _buildQueueItem(item, index, isCurrentlyPlaying);
                    }),
                const SizedBox(height: 24),
              ],
              // Video Section
              if (videoQueue.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Videos (${videoQueue.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...queue
                    .asMap()
                    .entries
                    .where((entry) => entry.value.type == MediaType.video)
                    .map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isCurrentlyPlaying = index == currentIndex;
                      return _buildQueueItem(item, index, isCurrentlyPlaying);
                    }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem(MediaItem item, int index, bool isCurrentlyPlaying) {
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      color: isCurrentlyPlaying
          ? Colors.purple.withOpacity(0.2)
          : const Color(0xFF2a2a2a),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            _buildThumbnail(item),
            if (isCurrentlyPlaying)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (isCurrentlyPlaying)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: isCurrentlyPlaying ? Colors.purple : Colors.white,
                  fontWeight: isCurrentlyPlaying
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          item.artist ?? 'Unknown Artist',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () {
                _queueService.removeFromQueue(index);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from queue'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.type == MediaType.audio) {
      return FutureBuilder<Uint8List?>(
        future: ThumbnailService.getAudioThumbnail(item.path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                snapshot.data!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            );
          }
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.purple,
              size: 28,
            ),
          );
        },
      );
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.blue, size: 28),
    );
  }
}
