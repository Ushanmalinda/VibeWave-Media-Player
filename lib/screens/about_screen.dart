import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Icon
            Image.asset('assets/images/logo.png', width: 100, height: 100),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'VibeWave Player',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Version
            const Text(
              'v1.0.0 (06.12.2025)',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'arm64-v8a, api33',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            // Developer Info
            _buildSection(
              title: 'Developer',
              items: [_buildInfoItem('Ushan Malinda', null)],
            ),
            const Divider(color: Color(0xFF333333), thickness: 1),
            // Contact Section
            _buildSection(
              title: 'Contact',
              items: [
                _buildInfoItem(
                  'abesinhaushan@gmail.com',
                  'mailto:abesinhaushan@gmail.com',
                  isLink: true,
                ),
                _buildInfoItem(
                  'https://github.com/Ushanmalinda',
                  'https://github.com/Ushanmalinda',
                  isLink: true,
                ),
              ],
            ),
            const Divider(color: Color(0xFF333333), thickness: 1),
            // Features Section
            _buildSection(
              title: 'Features',
              items: [
                _buildFeatureItem('Audio & Video Playback'),
                _buildFeatureItem('Gesture Controls'),
                _buildFeatureItem('Hardware Controls'),
                _buildFeatureItem('Playlist Management'),
                _buildFeatureItem('Equalizer Support'),
              ],
            ),
            const Divider(color: Color(0xFF333333), thickness: 1),
            // Third Party Libraries
            _buildSection(
              title: 'Third party libraries',
              items: [
                _buildLibraryItem('just_audio', '© 2024 Ryan Heise'),
                _buildLibraryItem('video_player', '© 2024 Flutter Team'),
                _buildLibraryItem('audio_session', '© 2024 Ryan Heise'),
                _buildLibraryItem('sensors_plus', '© 2024 Flutter Community'),
                _buildLibraryItem('volume_controller', '© 2024 Yosuke Ota'),
                _buildLibraryItem('file_picker', '© 2024 Miguel Ruivo'),
                _buildLibraryItem('audiotags', '© 2024 Nikos Beredimas'),
              ],
            ),
            const SizedBox(height: 32),
            // Copyright
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '© 2025, Ushan Malinda\nAll rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, String? url, {bool isLink = false}) {
    return GestureDetector(
      onTap: isLink && url != null
          ? () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: isLink ? Colors.orange : Colors.white,
            fontSize: 15,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(
            feature,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryItem(String name, String copyright) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            copyright,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
