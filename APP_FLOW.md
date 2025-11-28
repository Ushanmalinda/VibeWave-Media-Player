# App Flow - From Launch to Playing

## 📱 Complete User Journey

### 1. App Launch
```
[Splash Screen]
     ↓
[Main Screen with 2 Tabs]
├── Music Tab (Active)
└── Videos Tab
```

### 2. Music Tab - First View

```
┌─────────────────────────────────────┐
│  ← Media Player          🔀 🔁      │ ← Header
├─────────────────────────────────────┤
│                                     │
│     📁  Scanning for audio files... │ ← Loading
│         [Progress Indicator]        │
│                                     │
└─────────────────────────────────────┘
                                    [🔄] ← Refresh Button
```

### 3. After Scanning - Folder View

```
┌─────────────────────────────────────┐
│  Folders (5)                        │ ← Header with count
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📁  Music            12 songs ❯ │ │ ← Folder Card
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📁  Download          3 songs ❯ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📁  DCIM              1 song  ❯ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📁  Podcasts          8 songs ❯ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📁  Downloads         5 songs ❯ │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
                                    [🔄]
```

### 4. Inside a Folder - Song List

```
┌─────────────────────────────────────┐
│  ← Music               🔀 🔁        │ ← Back + Controls
├─────────────────────────────────────┤
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┃ 🎵  Bohemian Rhapsody          ┃ │ ← Currently Playing
│ ┃     Queen                      ┃ │   (colored border)
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
│ ┌───────────────────────────────┐ │
│ │ 🎵  Don't Stop Me Now         │ │
│ │     Queen                     │ │
│ └───────────────────────────────┘ │
│ ┌───────────────────────────────┐ │
│ │ 🎵  We Will Rock You          │ │
│ │     Queen                     │ │
│ └───────────────────────────────┘ │
│                                   │
├═══════════════════════════════════┤
│ 🎵  Bohemian Rhapsody  ⏮️ ⏸️ ⏭️  │ ← Mini Player
│     Queen                         │
│ ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░ 2:34/5:55│
└─────────────────────────────────────┘
```

### 5. Full Player (Expanded)

```
┌─────────────────────────────────────┐
│  ⌄  Now Playing                     │ ← Close button
│                                     │
│                                     │
│         ┌─────────────┐            │
│         │             │            │
│         │     🎵      │            │ ← Large Album Art
│         │             │            │
│         └─────────────┘            │
│                                     │
│      Bohemian Rhapsody             │ ← Song Title
│         Queen                       │ ← Artist
│                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━     │ ← Progress Slider
│  2:34                      5:55     │
│                                     │
│    🔀    ⏮️   ⏸️   ⏭️    🔁       │ ← Full Controls
│                                     │
└─────────────────────────────────────┘
```

### 6. Videos Tab - Folder View

```
┌─────────────────────────────────────┐
│  Folders (3)                        │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📹  Movies           15 videos ❯│ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📹  DCIM             22 videos ❯│ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📹  Downloads         5 videos ❯│ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
                                    [🔄]
```

### 7. Inside Video Folder - Playing

```
┌─────────────────────────────────────┐
│  ← Movies                           │
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐ │
│ │  Movie Title.mp4              │ │ ← Video Player
│ │                               │ │   (300px height)
│ │      [Video Playing]          │ │
│ │          ⏸️                   │ │
│ │  ━━━━━━━━━━━━━━ 1:23/2:45   │ │
│ │       ⏮️        ⏭️           │ │
│ └───────────────────────────────┘ │
├─────────────────────────────────────┤
│ 🎬  Movie Title.mp4  [PLAYING]     │
│ 🎬  Another Movie.mkv              │
│ 🎬  Video File.avi                 │
│ 🎬  Holiday 2024.mp4               │
└─────────────────────────────────────┘
```

## 🎮 Key User Actions

### Folder View Actions
1. **Tap Folder Card** → Opens folder to show files
2. **Tap Refresh Button** → Rescans device for media files

### Music Player Actions
1. **Tap Song** → Starts playing immediately
2. **Tap Mini Player** → Expands to full player
3. **Tap Back Arrow** → Returns to folder view
4. **Tap Shuffle** → Toggles shuffle mode
5. **Tap Repeat** → Cycles through repeat modes (Off → All → One)
6. **Tap Skip Previous** → Previous song (or restart if >3 sec)
7. **Tap Play/Pause** → Toggles playback
8. **Tap Skip Next** → Next song
9. **Drag Slider** → Seek to position

### Video Player Actions
1. **Tap Video** → Plays in player at top
2. **Tap Video Player** → Show/hide controls
3. **Use Controls** → Play, pause, skip, seek
4. **Tap Back Arrow** → Returns to folder view

## 🎨 Visual States

### Song List Item States
- **Normal**: Gray background, regular font
- **Playing**: 
  - Purple left border (4px)
  - Light purple background
  - Bold purple text
  - Equalizer icon (animated)

### Button States
- **Inactive**: Gray color
- **Active**: Purple color (primary theme)

### Loading States
- **Scanning**: Circular progress indicator + text
- **Empty**: Folder-off icon + "No files found" message

## 🔄 App Lifecycle

```
App Launch
    ↓
Grant Permissions (if first time)
    ↓
Auto-Scan Starts (Music/Videos)
    ↓
Show Loading Indicator
    ↓
Scan Complete → Display Folders
    ↓
User Interaction:
├─ Tap Folder → Show Files
├─ Tap File → Start Playing
├─ Tap Back → Return to Folders
└─ Tap Refresh → Rescan Files
```

## 📊 Information Hierarchy

1. **Top Level**: Folder list (organized by directory)
2. **Second Level**: File list within folder
3. **Third Level**: Now playing (mini player)
4. **Fourth Level**: Full player (modal overlay)

Each level maintains context and allows easy navigation back.
