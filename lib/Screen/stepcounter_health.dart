// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'dart:async';
// import 'dart:isolate';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
//
// @pragma('vm:entry-point')
// Future<bool> onStart(ServiceInstance service) async {
//   print("back cclling");
//   DartPluginRegistrant.ensureInitialized();
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
//
//   try {
//     // Initialize pedometer
//     final pedometer = Pedometer.stepCountStream;
//
//     // Listen to step count changes
//     pedometer.listen((event) {
//       // Update notification with current steps
//       if (service is AndroidServiceInstance) {
//         service.setForegroundNotificationInfo(
//           title: "Step Counter Running",
//           content: "Steps: ${event.steps}",
//         );
//       }
//
//       // Send step count to app
//       service.invoke('updateSteps', {
//         'steps': event.steps,
//       });
//       print("back step ${event.steps}");
//     });
//
//     return true;
//   } catch (e) {
//     print('Error in background service: $e');
//     return false;
//   }
// }
//
// @pragma('vm:entry-point')
// Future<bool> onIosStart(ServiceInstance service) async {
//   try {
//     // Initialize pedometer
//     final pedometer = Pedometer.stepCountStream;
//
//     // Listen to step count changes
//     pedometer.listen((event) {
//       service.invoke('updateSteps', {
//         'steps': event.steps,
//       });
//     });
//
//     return true;
//   } catch (e) {
//     print('Error in iOS background service: $e');
//     return false;
//   }
// }
//
// class StepCounterPage extends StatefulWidget {
//   @override
//   State<StepCounterPage> createState() => _StepCounterPageState();
// }
//
// class _StepCounterPageState extends State<StepCounterPage> with RouteAware {
//   final Health _health = Health();
//   int _steps = 0;
//   Timer? _timer;
//   int? _androidVersion;
//   late Stream<StepCount> _stepCountStream;
//   late Stream<PedestrianStatus> _pedestrianStatusStream;
//   String _status = '?';
//   bool _isServiceRunning = false;
//   final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeService();
//     _getAndroidVersion();
//     _initStepCounter();
//      fetchSteps();
//     // // Request notification permission for Android 13+
//     // if (_androidVersion != null && _androidVersion! >= 33) {
//     //   Permission.notification.request();
//     // }
//   }
//
//   Future<void> _initializeService() async {
//     final service = FlutterBackgroundService();
//
//     // Configure notification channel
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'step_counter_channel',
//       'Step Counter Service',
//       description: 'This notification is used for step counting.',
//       importance: Importance.high,
//       enableVibration: false,
//       playSound: false,
//     );
//
//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();
//
//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//
//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: false,
//         isForegroundMode: true,
//         notificationChannelId: 'step_counter_channel',
//         initialNotificationTitle: 'Step Counter',
//         initialNotificationContent: 'Counting your steps...',
//         foregroundServiceNotificationId: 888,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: false,
//         onForeground: onStart,
//         onBackground: onStart,
//       ),
//     );
//
//     // Listen for step updates
//     service.on('updateSteps').listen((event) {
//       if (event != null && mounted) {
//         setState(() {
//           _steps = event['steps'] ?? 0;
//         });
//       }
//     });
//
//     // Check if service is running
//     final isRunning = await service.isRunning();
//     if (mounted) {
//       setState(() {
//         _isServiceRunning = isRunning;
//       });
//     }
//   }
//
//   Future<void> _startBackgroundService() async {
//     try {
//       // Request activity recognition permission
//       if (await Permission.activityRecognition.isDenied) {
//         final result = await Permission.activityRecognition.request();
//         if (!result.isGranted) {
//           _showSnackbar("Activity Recognition permission is required for step counting");
//           return;
//         }
//       }
//
//       // Start the background service
//       await _backgroundService.startService();
//
//       if (mounted) {
//         setState(() {
//           _isServiceRunning = true;
//         });
//       }
//       _showSnackbar("Step counter started. It will continue counting even when the app is closed.");
//     } catch (e) {
//       print('Error starting background service: $e');
//       _showSnackbar('Failed to start background service: $e');
//     }
//   }
//
//   // Future<void> _startBackgroundService() async {
//   //   try {
//   //     // Request activity recognition permission
//   //     if (await Permission.activityRecognition.isDenied) {
//   //       final result = await Permission.activityRecognition.request();
//   //       if (!result.isGranted) {
//   //         _showSnackbar("Activity Recognition permission is required for step counting");
//   //         return;
//   //       }
//   //     }
//   //
//   //     // Request battery optimization exemption
//   //     if (await Permission.ignoreBatteryOptimizations.isDenied) {
//   //       await Permission.ignoreBatteryOptimizations.request();
//   //     }
//   //
//   //     // Start the background service
//   //     await _backgroundService.startService();
//   //
//   //     if (mounted) {
//   //       setState(() {
//   //         _isServiceRunning = true;
//   //       });
//   //     }
//   //     _showSnackbar("Step counter started. It will continue counting even when the app is closed.");
//   //   } catch (e) {
//   //     print('Error starting background service: $e');
//   //     _showSnackbar('Failed to start background service: $e');
//   //   }
//   // }
//
//   Future<void> _stopBackgroundService() async {
//     try {
//       _backgroundService.invoke('stopService');
//       if (mounted) {
//         setState(() {
//           _isServiceRunning = false;
//         });
//       }
//       _showSnackbar("Step counter stopped");
//     } catch (e) {
//       print('Error stopping background service: $e');
//       _showSnackbar('Failed to stop background service: $e');
//     }
//   }
//
//   Future<void> _getAndroidVersion() async {
//     try {
//       final deviceInfo = DeviceInfoPlugin();
//       final androidInfo = await deviceInfo.androidInfo;
//       setState(() {
//         _androidVersion = androidInfo.version.sdkInt;
//       });
//       print("Android version: $_androidVersion");
//     } catch (e) {
//       print("Error getting Android version: $e");
//       setState(() {
//         _androidVersion = 11;
//       });
//     }
//   }
//
//   Future<void> _initStepCounter() async {
//     try {
//       await _startBackgroundService();
//     } catch (e) {
//       print("Error initializing step counter: $e");
//       _showSnackbar("Error initializing step counter: $e");
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final route = ModalRoute.of(context);
//     if (route is PageRoute) {
//       routeObserver.subscribe(this, route);
//     }
//   }
//
//   @override
//   void dispose() {
//     routeObserver.unsubscribe(this);
//     _timer?.cancel();
//     if (_androidVersion != null && _androidVersion! < 13) {
//       _stopBackgroundService();
//     }
//     super.dispose();
//   }
//
//   @override
//   void didPopNext() {
//     if (_androidVersion != null && _androidVersion! >= 13) {
//       fetchSteps();
//     }
//   }
//
//   Future<void> _requestPermissionsAndFetch() async {
//     print("Requesting permissions");
//
//     // Request activity recognition permission
//     if (await Permission.activityRecognition.isPermanentlyDenied) {
//       _showSettingsDialog("Activity Recognition permission permanently denied. Please enable it in settings.");
//       return;
//     }
//
//     if (await Permission.activityRecognition.isDenied) {
//       final result = await Permission.activityRecognition.request();
//       if (!result.isGranted) {
//         _showSnackbar("Activity Recognition permission is required.");
//         return;
//       }
//     }
//
//     // Request health permissions
//     try {
//       final granted = await hasPermissions();
//       print("Health permissions granted: $granted");
//
//       if (!granted) {
//         _showSnackbar("Permission to access health data was denied.");
//         return;
//       }
//
//       await fetchSteps();
//     } catch (e) {
//       print("Permission request error: $e");
//       _showSnackbar("Error requesting permissions: $e");
//     }
//   }
//
//   Future<bool> hasPermissions() async {
//     try {
//       bool success = await _health.requestAuthorization(
//         [HealthDataType.STEPS],
//         permissions: [HealthDataAccess.READ],
//       );
//       print("Health Connect authorization result: $success");
//
//       bool? granted = await _health.hasPermissions(
//         [HealthDataType.STEPS],
//         permissions: [HealthDataAccess.READ],
//       );
//
//       return granted ?? false;
//     } catch (e) {
//       print("hasPermissions error: $e");
//       return false;
//     }
//   }
//
//   Future<void> fetchSteps() async {
//     if (!mounted) return;
//
//     final types = [HealthDataType.STEPS];
//     final now = DateTime.now();
//     final midnight = DateTime(now.year, now.month, now.day);
//
//     try {
//       final healthData = await _health.getHealthDataFromTypes(
//         types: types,
//         startTime: midnight,
//         endTime: now,
//       );
//
//       final cleanData = _health.removeDuplicates(healthData);
//       int totalSteps = 0;
//
//       for (var point in cleanData) {
//         if (point.type == HealthDataType.STEPS) {
//           final value = point.value;
//           if (value is NumericHealthValue) {
//             totalSteps += value.numericValue.toInt();
//           }
//         }
//       }
//
//       if (mounted) {
//         setState(() {
//           _steps = totalSteps;
//         });
//       }
//       print('Fetched steps: $totalSteps');
//     } catch (e) {
//       print("Error fetching steps: $e");
//       if (mounted) {
//         _showSnackbar("Error fetching step data: $e");
//       }
//     }
//   }
//
//   void _showSnackbar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     }
//   }
//
//   void _showSettingsDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Permission Required"),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               openAppSettings();
//             },
//             child: Text("Open Settings"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text("Cancel"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Step Tracker")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "Steps today: $_steps",
//               style: TextStyle(fontSize: 28),
//             ),
//             if (_androidVersion != null && _androidVersion! < 13)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   "Status: $_status",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               ),
//             if (_androidVersion != null)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   "Android Version: $_androidVersion",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               ),
//             if (_androidVersion != null && _androidVersion! < 13)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   "Background Service: ${_isServiceRunning ? 'Running' : 'Stopped'}",
//                   style: TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//               ),
//             if (_androidVersion != null && _androidVersion! < 13)
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_isServiceRunning) {
//                     await _stopBackgroundService();
//                   } else {
//                     await _startBackgroundService();
//                   }
//                 },
//                 child: Text(_isServiceRunning ? 'Stop Counting' : 'Start Counting'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  try {
    final pedometer = Pedometer.stepCountStream;
    pedometer.listen((event) async {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Step Counter Running",
          content: "Steps: ${event.steps}",
        );
      }

      final prefs = await SharedPreferences.getInstance();
      int savedSteps = prefs.getInt("steps") ?? 0;
      int updatedSteps = savedSteps + event.steps;
      prefs.setInt("steps", updatedSteps);

      service.invoke('updateSteps', {'steps': updatedSteps});
    });

    return true;
  } catch (e) {
    print('Error in background service: $e');
    return false;
  }
}

