import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
    final prefs = await SharedPreferences.getInstance();

    int? initialStepCount = prefs.getInt("initial_steps");

    pedometer.listen((event) async {
      if (initialStepCount == null) {
        initialStepCount = event.steps;
        await prefs.setInt("initial_steps", initialStepCount!);
      }

      int stepsSinceStart = event.steps - initialStepCount!;
      if (stepsSinceStart < 0) stepsSinceStart = 0;

      await prefs.setInt("steps", stepsSinceStart);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Step Counter Running",
          content: "Steps: $stepsSinceStart",
        );
      }

      service.invoke('updateSteps', {'steps': stepsSinceStart});
      print("current step $stepsSinceStart");
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
    final prefs = await SharedPreferences.getInstance();

    int? initialStepCount = prefs.getInt("initial_steps_ios");

    pedometer.listen((event) async {
      if (initialStepCount == null) {
        initialStepCount = event.steps;
        await prefs.setInt("initial_steps_ios", initialStepCount!);
      }

      int stepsSinceStart = event.steps - initialStepCount!;
      if (stepsSinceStart < 0) stepsSinceStart = 0;

      await prefs.setInt("steps", stepsSinceStart);
      service.invoke('updateSteps', {'steps': stepsSinceStart});
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
  final FlutterBackgroundService _backgroundService =
  FlutterBackgroundService();

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
      _isLoading = false;
    });
    print("object fetch step $storedSteps");
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
        AndroidFlutterLocalNotificationsPlugin
    >()
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
        // _isLoading = false;
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
    // _loadSavedSteps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      print("calling change ");
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool _isLoading = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Step Tracker")),
      body:
      _isLoading
          ? Center(child: SpinKitCircle(color: Colors.black))
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Steps today: $_steps",
              style: TextStyle(fontSize: 28),
            ),
            if (_androidVersion != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Android Version: $_androidVersion",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            if (_androidVersion != null && _androidVersion! < 13)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Background Service: ${_isServiceRunning ? 'Running' : 'Stopped'}",
                ),
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
                child: Text(
                  _isServiceRunning
                      ? 'Stop Counting'
                      : 'Start Counting',
                ),
              ),
          ],
        ),
      ),
    );
  }
}