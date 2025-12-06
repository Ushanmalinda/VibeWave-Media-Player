# Optimize for low-end devices
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Play Core (Fix for R8 errors)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep just_audio
-keep class com.ryanheise.just_audio.** { *; }

# Keep video_player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Keep video_thumbnail
-keep class xyz.justsoft.video_thumbnail.** { *; }
-dontwarn xyz.justsoft.video_thumbnail.**

# Optimize unused code
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
