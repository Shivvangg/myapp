package com.example.myapp

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.myapp/mqtt"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start the BackgroundService
        val serviceIntent = Intent(this, BackgroundService::class.java)
        startService(serviceIntent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Platform channel for handling MQTT alerts
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "newAlert") {
                    val topic = call.argument<String>("topic") ?: ""
                    val timestamp = call.argument<String>("timestamp") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val imageUrl = call.argument<String>("imageUrl") ?: ""
                    val alertType = call.argument<Int>("alertType") ?: 0

                    // Pass alert data to Flutter to display the dialog
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod(
                            "showDialog", mapOf(
                                "topic" to topic,
                                "timestamp" to timestamp,
                                "message" to message,
                                "imageUrl" to imageUrl,
                                "alertType" to alertType
                            )
                        )
                }
                result.success(null)
            }
    }
}
