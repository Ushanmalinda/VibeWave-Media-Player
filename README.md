# Media Player App

A professional Flutter media player app inspired by AIMP player, featuring **automatic file scanning** with folder-based navigation for audio and video files on Android.

## Features

### 🎵 Professional Audio Player
- **Auto-Scan on Startup**: Automatically finds all audio files when you open the app
- **Folder-Based Navigation**: Browse your music library organized by folders
- **Smart File Detection**: Scans common directories (Music, Downloads, DCIM, etc.)
- **Multiple Format Support**: MP3, M4A, WAV, FLAC, AAC, OGG, OPUS, WMA
- **Advanced Playback Controls**: Play, pause, skip forward/backward
- **Shuffle Mode**: Randomize your playlist playback
- **Repeat Modes**: Off, Repeat All, Repeat One
- **Mini Player**: Persistent bottom player for quick access
- **Full Player Modal**: Beautiful full-screen player with gradient background
- **Visual Feedback**: Animated equalizer icon for currently playing track
- **Progress Control**: Seek to any position with visual progress bar
- **Smart Previous**: Tap previous within 3 seconds to restart track, otherwise play previous track
- **Playlist Management**: View all songs in a folder
- **Artist & Album Info**: Display metadata for each track
- **Professional UI**: Material Design 3 with custom styling and animations

### 🎬 Video Player
- **Auto-Scan on Startup**: Automatically finds all video files when you open the app
- **Folder-Based Navigation**: Browse your videos organized by folders
- **Multiple Format Support**: MP4, MKV, AVI, MOV, WMV, FLV, WEBM, M4V, 3GP
- **Full video player controls**: Play, pause, skip
- **Progress bar with seek functionality**
- **Tap to show/hide controls**
- **Auto-play next video**

### General Features
- 📂 **Automatic File Scanning**: No manual file picking needed!
- 📁 **Folder Structure**: Files displayed exactly as organized on your device
- 🔄 **Refresh Button**: Rescan to find new files
- 🎨 Modern Material Design 3 UI
- 🌓 Automatic dark and light theme support
- 📱 Optimized for Android
- 💿 Tab-based navigation between Music and Videos

## How to Use

### 🎵 Music Player

#### First Launch - Automatic Scanning
1. Open the app and go to the "Music" tab
2. **The app automatically scans your device for audio files** (shows loading indicator)
3. Wait a few seconds while it searches common directories
4. All folders containing music files will be displayed

#### Browsing Your Music
1. **Folder View**: See all folders that contain audio files
   - Each folder shows the folder name and number of songs
   - Tap any folder to see songs inside
2. **Inside a Folder**: 
   - View all songs in that folder
   - Tap any song to start playing
   - Use back arrow to return to folder view
3. **Refresh**: Tap the refresh button (floating button) to rescan for new files

#### Playing Music
- **Start Playing**: Tap any song in the playlist
- **Mini Player**: Use the bottom mini player for quick controls
- **Full Player**: Tap the mini player to expand to full-screen player
- **Play/Pause**: Tap the play/pause button
- **Skip**: Use skip previous/next buttons
- **Seek**: Drag the progress bar to jump to any position
- **Smart Previous**: Within 3 seconds of playing, it restarts the song; after 3 seconds, it plays the previous song

#### Playback Modes
- **Shuffle**: Tap the shuffle button in the header to randomize playback order (icon lights up when active)
- **Repeat Off**: Songs stop after playlist ends
- **Repeat All**: Playlist loops continuously (tap repeat button once)
- **Repeat One**: Current song loops continuously (tap repeat button twice)

### 🎬 Video Player

#### First Launch - Automatic Scanning
1. Switch to the "Videos" tab
2. **The app automatically scans your device for video files**
3. All folders containing videos will be displayed

#### Browsing Your Videos
1. **Folder View**: See all folders that contain video files
2. **Inside a Folder**: Tap to view all videos in that folder
3. **Refresh**: Tap the refresh button to rescan

#### Playing Videos
- Tap any video to start playing
- Video player appears at the top of the screen
- Tap video to show/hide controls
- Use controls to play, pause, skip, and seek

## Permissions

The app requires the following permissions (already configured in AndroidManifest.xml):
- **READ_EXTERNAL_STORAGE**: Read files from storage (Android 12 and below)
- **WRITE_EXTERNAL_STORAGE**: For older Android versions
- **READ_MEDIA_AUDIO**: Read audio files (Android 13+)
- **READ_MEDIA_VIDEO**: Read video files (Android 13+)
- **MANAGE_EXTERNAL_STORAGE**: Full storage access for file scanning (Android 11+)
- **INTERNET**: For future online features

**Important Notes:**
- When you first open the app, it will request storage permissions
- For Android 11+, you may need to grant "All files access" permission
- The app scans these directories automatically:
  - `/storage/emulated/0/Music`
  - `/storage/emulated/0/Download(s)`
  - `/storage/emulated/0/Movies`
  - `/storage/emulated/0/DCIM`
  - `/storage/emulated/0/Video(s)`
  - `/storage/emulated/0/Audio`
  - `/storage/emulated/0/Podcasts`
  - And subdirectories within these locations

## Dependencies

- **just_audio**: ^0.9.40 - Audio playback
- **video_player**: ^2.9.2 - Video playback
- **file_picker**: ^8.1.6 - File selection
- **permission_handler**: ^11.3.1 - Runtime permissions
- **provider**: ^6.1.2 - State management
- **path**: ^1.9.1 - Path utilities
- **path_provider**: ^2.1.5 - Path provider


## Supported Formats

### Audio
- MP3
- AAC
- WAV
- FLAC
- OGG
- And other formats supported by just_audio

### Video
- MP4
- AVI
- MKV
- MOV
- FLV
- And other formats supported by video_player

## Troubleshooting

### Files not appearing
- Make sure you've granted storage permissions
- Check that the files are in a readable location on your device

### Audio/Video not playing
- Ensure the file format is supported
- Check file integrity
- Try with a different file

### Permission errors
- Go to Settings > Apps > Media Player App > Permissions
- Grant all required storage permissions

## Future Enhancements

Potential features for future versions:
- [ ] Search and filter functionality
- [ ] Sort by name, artist, album, duration
- [ ] Online radio streaming
