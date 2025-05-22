// import 'package:flutter/services.dart';
//
// class StepTracker {
//   static const MethodChannel _channel = MethodChannel('step_tracker_plugin');
//
//   static Future<void> startService() async {
//     try {
//       await _channel.invokeMethod('startService');
//     } on PlatformException catch (e) {
//       print("Failed to start service: ${e.message}");
//     }
//   }
// }
import 'package:flutter/services.dart';

class StepTracker {
  static const EventChannel _stepEventChannel = EventChannel('step_tracker_events');

  // Emits Map<String, dynamic> with keys: 'steps' (int) and 'status' (String)
  static Stream<Map<String, dynamic>> get stepDataStream =>
      _stepEventChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));
}


