# VibeWave Player 🎵

A feature-rich Flutter media player inspired by AIMP, offering professional audio/video playback with advanced gesture controls and hardware integration.

![Version](https://img.shields.io/badge/version-1.0.0-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue)
![Platform](https://img.shields.io/badge/platform-Android-green)

## ✨ Key Features

### 🎵 Audio Player
- **Auto-Scan on Startup**: Automatically finds all audio files
- **Folder-Based Navigation**: Browse music organized by folders
- **Format Support**: MP3, M4A, WAV, FLAC, AAC, OGG, OPUS, WMA
- **Advanced Controls**: Shuffle, repeat modes, seek, previous/next
- **Mini Player**: Persistent bottom player for quick access
- **Full Player Modal**: Beautiful full-screen player with album art
- **Queue Management**: View and reorder playback queue
- **Bookmarks & Favorites**: Quick access to preferred tracks

### 🎬 Video Player
- **Auto-Scan**: Automatically finds all video files
- **Format Support**: MP4, MKV, AVI, MOV, WMV, FLV, WEBM, M4V, 3GP
- **Full Controls**: Play, pause, skip, seek
- **Tap to Toggle**: Show/hide controls

### 🎛️ Equalizer
- **10-Band Equalizer**: Fine-tune audio frequencies
- **Presets**: Rock, Pop, Jazz, Classical, Bass Boost, and more
- **Bass Boost**: Enhance low frequencies
- **Virtualization**: Spatial audio effect

### 🎮 Gesture Controls
- **Horizontal Swipe**: Previous/Next track
- **Vertical Swipe**: Volume control
- **Double Tap Left**: Rewind 10 seconds
- **Double Tap Right**: Fast forward 10 seconds
- **Double Tap Center**: Play/Pause
- **All customizable** in Settings

### 📳 Hardware Controls
- **Volume Buttons**: Double-tap to switch tracks
- **Shake Detection**: Shake phone left for previous, right for next (adjustable sensitivity)
- **Headset Controls**: Single/double/triple tap actions
- **Auto-pause**: When volume reaches zero or headset unplugged

### 📚 Organization
- **Playlists**: Create and manage custom playlists
- **Bookmarks**: Quick access to specific tracks
- **Favorites**: Mark and access loved tracks easily
- **Queue**: View and reorder upcoming tracks

### ⚙️ Settings
- Comprehensive control customization
- Gesture configuration
- Hardware control settings
- Reset to defaults option

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Android SDK (API 33+)
- Android device or emulator

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Ushanmalinda/flutter-media-player.git
cd flutter-media-player
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

## 📱 Usage Guide

### Audio Player
1. Open app → automatically scans for audio files
2. Tap any folder to browse songs
3. Tap a song to start playing
4. Use mini player for quick controls
5. Tap mini player for full-screen view
6. Use gestures on album art (swipe, double-tap)

### Gesture Controls (on Audio Player)
- **Swipe horizontally**: Skip tracks
- **Swipe vertically**: Adjust volume
- **Double tap left**: Rewind 10s
- **Double tap right**: Forward 10s
- **Double tap center**: Play/Pause

### Hardware Controls
1. Go to **Settings** from side panel
2. Configure:
   - Volume button double-tap to switch tracks
   - Shake to skip (left/right direction)
   - Headset button actions
3. All controls are customizable

### Playlists
1. Tap **Playlists** from side panel
2. Tap **+** to create new playlist
3. Add songs from any folder
4. Reorder, rename, or delete playlists

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2
- **Audio**: just_audio, audio_session
- **Video**: video_player
- **Sensors**: sensors_plus (shake detection)
- **Storage**: shared_preferences, path_provider
- **UI**: Material Design 3
- **State Management**: Provider pattern

## 📂 Project Structure

```
lib/
├── models/          # Data models (MediaItem, Playlist)
├── screens/         # UI screens
│   ├── home_screen.dart
│   ├── audio_player_screen.dart
│   ├── video_player_screen.dart
│   ├── equalizer_screen.dart
│   ├── playlists_screen.dart
│   ├── settings_screen.dart
│   └── about_screen.dart
├── services/        # Business logic
│   ├── audio_player_service.dart
│   ├── queue_service.dart
│   ├── playlist_service.dart
│   ├── settings_service.dart
│   ├── controls_manager.dart
│   └── equalizer_service.dart
├── widgets/         # Reusable components
└── main.dart        # App entry point
```

## 🎨 Customization

### Change App Logo
1. Place your logo in `assets/images/logo.png`
2. Run `flutter pub run flutter_launcher_icons`
3. See `LOGO_INSTALLATION.md` for details

### Modify Gesture Actions
1. Open **Settings** in app
2. Go to **Gestures** section
3. Tap any gesture to change its action

### Reset All Settings
1. Open **Settings**
2. Scroll to bottom
3. Tap **Reset All Settings to Default**

## 📄 Documentation

- **BRANDING_BRIEF.md** - Logo design guide and app naming
- **LOGO_INSTALLATION.md** - How to add/change app logo
- **CONTROLS_TESTING_GUIDE.md** - Testing hardware controls

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 👤 Author

**Ushan Malinda**
- GitHub: [@Ushanmalinda](https://github.com/Ushanmalinda)

## 🙏 Acknowledgments

- Inspired by AIMP Player
- Flutter community packages
- Material Design guidelines

---

