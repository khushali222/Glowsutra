import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  await Firebase.initializeApp();
  final String? actionId = notificationResponse.actionId;
  final String? payload = notificationResponse.payload;

  print("Background notification action tapped!");
  print("Action ID: $actionId");
  print("Payload: $payload");
  final prefs = await SharedPreferences.getInstance();
  // Add logic based on the action ID
  tz.initializeTimeZones();
  if (actionId == 'ok_action') {
    try {
      final deviceId =
          prefs.getString('device_id') ??
          "unknown_device_id"; // Get the device ID from SharedPreferences

      print("$deviceId Device ID (from SharedPreferences): ");
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        // Handle the case where the user is not logged in
        print("No user is logged in.");
        return;
      }
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .doc("fireid")
              .collection("waterGlasess")
              .doc(userId)
              .get();
      // Get the current time zone
      final currentTimeZone = tz.local.name;
      int currentGlasses = 0;
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!['glasscount'] != null) {
        currentGlasses = snapshot.data()!['glasscount'] as int;
      }
      currentGlasses += 1;
      // Optional: limit to maximum 8 glasses
      if (currentGlasses > 8) {
        currentGlasses = 8;
      }
      FirebaseFirestore.instance
        .collection("User")
        .doc("fireid")
        .collection("waterGlasess")
        .doc(userId)..set({
        "glasscount": currentGlasses,
        "timezone": currentTimeZone,
        "lastUpdated": Timestamp.now(),
      });

      // Also update SharedPreferences (optional)

      int id = 0;
      prefs.setInt('water_glasses', currentGlasses);
      prefs.setString('last_updated', DateTime.now().toIso8601String());
      prefs.setInt('id', id);
      await prefs.reload();
      print("deviceid $id");
      print("currentGlasses  $currentGlasses");
    } catch (e) {
      print("Error updating water glasses: $e");
    }
  } else if (actionId == 'snooze_action') {
    print("notification snooze tapped");
    final now = DateTime.now().add(Duration(minutes: 5));
    final androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminder',
      channelDescription: 'Reminds you to drink water',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('ok_action', 'OK'),
        AndroidNotificationAction('snooze_action', 'Snooze'),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      now.millisecondsSinceEpoch ~/ 1000, // unique ID
      'Time to drink water!',
      'This is your snoozed reminder!',
      tz.TZDateTime.from(now, tz.local),
      notificationDetails,
      payload: 'Snoozed notification',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print("Snoozed notification scheduled for: $now");
  } else {
    print("User tapped the notification body.");
  }
}

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? "unknown_device_id";
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id ?? "unknown_device_id";
  }
  return "unknown_device_id";
}

class WaterIntakeScreen extends StatefulWidget {
  @override
  _WaterIntakeScreenState createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen>
    with WidgetsBindingObserver {
  int totalGlasses = 0;
  final int targetGlasses = 8; // 1 glass = 250ml, 8 glasses = 2000ml
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  bool notificationsEnabled = false;
  String selectedReminder = "None"; // Default: No reminders

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _loadWaterIntake();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationPreferences();
    _fetchAndSaveDeviceId();
  }

