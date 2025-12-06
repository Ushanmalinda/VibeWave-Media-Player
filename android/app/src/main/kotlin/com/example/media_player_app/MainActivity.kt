package com.example.media_player_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.graphics.BitmapFactory
import android.media.audiofx.Equalizer
import android.os.Build
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.example.media_player_app/storage"
    private val EQUALIZER_CHANNEL = "com.media_player_app/equalizer"
    private val BACK_CHANNEL = "android/back/pressed"
    private val MEDIA_CONTROLS_CHANNEL = "com.vibewave.player/media_controls"
    private var equalizer: Equalizer? = null
    private var currentAudioSessionId: Int? = null
    private var mediaSession: MediaSessionCompat? = null
    private var notificationManager: NotificationManager? = null
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "media_playback_channel"
    private var currentTitle: String = "Unknown"
    private var currentArtist: String = "Unknown Artist"
    private var isPlaying: Boolean = false
    private var mediaButtonReceiver: MediaButtonReceiver? = null
    private var flutterEngineRef: FlutterEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        flutterEngineRef = flutterEngine
        
        // Initialize notification manager and media session
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        setupMediaSession(flutterEngine)
        registerMediaButtonReceiver()
        
        // Media controls channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateMetadata" -> {
                    val title = call.argument<String>("title") ?: "Unknown"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val album = call.argument<String>("album") ?: "Unknown Album"
                    currentTitle = title
                    currentArtist = artist
                    updateNotification(title, artist, isPlaying)
                    result.success(null)
                }
                "updatePlaybackState" -> {
                    val playing = call.argument<Boolean>("playing") ?: false
                    isPlaying = playing
                    updatePlaybackState(playing)
                    updateNotification(currentTitle, currentArtist, playing)
                    result.success(null)
                }
                "dispose" -> {
                    hideNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Back button channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveTaskToBack" -> {
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Storage channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStoragePaths" -> {
                    val paths = getStoragePaths()
                    result.success(paths)
                }
                else -> result.notImplemented()
            }
        }

        // Equalizer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EQUALIZER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    equalizer?.enabled = enabled
                    result.success(null)
                }
                "setBands" -> {
                    try {
                        val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                        val bands = call.argument<List<Map<String, Any>>>("bands")
                        
                        android.util.Log.d("Equalizer", "Received audio session ID: $audioSessionId")
                        android.util.Log.d("Equalizer", "Received bands: $bands")
                        
                        // Always recreate equalizer to ensure it's attached to current session
                        equalizer?.release()
                        equalizer = null
                        
                        try {
                            equalizer = Equalizer(0, audioSessionId)
                            val numBands = equalizer?.numberOfBands?.toInt() ?: 0
                            android.util.Log.d("Equalizer", "Created equalizer with $numBands bands")
                            
                            // Get min and max levels
                            val minLevel = equalizer?.bandLevelRange?.get(0) ?: 0
                            val maxLevel = equalizer?.bandLevelRange?.get(1) ?: 0
                            android.util.Log.d("Equalizer", "Level range: $minLevel to $maxLevel")
                            
                            // Enable equalizer
                            equalizer?.enabled = true
                            currentAudioSessionId = audioSessionId
                            
                            // Apply bands
                            bands?.let { bandList ->
                                if (numBands > 0) {
                                    // Simple mapping: distribute the 10 bands across available bands
                                    for (i in 0 until numBands) {
                                        val sourceIndex = (i * bandList.size) / numBands
                                        val band = bandList[sourceIndex.coerceIn(0, bandList.size - 1)]
                                        val gain = (band["gain"] as? Double)?.toFloat() ?: 0f
                                        
                                        // Convert -12 to +12 dB range to millibels
                                        val gainInMillibels = (gain * 100).toInt().toShort()
                                            .coerceIn(minLevel, maxLevel)
                                        
                                        equalizer?.setBandLevel(i.toShort(), gainInMillibels)
                                        android.util.Log.d("Equalizer", "Band $i: gain=$gain dB, level=$gainInMillibels mB")
                                    }
                                }
                            }
                            
                            android.util.Log.d("Equalizer", "Equalizer successfully configured and enabled")
                        } catch (e: Exception) {
                            android.util.Log.e("Equalizer", "Failed to create equalizer: ${e.message}")
                            e.printStackTrace()
                        }
                        
                        result.success(null)
                    } catch (e: Exception) {
                        android.util.Log.e("Equalizer", "Error in setBands: ${e.message}")
                        e.printStackTrace()
                        result.error("EQUALIZER_ERROR", e.message, null)
                    }
                }
                "release" -> {
                    equalizer?.release()
                    equalizer = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        equalizer?.release()
        mediaSession?.release()
        hideNotification()
        unregisterMediaButtonReceiver()
        super.onDestroy()
    }
    
    private fun registerMediaButtonReceiver() {
        mediaButtonReceiver = MediaButtonReceiver()
        val filter = android.content.IntentFilter().apply {
            addAction("com.vibewave.player.PLAY")
            addAction("com.vibewave.player.PAUSE")
            addAction("com.vibewave.player.NEXT")
            addAction("com.vibewave.player.PREVIOUS")
        }
        registerReceiver(mediaButtonReceiver, filter)
    }
    
    private fun unregisterMediaButtonReceiver() {
        try {
            mediaButtonReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
    
    fun handleMediaAction(action: String) {
        flutterEngineRef?.let { engine ->
            android.util.Log.d("MainActivity", "Handling media action: $action")
            MethodChannel(engine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL)
                .invokeMethod(action, null)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Media Playback",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Media playback controls"
                setShowBadge(false)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun setupMediaSession(flutterEngine: FlutterEngine) {
        val mediaButtonReceiver = ComponentName(this, MediaButtonReceiver::class.java)
        mediaSession = MediaSessionCompat(this, "VibeWavePlayer", mediaButtonReceiver, null).apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    android.util.Log.d("MediaSession", "onPlay called")
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL)
                        .invokeMethod("play", null)
                }

                override fun onPause() {
                    android.util.Log.d("MediaSession", "onPause called")
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL)
                        .invokeMethod("pause", null)
                }

                override fun onSkipToNext() {
                    android.util.Log.d("MediaSession", "onSkipToNext called")
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL)
                        .invokeMethod("next", null)
                }

                override fun onSkipToPrevious() {
                    android.util.Log.d("MediaSession", "onSkipToPrevious called")
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_CONTROLS_CHANNEL)
                        .invokeMethod("previous", null)
                }
            })
            isActive = true
        }
    }

    private fun updatePlaybackState(playing: Boolean) {
        val state = if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
        val playbackState = PlaybackStateCompat.Builder()
            .setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 1.0f)
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
            )
            .build()
        mediaSession?.setPlaybackState(playbackState)
    }

    private fun updateNotification(title: String, artist: String, playing: Boolean) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create action intents that directly call the media session
        val playIntent = Intent("com.vibewave.player.PLAY")
        val pauseIntent = Intent("com.vibewave.player.PAUSE")
        val previousIntent = Intent("com.vibewave.player.PREVIOUS")
        val nextIntent = Intent("com.vibewave.player.NEXT")

        val playPendingIntent = PendingIntent.getBroadcast(this, 0, playIntent, PendingIntent.FLAG_IMMUTABLE)
        val pausePendingIntent = PendingIntent.getBroadcast(this, 1, pauseIntent, PendingIntent.FLAG_IMMUTABLE)
        val previousPendingIntent = PendingIntent.getBroadcast(this, 2, previousIntent, PendingIntent.FLAG_IMMUTABLE)
        val nextPendingIntent = PendingIntent.getBroadcast(this, 3, nextIntent, PendingIntent.FLAG_IMMUTABLE)

        val playPauseAction = if (playing) {
            NotificationCompat.Action.Builder(
                android.R.drawable.ic_media_pause,
                "Pause",
                pausePendingIntent
            ).build()
        } else {
            NotificationCompat.Action.Builder(
                android.R.drawable.ic_media_play,
                "Play",
                playPendingIntent
            ).build()
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(artist)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setColorized(true)
            .setStyle(androidx.media.app.NotificationCompat.MediaStyle()
                .setMediaSession(mediaSession?.sessionToken)
                .setShowActionsInCompactView(0, 1, 2)
                .setShowCancelButton(false))
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    previousPendingIntent
                ).build()
            )
            .addAction(playPauseAction)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_media_next,
                    "Next",
                    nextPendingIntent
                ).build()
            )
            .setOngoing(playing)
            .setAutoCancel(false)
            .build()

        notificationManager?.notify(NOTIFICATION_ID, notification)
    }

    private fun hideNotification() {
        notificationManager?.cancel(NOTIFICATION_ID)
    }

    private fun getStoragePaths(): List<String> {
        val paths = mutableListOf<String>()
        
        try {
            val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val volumes: List<StorageVolume> = storageManager.storageVolumes
                
                for (volume in volumes) {
                    // Use reflection to get the path since it's hidden API
                    try {
                        val pathMethod = volume.javaClass.getMethod("getPath")
                        val path = pathMethod.invoke(volume) as? String
                        
                        if (path != null && volume.state == "mounted") {
                            paths.add(path)
                        }
                    } catch (e: Exception) {
                        // Try alternative method for getting directory
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            volume.directory?.let {
                                paths.add(it.absolutePath)
                            }
                        }
                    }
                }
            }
            
            // Fallback: Add default paths if nothing found
            if (paths.isEmpty()) {
                paths.add("/storage/emulated/0")
            }
            
        } catch (e: Exception) {
            // Fallback to internal storage
            paths.add("/storage/emulated/0")
        }
        
        return paths
    }
}
