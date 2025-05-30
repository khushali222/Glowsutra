import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:pedometer/pedometer.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    tz.initializeTimeZones();
    if (userId == null) {
      print("No user is logged in.");
      return false;
    }

    final docRef = FirebaseFirestore.instance
        .collection("User")
        .doc("fireid")
        .collection("stepCounter")
        .doc(userId);

    DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
    int? initialStepCount = snapshot.data()?['initial_steps'];

    pedometer.listen((event) async {
      if (initialStepCount == null) {
        initialStepCount = event.steps;
        await docRef.set({
          "initial_steps": initialStepCount,
        }, SetOptions(merge: true));
      }

      int stepsSinceStart = event.steps - initialStepCount!;
      if (stepsSinceStart < 0) stepsSinceStart = 0;

      final currentTimeZone = tz.local.name;

      await docRef.set({
        "steps": stepsSinceStart,
        "timezone": currentTimeZone,
        "lastUpdated": Timestamp.now(),
      }, SetOptions(merge: true));

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Step Counter Running",
          content: "Steps: $stepsSinceStart",
        );
      }

      service.invoke('updateSteps', {'steps': stepsSinceStart});
      print("Current step $stepsSinceStart");
    });

    return true;
  } catch (e) {
    print('Error in background service: $e');
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _getAndroidVersion();
    _initStepCounter();
    _loadSavedSteps();
  }

  Future<void> _loadSavedSteps() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("No user logged in.");
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection("User")
        .doc("fireid")
        .collection("stepCounter")
        .doc(userId);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      setState(() {
        _steps = snapshot.data()?["steps"] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }

    print("Fetched steps: $_steps");
  }

  Future<void> _initializeService() async {
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

    await _backgroundService.configure(
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

    _backgroundService.on('updateSteps').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _steps = event['steps'] ?? 0;
        });
      }
    });

    final isRunning = await _backgroundService.isRunning();
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

    // _showSnackbar("Step counter started.");
  }

  Future<void> _stopBackgroundService() async {
    _backgroundService.invoke('stopService');
    if (mounted) {
      setState(() => _isServiceRunning = false);
    }
    // _showSnackbar("Step counter stopped.");
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

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void didPopNext() {}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepPurple[100],
        elevation: 0,
        title: Text("Step Tracker"),
      ),
      body:
          _isLoading
              ? Center(child: SpinKitCircle(color: Colors.black))
              : Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(
                            DateTime.now(),
                          ), // e.g., Wednesday, May 29, 2025
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 250,
                        // width: double.infinity,
                        color: Colors.deepPurple[50],
                        child: Image.network(
                          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTHeR9TqVs3iUA3fRSZ9lkUrZzvH-lgmeozxA&s",
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Steps card
                    Row(
                      children: [
                        SizedBox(width: 10),
                        Text(
                          "Daily step count",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.deepPurple.shade50,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              "Steps Today",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade500,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(
                                '$_steps',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.deepPurple.shade900,
                                ),
                              ),
                            ),
                          ),
                          //SizedBox(height: 12),
                        ],
                      ),
                    ),
                    SizedBox(height: 50),
                    if (_androidVersion != null && _androidVersion! < 13)
                      SizedBox(height: 16),
                    if (_androidVersion != null && _androidVersion! < 13)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _isServiceRunning
                                ? Icons.play_circle_fill
                                : Icons.stop_circle,
                            color:
                                _isServiceRunning ? Colors.green : Colors.red,
                          ),
                          title: Text("Background Service"),
                          subtitle: Text(
                            _isServiceRunning ? "Running" : "Stopped",
                            style: TextStyle(
                              color:
                                  _isServiceRunning ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 10),
                    // Text("Calories count"),
                  ],
                ),
              ),
    );
  }
}
