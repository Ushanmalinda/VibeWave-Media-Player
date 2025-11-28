# App Screenshots Description

## 1. Main Playlist View (Empty State)
- Large music note icon (100px, gray)
- Text: "No audio files"
- Subtext: "Tap the + button to add music"
- Header shows "Playlist (0)"
- Shuffle and Repeat buttons visible but inactive
- Purple + button at bottom right

## 2. Main Playlist View (With Songs)
- Header: "Playlist (X)" with shuffle and repeat buttons
- Each song item shows:
  - Left: 48x48px colored square with music note icon
  - Title in bold (if playing) or regular weight
  - Artist name below title in gray
  - Right: Three-dot menu button
- Currently playing song has:
  - 4px colored left border
  - Light background tint
  - Equalizer icon (animated when playing)
  - Accent color text
- Floating + button at bottom right

## 3. Mini Player (Bottom Bar)
- Height: 72px total (3px progress + 69px content)
- Top: Thin colored progress bar showing playback progress
- Left: 48x48px album art placeholder (colored square, rounded corners)
- Center: Song title (bold, 14px) and artist (gray, 12px)
- Right: Three control buttons
  - Skip Previous (rounded icon)
  - Play/Pause (large, 40px circle icon)
  - Skip Next (rounded icon)
- White background with shadow
- Tap anywhere to expand to full player

## 4. Full Player Modal
- Full-screen overlay with gradient background (primary to secondary color)
- Top bar:
  - Left: Large down arrow button (32px)
  - Center: "Now Playing" text
- Main content (vertically centered):
  - Large album art: 280x280px rounded square with shadow
  - Song title: 24px, bold, white, center-aligned
  - Artist: 16px, semi-transparent white
  - Custom slider with thin track (3px)
  - Time labels: Start time (left) and total duration (right)
- Bottom controls (evenly spaced):
  - Shuffle button (28px)
  - Skip Previous (40px)
  - Play/Pause in white circle (70px diameter, 40px icon)
  - Skip Next (40px)
  - Repeat button (28px)
- All controls in white color
- Active buttons (shuffle, repeat) fully opaque
- Inactive buttons semi-transparent (60% opacity)

## 5. Options Menu (Bottom Sheet)
- Appears when tapping three-dot menu on any song
- White rounded top corners
- Options:
  - "Remove from playlist" with delete icon
- Tapping option closes menu and performs action

## 6. Empty Video Tab
- Large video library icon (100px, gray)
- Text: "No video files"
- Subtext: "Tap the + button to add videos"
- Purple + button at bottom right

## Color Scheme
- **Primary**: Deep Purple (#673AB7)
- **Secondary**: Auto-generated from primary
- **Background**: White (light) / Dark (dark mode)
- **Surface**: Material Design 3 containers
- **Active Elements**: Primary color
- **Inactive Elements**: Gray (#9E9E9E)
- **Text**: Black/White depending on background
- **Subtle Text**: Gray (#757575)

## Icons Used
- `music_note_rounded` - Generic music icon
- `equalizer_rounded` - Playing indicator (animated)
- `shuffle` / `shuffle_on_rounded` - Shuffle mode
- `repeat_rounded` / `repeat_one_rounded` - Repeat modes
- `skip_previous_rounded` - Previous button
- `skip_next_rounded` - Next button
- `play_circle_filled_rounded` - Play button
- `pause_circle_filled_rounded` - Pause button
- `play_arrow_rounded` - Full player play
- `pause_rounded` - Full player pause
- `keyboard_arrow_down_rounded` - Close full player
- `more_vert` - Options menu
- `add` - Add files button
- `video_library_rounded` - Video tab icon

## Fonts
- Default system font (Roboto on Android)
- Weight variations: Regular (400), Medium (500), Bold (700)
- Sizes: 12px, 14px, 16px, 18px, 20px, 24px, 32px

## Animations
- Equalizer icon pulses/animates when song is playing
- Smooth transitions between mini and full player
- Progress bar smoothly updates every frame
- Button states fade in/out on press
- List items have ripple effect on tap

## Spacing
- Padding: 8px, 12px, 16px, 20px, 32px, 40px
- Item heights: 56px (list items), 72px (mini player)
- Border radius: 8px (small elements), 20px (large elements)
- Shadows: Elevation of 2-8dp for Material Design depth
