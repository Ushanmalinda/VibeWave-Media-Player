# AIMP-Style Features Guide

This app is inspired by AIMP player and includes professional-grade music player features.

## 🎵 Music Player Interface

### Main Playlist View
- **Clean List Design**: Each song shows with a colorful icon, title, and artist
- **Visual Playing Indicator**: Currently playing song has:
  - Colored left border (accent color)
  - Highlighted background
  - Animated equalizer icon (when playing)
  - Bold text and accent color
- **Header Controls**: 
  - Playlist counter showing total number of songs
  - Shuffle button (lights up when active)
  - Repeat mode button (cycles through Off → All → One)

### Mini Player (Bottom Bar)
The persistent mini player stays at the bottom while browsing your playlist:
- **Album Art**: Colorful placeholder icon
- **Song Info**: Title and artist display
- **Linear Progress Bar**: Thin progress indicator at top
- **Quick Controls**:
  - Skip Previous button
  - Play/Pause button (large, centered)
  - Skip Next button
- **Tap to Expand**: Tap anywhere on the mini player to open full player

### Full Player Modal
Beautiful full-screen player with gradient background:
- **Gradient Design**: Smooth color transition from primary to secondary theme colors
- **Large Album Art**: 280x280px centered placeholder with shadow
- **Song Information**:
  - Large title (24px, bold)
  - Artist name below title
- **Custom Slider**: Thin, elegant progress bar with time labels
- **Complete Controls**:
  - Shuffle button (left)
  - Skip Previous button
  - Large circular Play/Pause button (white circle, 70px)
  - Skip Next button
  - Repeat mode button (right)
- **Close Button**: Top-left down arrow to minimize back to mini player

## 🎮 Playback Controls

### Shuffle Mode
**Icon States**:
- `shuffle` - Inactive (gray)
- `shuffle_on_rounded` - Active (accent color)

**Behavior**:
- When OFF: Plays songs in order
- When ON: Randomly selects next song from playlist
- Works with Repeat All mode

### Repeat Modes
**Three States** (cycles through):

1. **Repeat OFF** (`repeat_rounded`, gray)
   - Plays playlist once and stops at the end
   
2. **Repeat ALL** (`repeat_rounded`, accent color)
   - Loops entire playlist continuously
   - After last song, goes back to first song
   
3. **Repeat ONE** (`repeat_one_rounded`, accent color)
   - Loops current song infinitely
   - Skip buttons still work to change songs

### Smart Previous Button
Intelligent behavior based on playback position:
- **First 3 seconds**: Goes to previous song
- **After 3 seconds**: Restarts current song
- Similar to Spotify and other modern players

## 🎨 Visual Design

### Color System
- **Primary Color**: Deep purple (from theme)
- **Secondary Color**: Auto-generated from primary
- **Surface Colors**: Material Design 3 surface containers
- **Accent Elements**: Primary color for active states

### Animations & Effects
- **Equalizer Icon**: Animated equalizer appears on currently playing song
- **Smooth Transitions**: Between mini and full player
- **Shadow Effects**: Album art has depth with shadows
- **Progress Animations**: Smooth slider and progress bar updates
- **Gradient Backgrounds**: Full player uses gradient overlay

### Typography
- **Song Titles**: Bold, 14-24px depending on context
- **Artists**: Regular, 12-16px, gray color
- **Times**: 12px, semi-transparent white
- **Headers**: 18px, bold

## 📱 User Experience

### Gestures
- **Tap Song**: Start playing immediately
- **Tap Mini Player**: Expand to full player
- **Tap Full Player Background**: Remains open (intentional)
- **Down Arrow**: Close full player
- **Drag Slider**: Seek to position
- **Three-Dot Menu**: Show options (remove from playlist)

### Visual Feedback
- **Active Buttons**: Color changes to accent
- **Currently Playing**: Multiple indicators (border, background, icon)
- **Progress**: Both linear (mini) and slider (full) representations
- **Hover States**: Touch feedback on all interactive elements

### Performance
- **Smooth Scrolling**: Optimized list rendering
- **Quick Transitions**: Instant response to user actions
- **Memory Efficient**: Proper disposal of resources
- **State Management**: Clean setState usage

## 🔧 Technical Features

### Audio Engine
- **just_audio Package**: Professional audio playback
- **Stream Listeners**: Real-time position and state updates
- **Error Handling**: Graceful error messages
- **File Support**: MP3, AAC, WAV, FLAC, OGG, and more

### State Management
- **Duration Tracking**: Live duration and position streams
- **Play State**: Real-time playing/paused status
- **Index Management**: Current song index tracking
- **Mode States**: Shuffle and repeat mode persistence

### File Management
- **File Picker**: Native Android file picker integration
- **Multiple Selection**: Add many songs at once
- **Path Storage**: Direct file path access
- **Metadata**: Title, artist, album info storage

## 🎯 AIMP-Inspired Elements

This app takes inspiration from AIMP player's:
1. **Clean Interface**: Simple, functional design
2. **Powerful Controls**: Shuffle and multiple repeat modes
3. **Visual Feedback**: Clear indication of playing state
4. **Mini Player**: Quick access without losing context
5. **Professional Feel**: Polished UI with attention to detail
6. **Color Coding**: Visual distinction for active elements
7. **Smooth Experience**: Fast and responsive interactions

## 🚀 Quick Tips

- **Batch Add**: Select multiple files at once when adding music
- **Quick Access**: Use mini player for basic controls while browsing
- **Full Control**: Open full player for complete control and beautiful view
- **Smart Navigation**: Previous button intelligently decides to restart or go back
- **Visual Cues**: Watch for colored elements to see what's active
- **Playlist Management**: Use three-dot menu to remove unwanted songs
- **Mode Indicators**: Button colors show which modes are active
