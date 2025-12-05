package com.example.media_player_app

import android.content.Context
import android.media.audiofx.Equalizer
import android.os.Build
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.example.media_player_app/storage"
    private val EQUALIZER_CHANNEL = "com.media_player_app/equalizer"
    private var equalizer: Equalizer? = null
    private var currentAudioSessionId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
        super.onDestroy()
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
