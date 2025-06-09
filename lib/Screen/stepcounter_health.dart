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
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

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

    // Fetch last saved steps and lastUpdated timestamp from Firestore
    DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
    int lastSavedSteps = snapshot.data()?['steps'] ?? 0;
    Timestamp? lastUpdatedTimestamp = snapshot.data()?['lastUpdated'];

    int? initialSensorStep;

    pedometer.listen((event) async {
      final now = DateTime.now();

      // Check if it's a new day compared to lastUpdated in Firestore
      DateTime lastUpdatedDate =
          lastUpdatedTimestamp?.toDate() ?? DateTime(2000);
      bool isNewDay =
          !(lastUpdatedDate.year == now.year &&
              lastUpdatedDate.month == now.month &&
              lastUpdatedDate.day == now.day);

      if (isNewDay) {
        // Reset step counts for new day
        lastSavedSteps = 0;
        initialSensorStep =
            event.steps; // Reset baseline to current sensor steps
        lastUpdatedTimestamp = Timestamp.fromDate(now);

        await docRef.set({
          "steps": 0,
          "calories": 0.0,
          "lastUpdated": lastUpdatedTimestamp,
          "timezone": tz.local.name,
        }, SetOptions(merge: true));

        print("Step count reset in background service for new day.");
      }

      // Set initial sensor step if not set yet
      if (initialSensorStep == null) {
        initialSensorStep = event.steps;
      }

      int stepsSinceReboot = event.steps - initialSensorStep!;
      if (stepsSinceReboot < 0) stepsSinceReboot = 0;

      int totalSteps = lastSavedSteps + stepsSinceReboot;
      // Fetch user weight for calorie calculation
      final userDoc =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      final weightStr = userDoc['weight'] ?? '70';
      final weight = double.tryParse(weightStr) ?? 70.0;
      final calories = totalSteps * weight * 0.0005;

      // Update Firestore with total steps and lastUpdated time
      await docRef.set({
        "steps": totalSteps,
        "lastUpdated": Timestamp.fromDate(now),
        "calories": calories,
        "weight": weight,
        "timezone": tz.local.name,
      }, SetOptions(merge: true));

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Step Counter Running",
          content: "Steps: $totalSteps",
        );
      }

      service.invoke('updateSteps', {'steps': totalSteps});
      print("Current steps: $totalSteps");
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
  double _calories = 0.0;
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
      int savedSteps = snapshot.data()?["steps"] ?? 0;
      double savedCalories = (snapshot.data()?["calories"] ?? 0.0).toDouble();
      double savedWeight = (snapshot.data()?["weight"] ?? 70.0).toDouble();
      setState(() {
        _steps = savedSteps;
        _calories = savedCalories;
        _weight = savedWeight;
        _isLoading = false;
      });
      print("load weight $_weight");
      print("load calories $_calories");
      print("load step $_steps");
      // await _updateCalories();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
        final steps = event['steps'] ?? 0;
        final calories = steps * _weight * 0.0005;

        setState(() {
          _steps = steps;
          _calories = calories;
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

  double _weight = 0.0;
  final int _dailyGoal = 6000;
  @override
  Widget build(BuildContext context) {
    double progress = (_steps / _dailyGoal).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade100,
        title: const Text(
          "Step Tracker",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 4,
      ),
      body:
          _isLoading
              ? const Center(child: SpinKitCircle(color: Colors.black))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy',
                          ).format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            // color: Colors.deepPurple.shade800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Hero image
                    Center(
                      child: CircleAvatar(
                        radius: 100,
                        child: Image.network(
                          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREg4rw59UEsRoChPqlq3mNOWfEsIZAV5fS_zxSPySmQmsAgL2NWbMGIj-h4Sy3Rb77kTU&usqp=CAU",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Daily Goal Progress
                    Text(
                      "Daily Goal Progress",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: Colors.deepPurple.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_steps steps',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Goal: $_dailyGoal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        progress >= 1.0
                            ? "Goal achieved!"
                            : progress >= 0.75
                            ? "Almost there!"
                            : progress >= 0.5
                            ? "Keep going, you're halfway there!"
                            : "Let's get moving!",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.deepPurple.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Steps Card
                    _InfoCard(
                      title: "Steps Today",
                      value: '$_steps',
                      icon: Icons.directions_walk,
                      iconColor: Colors.deepPurple,
                    ),
                    const SizedBox(height: 20),

                    // Calories Card
                    _InfoCard(
                      title: "Calories Burned",
                      value: "${_calories.toStringAsFixed(2)} kcal",
                      icon: Icons.local_fire_department,
                      iconColor: Colors.deepOrange,
                    ),
                    const SizedBox(height: 30),

                    // Background Service Status (if applicable)
                    // if (_androidVersion != null && _androidVersion! < 13)
                    //   Card(
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(16),
                    //     ),
                    //     elevation: 3,
                    //     child: ListTile(
                    //       leading: Icon(
                    //         _isServiceRunning
                    //             ? Icons.play_circle_fill
                    //             : Icons.stop_circle,
                    //         color:
                    //             _isServiceRunning ? Colors.green : Colors.red,
                    //         size: 32,
                    //       ),
                    //       title: const Text(
                    //         "Background Service",
                    //         style: TextStyle(fontWeight: FontWeight.bold),
                    //       ),
                    //       subtitle: Text(
                    //         _isServiceRunning ? "Running" : "Stopped",
                    //         style: TextStyle(
                    //           color:
                    //               _isServiceRunning ? Colors.green : Colors.red,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
      // bottomSheet: BottomSheet(
      //   enableDrag: false,
      //   onClosing: () {
      //     Navigator.pop(context);
      //   },
      //   builder: (BuildContext context) {
      //     return Container(
      //       height: 250,
      //       padding: EdgeInsets.all(16),
      //       decoration: BoxDecoration(
      //         color: Colors.white,
      //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      //       ),
      //       child: Column(
      //         children: [
      //           GestureDetector(
      //             onTap: () {
      //               Navigator.pop(context);
      //             },
      //             child: Icon(Icons.close),
      //           ),
      //           Text("This is a bottom sheet"),
      //           ElevatedButton(
      //             child: Text("Open Setting"),
      //             onPressed: () {
      //               print("clling setting");
      //               openAppSettings();
      //               Navigator.pop(context);
      //             },
      //           ),
      //         ],
      //       ),
      //     );
      //   },
      // ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _InfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
