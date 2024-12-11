package com.example.myapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.app.Service
import com.example.myapp.R

class BackgroundService : Service() {

    private val channelId = "com.example.your_project.background_channel"

    override fun onCreate() {
        super.onCreate()

        // Create the notification channel (required for Android O and above)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Background Service", NotificationManager.IMPORTANCE_DEFAULT)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        // Create the notification to keep the service running in the foreground
        val notification: Notification = Notification.Builder(this, channelId)
            .setContentTitle("MQTT Service Running")
            .setContentText("Your MQTT connection is active in the background.")
            .setSmallIcon(R.drawable.launch_background)  // Use your custom notification icon
            .build()

        // Start the service as a foreground service
        startForeground(1, notification)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // No binding needed
    }

    override fun onDestroy() {
        super.onDestroy()
        // Stop the service if needed (usually handled by the system)
    }
}
