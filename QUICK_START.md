# Quick Start Guide

## Running the App

### On Android Device/Emulator

1. Make sure an Android device is connected or emulator is running:
   ```bash
   flutter devices
   ```

2. Run the app:
   ```bash
   flutter run
   ```

### Build Release APK

To create a release APK for distribution:
```bash
flutter build apk --release
```

The APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## Testing the App

### Test Audio Player
1. Open the app
2. Stay on the "Audio" tab
3. Tap the '+' button
4. Select MP3 files from your device
5. Tap a song to play it
6. Use controls to pause, skip, and seek

### Test Video Player
1. Open the app
2. Switch to the "Video" tab
3. Tap the '+' button
4. Select video files from your device
5. Tap a video to play it
6. Tap the video to show/hide controls
7. Use controls to pause, skip, and seek

## Important Notes

- **First Run**: The app will request storage permissions when you first try to pick files
- **Permissions**: Make sure to grant all storage permissions for the app to work properly
- **File Formats**: Supported formats include MP3, MP4, and most common audio/video formats
- **Android Version**: Works on Android 5.0 (API 21) and above

## Commands Reference

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk --release

# Clean build
flutter clean

# Check for issues
flutter doctor
```

## Troubleshooting

### App won't run
```bash
flutter clean
flutter pub get
flutter run
```

### Permission issues
- Grant all storage permissions in Android Settings
- For Android 13+, both READ_MEDIA_AUDIO and READ_MEDIA_VIDEO are needed

### Build errors
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```
