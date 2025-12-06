package com.example.media_player_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

class MediaButtonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.d("MediaButtonReceiver", "Received intent: ${intent.action}")
        
        when (intent.action) {
            "com.vibewave.player.PLAY" -> {
                android.util.Log.d("MediaButtonReceiver", "Play action received")
                // Trigger MediaSession callback
                (context as? MainActivity)?.handleMediaAction("play")
            }
            "com.vibewave.player.PAUSE" -> {
                android.util.Log.d("MediaButtonReceiver", "Pause action received")
                (context as? MainActivity)?.handleMediaAction("pause")
            }
            "com.vibewave.player.NEXT" -> {
                android.util.Log.d("MediaButtonReceiver", "Next action received")
                (context as? MainActivity)?.handleMediaAction("next")
            }
            "com.vibewave.player.PREVIOUS" -> {
                android.util.Log.d("MediaButtonReceiver", "Previous action received")
                (context as? MainActivity)?.handleMediaAction("previous")
            }
        }
    }
}
