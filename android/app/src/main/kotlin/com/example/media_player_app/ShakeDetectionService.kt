package com.example.media_player_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class ShakeDetectionService(
    private val context: Context,
    private val methodChannel: MethodChannel
) : SensorEventListener {
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var lastShakeTime: Long = 0
    private var lastX: Float = 0f
    private var lastY: Float = 0f
    private var lastZ: Float = 0f
    private var isEnabled = false
    private var sensitivity = 3 // 1-5, where 1 is most sensitive
    private val mainHandler = Handler(Looper.getMainLooper()) // Main thread handler for Flutter communication
    private var wakeLock: PowerManager.WakeLock? = null
    
    fun start() {
        if (isEnabled) return
        
        // Acquire wake lock to keep CPU running when screen is off
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "MediaPlayer:ShakeDetectionWakeLock"
        )
        wakeLock?.acquire()
        android.util.Log.d("ShakeDetection", "Wake lock acquired")
        
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        
        accelerometer?.let {
            sensorManager?.registerListener(
                this,
                it,
                SensorManager.SENSOR_DELAY_GAME // Faster updates
            )
            isEnabled = true
            android.util.Log.d("ShakeDetection", "Shake detection started")
        }
    }
    
    fun stop() {
        if (!isEnabled) return
        
        sensorManager?.unregisterListener(this)
        isEnabled = false
        
        // Release wake lock
        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
            android.util.Log.d("ShakeDetection", "Wake lock released")
        }
        wakeLock = null
        
        android.util.Log.d("ShakeDetection", "Shake detection stopped")
    }
    
    fun setSensitivity(value: Int) {
        sensitivity = value.coerceIn(1, 5)
    }
    
    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        
        // Calculate shake intensity
        val gForce = sqrt((x * x + y * y + z * z).toDouble())
        
        // Sensitivity: 1 = very sensitive (10), 5 = least sensitive (18)
        val threshold = 10 + (sensitivity * 2)
        
        if (gForce > threshold) {
            val now = System.currentTimeMillis()
            
            // Cooldown of 300ms between shakes
            if (now - lastShakeTime > 300) {
                lastShakeTime = now
                
                // Calculate deltas for direction detection
                val deltaX = kotlin.math.abs(x - lastX)
                val deltaY = kotlin.math.abs(y - lastY)
                val deltaZ = kotlin.math.abs(z - lastZ)
                
                // Determine shake direction
                val action = if (deltaX > deltaY && deltaX > deltaZ) {
                    // Horizontal shake
                    if (x > lastX + 2) "next" else if (x < lastX - 2) "previous" else "next"
                } else {
                    // Vertical or forward shake -> next
                    "next"
                }
                
                android.util.Log.d("ShakeDetection", "Shake detected: $action")
                
                // Send to Flutter on main thread (CRITICAL: MethodChannel must be called on main thread)
                mainHandler.post {
                    try {
                        methodChannel.invokeMethod("shake", mapOf("action" to action))
                        android.util.Log.d("ShakeDetection", "Shake event sent to Flutter: $action")
                    } catch (e: Exception) {
                        android.util.Log.e("ShakeDetection", "Error sending shake event: ${e.message}")
                    }
                }
            }
        }
        
        lastX = x
        lastY = y
        lastZ = z
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed
    }
}
