//package com.glowsutra
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity()
//package com.glowsutra
//
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.EventChannel
//
//class MainActivity : FlutterActivity() {
//
//    private lateinit var stepTrackingService: StepTrackingService
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        stepTrackingService = StepTrackingService()
//
//        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "step_tracker_events").setStreamHandler(
//            object : EventChannel.StreamHandler {
//                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
//                    stepTrackingService.setEventSink(events)
//                }
//
//                override fun onCancel(arguments: Any?) {
//                    stepTrackingService.setEventSink(null)
//                }
//            }
//        )
//    }
//}
package com.glowsutra

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.stepcounter/steps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStepCount" -> {
                    result.success(StepCounterService.CURRENT_STEPS)
                }
                "startService" -> {
                    val intent = Intent(this, StepCounterService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

