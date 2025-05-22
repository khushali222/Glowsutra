package com.glowsutra

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.*
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class StepCounterService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var sensor: Sensor? = null
    private var baseSteps = -1
    private var totalSteps = 0

    companion object {
        var CURRENT_STEPS = 0
    }

    override fun onCreate() {
        super.onCreate()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        sensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
        }

        startForegroundService()
    }

    private fun startForegroundService() {
        val channelId = "step_channel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, "Steps", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(chan)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Step Counter Active")
            .setContentText("Tracking steps in background")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .build()

        startForeground(1, notification)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event != null) {
            totalSteps = event.values[0].toInt()

            val prefs = getSharedPreferences("step_prefs", Context.MODE_PRIVATE)
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
            val savedDate = prefs.getString("stepDate", null)
            baseSteps = prefs.getInt("baseSteps", -1)

            if (savedDate != today || baseSteps == -1) {
                // First reading today — reset base
                prefs.edit()
                    .putInt("baseSteps", totalSteps)
                    .putString("stepDate", today)
                    .apply()
                baseSteps = totalSteps
            }

            CURRENT_STEPS = totalSteps - baseSteps
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(this)
    }
}