@pragma('vm:entry-point')
Future<bool> onIosStart(ServiceInstance service) async {
  try {
    final pedometer = Pedometer.stepCountStream;
    pedometer.listen((event) async {
      final prefs = await SharedPreferences.getInstance();
      int savedSteps = prefs.getInt("steps") ?? 0;
      int updatedSteps = savedSteps + event.steps;
      prefs.setInt("steps", updatedSteps);
      service.invoke('updateSteps', {'steps': updatedSteps});
    });
    return true;
  } catch (e) {
    print('Error in iOS background service: $e');
    return false;
  }
}

class StepCounterPage extends StatefulWidget {
  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> with RouteAware {
  final Health _health = Health();
  int _steps = 0;
  int? _androidVersion;
  String _status = '?';
  bool _isServiceRunning = false;
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _getAndroidVersion();
    _initStepCounter();
    _loadSavedSteps();
  }

  Future<void> _loadSavedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    int storedSteps = prefs.getInt("steps") ?? 0;
    setState(() {
      _steps = storedSteps;
    });
  }

  Future<void> _initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'step_counter_channel',
      'Step Counter Service',
      description: 'This notification is used for step counting.',
      importance: Importance.high,
      enableVibration: false,
      playSound: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'step_counter_channel',
        initialNotificationTitle: 'Step Counter',
        initialNotificationContent: 'Counting your steps...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onStart,
      ),
    );

    // Listen for step updates
    service.on('updateSteps').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _steps = event['steps'] ?? 0;
        });
      }
    });

    // Check if service is running
    final isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        _isServiceRunning = isRunning;
      });
    }
  }

  Future<void> _startBackgroundService() async {
    if (await Permission.activityRecognition.isDenied) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        _showSnackbar("Activity Recognition permission is required");
        return;
      }
    }

    await _backgroundService.startService();

    if (mounted) {
      setState(() => _isServiceRunning = true);
    }

    _showSnackbar("Step counter started.");
  }

  Future<void> _stopBackgroundService() async {
    _backgroundService.invoke('stopService');
    if (mounted) {
      setState(() => _isServiceRunning = false);
    }
    _showSnackbar("Step counter stopped.");
  }

  Future<void> _getAndroidVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      setState(() => _androidVersion = androidInfo.version.sdkInt);
    } catch (e) {
      setState(() => _androidVersion = 11);
    }
  }

  Future<void> _initStepCounter() async {
    await _startBackgroundService();
  }

  @override
  void didPopNext() {
    _loadSavedSteps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (_androidVersion != null && _androidVersion! < 13) {
      _stopBackgroundService();
    }
    super.dispose();
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Step Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Steps today: $_steps", style: TextStyle(fontSize: 28)),
            if (_androidVersion != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Android Version: $_androidVersion", style: TextStyle(color: Colors.grey)),
              ),
            if (_androidVersion != null && _androidVersion! < 13)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Background Service: ${_isServiceRunning ? 'Running' : 'Stopped'}"),
              ),
            if (_androidVersion != null && _androidVersion! < 13)
              ElevatedButton(
                onPressed: () async {
                  if (_isServiceRunning) {
                    await _stopBackgroundService();
                  } else {
                    await _startBackgroundService();
                  }
                },
                child: Text(_isServiceRunning ? 'Stop Counting' : 'Start Counting'),
              ),
          ],
        ),
      ),
    );
  }
}
