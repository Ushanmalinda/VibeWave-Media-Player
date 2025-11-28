# Folder-Based Navigation Guide

This app automatically scans your device for media files and displays them organized by folders - just like a file manager!

## 🔍 How Auto-Scanning Works

### When You Open the App

**Music Tab:**
1. App immediately starts scanning for audio files
2. Shows a loading indicator with "Scanning for audio files..."
3. Searches common Android directories:
   - Music folder
   - Downloads folder
   - DCIM (Camera) folder
   - Videos folder (may contain audio)
   - Audio/Podcasts folders
   - Root storage and subdirectories

**Videos Tab:**
1. Same automatic scanning process
2. Searches for video files in similar locations
3. Displays results organized by folder

### Supported File Types

**Audio Files (Extensions):**
- `.mp3` - MP3 Audio
- `.m4a` - MPEG-4 Audio
- `.wav` - Waveform Audio
- `.flac` - Free Lossless Audio Codec
- `.aac` - Advanced Audio Coding
- `.ogg` - Ogg Vorbis
- `.opus` - Opus Audio
- `.wma` - Windows Media Audio

**Video Files (Extensions):**
- `.mp4` - MPEG-4 Video
- `.mkv` - Matroska Video
- `.avi` - Audio Video Interleave
- `.mov` - QuickTime Movie
- `.wmv` - Windows Media Video
- `.flv` - Flash Video
- `.webm` - WebM Video
- `.m4v` - iTunes Video
- `.3gp` - 3GPP Multimedia

## 📁 Folder View Interface

### Folder List Display

Each folder card shows:
- **Folder Icon**: 
  - Music: Folder icon with primary color
  - Videos: Video library icon with primary color
- **Folder Name**: The name of the directory (e.g., "Music", "Downloads", "My Songs")
- **File Count**: Number of media files in that folder
- **Chevron Arrow**: Indicates you can tap to open

### Folder Organization

Files are grouped by their **directory path**:
```
/storage/emulated/0/Music/
  ├── Rock/          (Shows as "Rock" folder with X songs)
  ├── Pop/           (Shows as "Pop" folder with X songs)
  └── Jazz/          (Shows as "Jazz" folder with X songs)

/storage/emulated/0/Downloads/
  └── (Shows as "Downloads" folder with X songs)
```

Each unique folder path becomes a separate entry in the folder list.

## 🎵 Inside a Folder

When you tap a folder:

### Navigation
- **Back Button**: Top-left arrow returns to folder view
- **Folder Name**: Displayed in header
- **Song/Video List**: All media files from that folder

### Music Folder View
- Shows all audio files in the folder
- Each song displays:
  - Album art placeholder (colored icon)
  - Song title (filename without extension)
  - Artist (extracted from folder structure or "Unknown Artist")
- **Currently Playing**: 
  - Left colored border
  - Highlighted background
  - Equalizer animation icon
- **Playback Controls**: Shuffle and Repeat buttons in header

### Video Folder View
- Shows all video files in the folder
- Each video displays:
  - Video icon placeholder
  - Video title (filename without extension)
- Tap any video to play it at the top of the screen

## 🔄 Refresh / Rescan

### When to Refresh
- Added new music/videos to your device
- Downloaded files from the internet
- Moved files between folders
- App not showing recent files

### How to Refresh
1. Make sure you're in **Folder View** (not inside a folder)
2. Tap the **floating refresh button** (circular button at bottom-right)
3. Wait for scanning to complete
4. New folders and files will appear

## 🗂️ File Scanning Details

### Scanning Strategy

**Recursive Scanning:**
- Scans main directories AND their subdirectories
- Example: `/Music/Rock/80s/` will be found

**Exclusions:**
- Hidden folders (starting with `.`)
- System folders (`android/`, `data/`)
- Folders without read permissions

**Performance:**
- Fast scanning (few seconds for typical libraries)
- Non-blocking UI (can navigate while scanning)
- Efficient file detection by extension

### Metadata Extraction

**Artist Information:**
The app tries to determine the artist from folder structure:
- `/Music/Artist Name/Album/Song.mp3` → Artist: "Artist Name"
- If not in standard structure → "Unknown Artist"

**Album Information:**
- Uses the immediate parent folder name as album
- Example: `/Music/Queen/Bohemian Rhapsody/song.mp3` → Album: "Bohemian Rhapsody"

## 🔐 Permissions Required

### Initial Permission Request

When first launching the app:
1. **Storage Permission Dialog** appears
2. Tap "Allow" or "While using the app"
3. For Android 11+: May show "Allow access to manage all files"

### Permission Types by Android Version

**Android 13+ (API 33+):**
- `READ_MEDIA_AUDIO` - Access audio files
- `READ_MEDIA_VIDEO` - Access video files

**Android 10-12:**
- `READ_EXTERNAL_STORAGE` - Access all files

**Android 11+:**
- `MANAGE_EXTERNAL_STORAGE` - Full file access (for comprehensive scanning)

### If Permissions Denied

If scanning shows no files:
1. Go to Android Settings
2. Navigate to Apps → Media Player App → Permissions
3. Enable "Files and media" or "Storage"
4. For Android 11+: Enable "All files access"
5. Return to app and tap Refresh

## 🎯 Benefits of Folder Navigation

1. **Organized Browsing**: Files grouped logically as you organized them
2. **Find Music Faster**: Know exactly where your music is stored
3. **Multiple Sources**: See music from Downloads, Music folder, etc. separately
4. **No Duplicates**: Each folder is distinct
5. **Familiar Structure**: Matches your file manager view
6. **No Manual Adding**: Everything is automatically discovered

## 💡 Tips & Tricks

**Organizing Your Library:**
- Create folders on your device for different genres/artists
- App will automatically find them on next refresh
- Example structure:
  ```
  Music/
    ├── Rock/
    ├── Pop/
    ├── Classical/
    └── Favorites/
  ```

**Download Location:**
- Most browsers save to `/Download` or `/Downloads`
- These folders are automatically scanned
- Downloaded music appears immediately after refresh

**External SD Card:**
- If your device has an SD card, place media there
- App scans external storage too
- May require additional permissions

**Performance:**
- First scan may take 5-10 seconds depending on library size
- Subsequent scans are faster (cached paths)
- Close and reopen app to force fresh scan

## 🐛 Troubleshooting

**No folders appearing:**
- Grant storage permissions in Settings
- Ensure files have correct extensions (.mp3, .mp4, etc.)
- Check files are in scanned directories
- Try Refresh button

**Missing some files:**
- Files might be in non-standard locations
- Check file extensions are supported
- Ensure folders aren't hidden (starting with .)

**Duplicate folders:**
- This is normal if you have files in multiple locations
- Each directory path is shown separately
- Different folders can have same name if in different paths

**Slow scanning:**
- Large music libraries (1000+ files) may take longer
- Close other apps to free memory
- Restart device if persistent
