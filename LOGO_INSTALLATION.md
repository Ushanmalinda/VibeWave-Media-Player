# VibeWave Player - Logo Installation Guide

## Quick Steps to Add Your Logo:

### 1. Create Folder Structure

```
media_player_app/
└── assets/
    └── icon/
        ├── app_icon.png
        └── app_icon_foreground.png
```

### 2. Prepare Your Logo Files

**app_icon.png** (1024x1024px)

- Your complete logo with background
- Square format, no transparency needed
- Background color: #1a1a1a (dark gray/black)
- Logo: Orange/your brand colors

**app_icon_foreground.png** (1024x1024px)

- Logo ONLY (no background)
- Must have transparent background
- Keep logo within center 60% (safe zone for adaptive icons)
- Margins: 200px on all sides recommended

### 3. Run Icon Generator Command

```bash
flutter pub run flutter_launcher_icons
```

This will automatically create all required icon sizes:

- mdpi (48x48)
- hdpi (72x72)
- xhdpi (96x96)
- xxhdpi (144x144)
- xxxhdpi (192x192)
- Adaptive icon XML files

### 4. Test the Icon

```bash
flutter run
```

Check your app icon on:

- Home screen
- App drawer
- Recent apps
- Notification bar

---

## Alternative: Manual Placement (If you already have all sizes)

If you already have pre-sized icons:

### Android Icons (Legacy)

Place your PNG files here:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png         (48x48)
├── mipmap-hdpi/ic_launcher.png         (72x72)
├── mipmap-xhdpi/ic_launcher.png        (96x96)
├── mipmap-xxhdpi/ic_launcher.png       (144x144)
└── mipmap-xxxhdpi/ic_launcher.png      (192x192)
```

### Android Adaptive Icons (Modern)

```
android/app/src/main/res/
└── mipmap-anydpi-v26/
    ├── ic_launcher.xml
    ├── ic_launcher_foreground.xml
    └── ic_launcher_background.xml
```

---

## Adding Logo to About Screen

After your logo is ready, update the about screen:

1. Save your logo as: `assets/images/logo.png` (500x500px recommended)
2. Add to pubspec.yaml:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/logo.png
```

3. Update lib/screens/about_screen.dart (around line 31):

```dart
// Replace the Container with:
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
),
```

---

## Testing Checklist

After installing your logo:

- [ ] Icon appears on home screen
- [ ] Icon looks clear (not pixelated)
- [ ] Icon stands out from other apps
- [ ] Adaptive icon works on Android 8.0+
- [ ] Notification icon is visible
- [ ] About screen shows logo correctly

---

## Need Help Designing the Logo?

See **BRANDING_BRIEF.md** for:

- AI prompts for logo generation
- Design specifications
- Color palette
- Free tool recommendations

**App Name:** VibeWave Player
**Colors:** Orange (#FF9800) + Dark Gray (#1a1a1a)
**Style:** Modern, minimal, wave/audio theme
