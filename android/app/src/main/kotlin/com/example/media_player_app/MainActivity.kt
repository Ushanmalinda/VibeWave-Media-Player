package com.example.media_player_app

import android.content.Context
import android.os.Build
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.media_player_app/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStoragePaths" -> {
                    val paths = getStoragePaths()
                    result.success(paths)
                }
                else -> result.notImplemented()
            }
        }
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
