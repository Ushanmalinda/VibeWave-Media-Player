# Media Player App - Controls Testing Guide

## Features Implemented

### 1. Settings Screen

- **Location**: Sidebar → Settings (last item)
- **UI**: Complete settings page with all AIMP-style controls

### 2. Volume Button Controls

**Settings**:

- ✅ Double tap switches tracks (when volume is 2-8 range)
- ✅ Pause when volume becomes zero
- ✅ Play when volume becomes non-zero

**How to Test**:

1. Play a song
2. Lower volume to zero → should pause
3. Raise volume → should resume playing

### 3. Headset Controls

**Settings**:

- ✅ Single tap action (default: Play/Pause)
- ✅ Double tap action (default: Next track)
- ✅ Triple tap action (default: None)
- ✅ Play when headset plugged in
- ✅ Play when Bluetooth headset plugged in
- ✅ Bluetooth commands as headset commands

**How to Test**:

1. Connect headphones/Bluetooth headset
2. Single tap headset button → Play/Pause
3. Double tap quickly → Next track
4. Triple tap → Custom action (if configured)

### 4. Shake It Feature

**Settings**:

- ✅ Enable/disable shake detection
- ✅ Shake sensitivity slider (1-5)
- ✅ Action: Skip to next track

**How to Test**:

1. Go to Settings → Enable "Shake it feature"
2. Adjust sensitivity (1 = very sensitive, 5 = less sensitive)
3. Play a song
4. Shake the device → Next track plays

### 5. Gesture Controls on Album Art

**Settings** (all customizable):

- ✅ Swipe left-to-right (default: Previous track)
- ✅ Swipe right-to-left (default: Next track)
- ✅ Swipe top-to-bottom (configurable)
- ✅ Swipe bottom-to-top (configurable)
- ✅ Double tap left side (default: Rewind 10s)
- ✅ Double tap right side (default: Forward 10s)
- ✅ Double tap top (configurable)
- ✅ Double tap bottom (configurable)
- ✅ Scroll vertically (default: Adjust volume)

**How to Test**:

1. Open audio player (full screen view)
2. On album art:
   - Swipe left → Previous track
   - Swipe right → Next track
   - Double tap left → Rewind 10 seconds
   - Double tap right → Forward 10 seconds
   - Swipe up/down → Custom actions

## Action Options Available

Each gesture/button can be configured to:

- **None**: Do nothing
- **Play / Pause**: Toggle playback
- **Next track**: Skip to next song
- **Previous track**: Go to previous song
- **Rewind**: Jump back 10 seconds
- **Fast forward**: Jump ahead 10 seconds
- **Adjust volume**: Change volume level

## Testing Checklist

### Initial Setup

- [ ] Open Settings from sidebar
- [ ] Verify all sections are visible:
  - [ ] Volume Buttons
  - [ ] Headset
  - [ ] Shake It
  - [ ] Gestures

### Volume Controls

- [ ] Enable "Pause on volume zero"
- [ ] Play song and lower volume to 0
- [ ] Verify playback pauses
- [ ] Raise volume
- [ ] Verify playback resumes

### Shake Detection

- [ ] Enable shake feature
- [ ] Set sensitivity to 3 (medium)
- [ ] Play a song
- [ ] Shake device firmly
- [ ] Verify next track plays

### Gesture Controls

- [X] Play a song and open full player
- [X] Test swipe gestures on album art:
  - [X] Swipe right (fast) → Next track
  - [X] Swipe left (fast) → Previous track
- [X] Test double tap gestures:
  - [X] Double tap left side → Rewind
  - [X] Double tap right side → Forward

### Settings Persistence

- [ ] Change a few settings
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify settings are saved

## Known Limitations

1. **Volume Button Track Switch**: Requires native Android implementation for true double-press detection of hardware volume buttons. Current implementation detects volume changes only.
2. **Headset Button Detection**: Basic implementation provided. Full multi-tap detection may require additional native code for reliable triple-tap detection.
3. **Scroll Gesture for Volume**: Currently configured in settings but requires additional UI feedback implementation.

## Development Notes

### Files Created/Modified:

1. `lib/services/settings_service.dart` - Settings persistence
2. `lib/services/controls_manager.dart` - Hardware controls integration
3. `lib/screens/settings_screen.dart` - Settings UI
4. `lib/screens/audio_player_screen.dart` - Gesture integration
5. `pubspec.yaml` - Added sensors_plus, audio_session packages

### Packages Added:

- **sensors_plus**: Accelerometer for shake detection
- **audio_session**: Audio focus and headset event handling
- **volume_controller**: Already present, used for volume monitoring

All settings are persisted using SharedPreferences and loaded on app startup.