  Future<void> _fetchAndSaveDeviceId() async {
    final deviceId = await getDeviceId(); // Get device ID
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'device_id',
      deviceId,
    ); // Save device ID in SharedPreferences
    print("Device ID saved in SharedPreferences: $deviceId");
  }

  Future<void> _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // Handle the case where the user is not logged in
      print("No user is logged in.");
      return;
    }
    try {
      // Fetch current glass count from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .doc("fireid")
              .collection("waterGlasess")
              .doc(userId)
              .get();

      int currentGlasses = 0;
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!['glasscount'] != null) {
        currentGlasses = snapshot.data()!['glasscount'] as int;
      }
      setState(() {
        totalGlasses = currentGlasses;
        print(totalGlasses);
      });

      // Update in Firestore
    } catch (e) {
      print("Error updating water glasses: $e");
    }
  }

  Future<void> _saveWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
    final currentTimeZone = tz.local.name;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // Handle the case where the user is not logged in
      print("No user is logged in.");
      return;
    }
    try {
      // Update in Firestore
      FirebaseFirestore.instance
          .collection("User")
          .doc("fireid")
          .collection("waterGlasess")
          .doc(userId)
          .set({
            "glasscount": totalGlasses,
            "timezone": currentTimeZone,
            "lastUpdated": Timestamp.now(),
          });

      // Also update SharedPreferences (optional)
      prefs.setInt('water_glasses', totalGlasses);
      prefs.setString('last_updated', DateTime.now().toIso8601String());
      await prefs.reload();

      print("currentGlasses  $totalGlasses");
    } catch (e) {
      print("Error updating water glasses: $e");
    }

    // SharedPreferences prefss = await SharedPreferences.getInstance();
    await prefs.setInt('water_glasses', totalGlasses);
  }

  Future<void> _loadNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      selectedReminder = prefs.getString('reminder_type') ?? "None";
    });
  }

  Future<void> _saveNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'notifications_enabled',
      notificationsEnabled,
    ); //  use the right key!
    await prefs.setString('reminder_type', selectedReminder);
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? actionId = response.actionId;
        print("data ${response.data}");
        print("payload ${response.payload}");
        print("responsetype ${response.notificationResponseType}");
        print("input ${response.input}");
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          print("input ${response.notificationResponseType}");
          onTapNotification(response.payload!);
        }
        final prefs = await SharedPreferences.getInstance();
        if (actionId == 'ok_action') {
          // User tapped OK
          print("User acknowledged water reminder.");
          // Optional: update intake counter, store time, etc.
          // Increase glass count by 1
          int currentGlasses = prefs.getInt('water_glasses') ?? 0;
          currentGlasses += 1;
          // Optional: limit to target 8 glasses
          if (currentGlasses > 8) {
            currentGlasses = 8;
          }
          //  await prefs.setInt('water_glasses', currentGlasses);
        } else if (actionId == 'snooze_action') {
          final now = DateTime.now().add(Duration(minutes: 5));

          final androidDetails = AndroidNotificationDetails(
            'water_reminder_channel',
            'Water Reminder',
            channelDescription: 'Reminds you to drink water',
            importance: Importance.high,
            priority: Priority.high,
            actions: [
              AndroidNotificationAction('ok_action', 'OK'),
              AndroidNotificationAction('snooze_action', 'Snooze'),
            ],
          );

          final notificationDetails = NotificationDetails(
            android: androidDetails,
          );

          await flutterLocalNotificationsPlugin.zonedSchedule(
            now.millisecondsSinceEpoch ~/ 1000, // unique ID
            'Time to drink water!',
            'This is your snoozed reminder!',
            tz.TZDateTime.from(now, tz.local),
            notificationDetails,
            payload: 'Snoozed notification',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents:
                DateTimeComponents.time, // optional, depends on your use case
          );

          print("Snoozed notification scheduled for: $now");
        } else {
          // User tapped the notification body
          print("Notification tapped (not a button).");
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  void onTapNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    print("notification with payload time: $payload");
  }

  void _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> waterList =
        prefs.getStringList('saved_notification_ids') ?? [];
    print("water list $waterList");

    setState(() {
      notificationsEnabled = value;
    });

    prefs.setBool('notificationsEnabled', notificationsEnabled);

    if (notificationsEnabled && selectedReminder != "None") {
      bool alreadyScheduled = prefs.getBool('alreadyScheduled') ?? false;
      if (!alreadyScheduled) {
        // Optional: cancel previously saved notifications first
        for (String id in waterList) {
          await flutterLocalNotificationsPlugin.cancel(int.parse(id));
        }

        _scheduleNotifications(_getDaysFromReminder(selectedReminder));
        prefs.setBool('alreadyScheduled', true);
      }
    } else {
      // Disable notifications
      prefs.setBool('alreadyScheduled', false);

      if (waterList.isNotEmpty) {
        for (String id in waterList) {
          await flutterLocalNotificationsPlugin.cancel(int.parse(id));
        }

        // Optionally clear the saved IDs
        await prefs.remove('saved_notification_ids');
      }

      // Safely show snackbar only if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Notifications Disabled!")));
      }
    }

    _saveNotificationPreferences();
  }

  int _getDaysFromReminder(String reminderType) {
    switch (reminderType) {
      case "Daily":
        return 1;
      case "Weekly":
        return 7;
      case "Monthly":
        return 30;
      default:
        return 0;
    }
  }

  void _scheduleNotifications(int days) {
    // flutterLocalNotificationsPlugin.cancelAll();
    final List<int> reminderHours = [
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
    ];
    final List<int> reminderMinutes = [0];
    for (int day = 0; day < days; day++) {
      for (int hour in reminderHours) {
        for (int minute in reminderMinutes) {
          _scheduleNotification(day, hour, minute);
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request notifications permission (wait until it is finished)
      if (await Permission.notification.isDenied) {
        PermissionStatus notificationPermissionStatus =
            await Permission.notification.request();
        if (!notificationPermissionStatus.isGranted) {
          print('Notification permission denied');
        }
      }
      // Request exact alarm permission (for scheduling notifications at exact times)
      if (await Permission.scheduleExactAlarm.isDenied ||
          await Permission.scheduleExactAlarm.isPermanentlyDenied) {
        PermissionStatus alarmPermissionStatus =
            await Permission.scheduleExactAlarm.request();
        if (!alarmPermissionStatus.isGranted) {
          print('Exact alarm permission denied');
          // Optionally, open app settings if permission is denied
          await openAppSettings();
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _scheduleNotification(
    int dayOffset,
    int hour,
    int minute,
  ) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: dayOffset));

    await _requestPermissions(); // Make sure you request notification + exact_alarm

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection("User")
            .doc("fireid")
            .collection("waterGlasess")
            .doc(deviceId)
            .get();

    int currentGlasses = 0;
    if (snapshot.exists &&
        snapshot.data() != null &&
        snapshot.data()!['glasscount'] != null) {
      currentGlasses = snapshot.data()!['glasscount'] as int;
    }

    int totalGlasses = prefs.getInt('water_glasses') ?? 0;

    final String message =
        "Hydrate well and monitor your progress on the water screen";

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminder',
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('ok_action', 'OK'),
            AndroidNotificationAction('snooze_action', 'Snooze'),
          ],
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    int id = dayOffset * 10000 + hour * 100 + minute;

    List<String> existingIds =
        prefs.getStringList('saved_notification_ids') ?? [];
    if (!existingIds.contains(id.toString())) {
      existingIds.add(id.toString());
      await prefs.setStringList('saved_notification_ids', existingIds);
    }

    try {
      bool canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Time to drink water!',
        message,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: scheduledTime.toString(),
        //androidScheduleMode: AndroidScheduleMode.alarmClock,
        androidScheduleMode:
            canScheduleExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle, // <-- fallback
      );
      // print("Notification scheduled successfully");
    } catch (e) {
      print("Error scheduling notification: $e");
    }

    _saveNotificationWhenTimeArrives(
      message,
      scheduledTime,
      "water_notification",
      id.toString(),
    );
  }

  void _saveNotificationWhenTimeArrives(
    String reminder,
    DateTime scheduledTime,
    String screenKey,
    String id,
  ) {
    Duration delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () async {
      final prefs = await SharedPreferences.getInstance();
      bool? scheduleEnable = prefs.getBool('alreadyScheduled');

      // Use dynamic key based on the screen
      String storageKey = '${screenKey}_unreadNotifications';

      List<String> notificationsJson = prefs.getStringList(storageKey) ?? [];

      String formattedTime =
          "${scheduledTime.hour % 12 == 0 ? 12 : scheduledTime.hour % 12}:${scheduledTime.minute.toString().padLeft(2, '0')} ${scheduledTime.hour >= 12 ? "PM" : "AM"}";
      String formattedDate = DateFormat('yyyy-MM-dd').format(scheduledTime);

      Map<String, String> notificationMap = {
        "reminder": reminder,
        "time": formattedTime,
        "date": formattedDate,
        "payload": scheduledTime.toString(),
        "source": screenKey,
        "id": id,
      };

      if (scheduleEnable == true) {
        notificationsJson.add(jsonEncode(notificationMap));
        await prefs.setStringList(storageKey, notificationsJson);

        print("Saved notification to [$storageKey]: $notificationMap");
      }

      if (mounted) setState(() {});
    });
  }

  void _addWater(int glasses) {
    setState(() {
      totalGlasses += glasses;
      if (totalGlasses > targetGlasses) {
        totalGlasses = targetGlasses;
      }
    });
    //_loadWaterIntake();
    _saveWaterIntake();
  }

  void _removeWater(int glasses) {
    setState(() {
      totalGlasses -= glasses;
      if (totalGlasses < 0) {
        totalGlasses = 0;
      }
    });
    //_removeWaterIntake();
    _saveWaterIntake();
  }

  void _resetWaterIntake() {
    setState(() {
      totalGlasses = 0;
    });
    _saveWaterIntake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWaterIntake(); // Reload when app comes to foreground
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = totalGlasses / targetGlasses;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.deepPurple[100],
        elevation: 0,
        title: Text("Water Intake Tracker"),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 250,
                  // width: double.infinity,
                  color: Colors.deepPurple[50],
                  child: Image.network(
                    "https://img.freepik.com/premium-vector/glass-with-water-template-glass-transparent-cup-with-blue-refreshing-natural-liquid_79145-1179.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740",
                    // fit: BoxFit.fill,
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Progress Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      "$totalGlasses / $targetGlasses Glasses",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color: Colors.deepPurple,
                      backgroundColor: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Inline Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addWater(1),
                    icon: Icon(Icons.add),
                    label: Text("Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _removeWater(1),
                    icon: Icon(Icons.remove),
                    label: Text("Remove"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
                      foregroundColor: Colors.deepPurple[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _resetWaterIntake,
                    child: Text("Reset"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: BorderSide(color: Colors.deepPurple.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Divider(color: Colors.deepPurple[100]),
              SizedBox(height: 8),
              // Reminder Section
              Row(
                children: [
                  Text(
                    "Reminders",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Reminder Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Enable Reminders",
                    style: TextStyle(color: Colors.deepPurple[700]),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReminder,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedReminder = newValue!;
                          });
                          if (notificationsEnabled) _toggleNotifications(true);
                          _saveNotificationPreferences();
                        },
                        items:
                            [
                              "None",
                              "Daily",
                              "Weekly",
                              "Monthly",
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              // Dropdown
            ],
          ),
        ),
      ),
    );
  }
}
