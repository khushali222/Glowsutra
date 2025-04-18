import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class WaterIntakeScreen extends StatefulWidget {
  @override
  _WaterIntakeScreenState createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  int totalGlasses = 0;
  final int targetGlasses = 8; // 1 glass = 250ml, 8 glasses = 2000ml
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool notificationsEnabled = false;
  String selectedReminder = "None"; // Default: No reminders

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _loadWaterIntake();
    _loadNotificationPreferences();
  }

  Future<void> _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      totalGlasses = prefs.getInt('water_glasses') ?? 0;
    });
  }

  Future<void> _saveWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_glasses', totalGlasses);
  }

  Future<void> _loadNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      selectedReminder = prefs.getString('reminder_type') ?? "None";
    });
  }

  // Future<void> _saveNotificationPreferences() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('unreadNotifications', notificationsEnabled);
  //   await prefs.setString('reminder_type', selectedReminder);
  // }
  Future<void> _saveNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'notifications_enabled',
      notificationsEnabled,
    ); // ✅ use the right key!
    await prefs.setString('reminder_type', selectedReminder);
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
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
        if (actionId == 'ok_action') {
          // 🔔 User tapped OK
          print("✅ User acknowledged water reminder.");
          // 👉 Optional: update intake counter, store time, etc.
        } else if (actionId == 'cancel_action') {
          // ❌ User tapped Cancel
          print("❌ User dismissed water reminder.");
          // 👉 Optional: log skipped time, or take no action
        } else {
          // 📱 User tapped the notification body
          print("📩 Notification tapped (not a button).");
        }
      },
    );
  }

  // for formatting date/time

  // void onTapNotification(String payload) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   // Retrieve the saved notifications
  //   List<String> notificationsJson =
  //       prefs.getStringList('unreadNotifications') ?? [];
  //
  //   // Decode the notifications into a list of maps
  //   List<Map<String, dynamic>> notifications =
  //       notificationsJson
  //           .map((item) => jsonDecode(item) as Map<String, dynamic>)
  //           .toList();
  //
  //   // Convert the payload (which is a string like "2025-04-16 16:20:00.000") into DateTime
  //   DateTime payloadTime = DateFormat("yyyy-MM-dd HH:mm:ss.SSS").parse(payload);
  //
  //   // Filter out the notification with the matching payload time
  //   notifications.removeWhere((notification) {
  //     String notificationTimeStr =
  //         notification['time']; // e.g., "2025-04-16 16:20:00.000"
  //     DateTime notificationTime = DateFormat(
  //       "yyyy-MM-dd HH:mm:ss.SSS",
  //     ).parse(notificationTimeStr);
  //     return notificationTime.isAtSameMomentAs(
  //       payloadTime,
  //     ); // Compare as DateTime objects
  //   });
  //
  //   // Convert the remaining notifications back to JSON strings
  //   List<String> updatedNotificationsJson =
  //       notifications.map((notification) => jsonEncode(notification)).toList();
  //
  //   // Store the updated notifications list back into SharedPreferences
  //   await prefs.setStringList('unreadNotifications', updatedNotificationsJson);
  //
  //   // Optionally, update UI or state
  //   setState(() {
  //     // You can update your state to reflect the changes if needed
  //   });
  //
  //   print("✅ Notification removed with payload time: $payload");
  // }
  void onTapNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> notificationsJson =
        prefs.getStringList('unreadNotifications') ?? [];

    List<Map<String, dynamic>> notifications =
        notificationsJson
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();

    DateTime payloadTime = DateTime.parse(payload);

    notifications.removeWhere((notification) {
      String? storedPayload = notification['payload'];
      if (storedPayload == null) return false;
      DateTime storedTime = DateTime.parse(storedPayload);
      return storedTime.isAtSameMomentAs(payloadTime);
    });

    List<String> updatedJson =
        notifications.map((notification) => jsonEncode(notification)).toList();

    await prefs.setStringList('unreadNotifications', updatedJson);

    // ✅ Fix: Only call setState if widget is still mounted
    if (mounted) {
      setState(() {
        // Any UI update
      });
    }

    print("✅ Removed notification with payload time: $payload");
  }

  void _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = value;
    });

    if (notificationsEnabled && selectedReminder != "None") {
      bool alreadyScheduled = prefs.getBool('alreadyScheduled') ?? false;
      if (!alreadyScheduled) {
        await flutterLocalNotificationsPlugin.cancelAll();
        _scheduleNotifications(_getDaysFromReminder(selectedReminder));
        prefs.setBool('alreadyScheduled', true);
      }
    } else {
      prefs.setBool('alreadyScheduled', false);

      prefs.setStringList('unreadNotifications', []);
      flutterLocalNotificationsPlugin.cancelAll();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Notifications Disabled!")));
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

  // void _scheduleNotifications(int days) {
  //   flutterLocalNotificationsPlugin.cancelAll();
  //   final List<int> reminderHours = [9, 11, 13, 15, 17, 19, 21, 22];
  //
  //   for (int day = 0; day < days; day++) {
  //     for (int hour in reminderHours) {
  //       _scheduleNotification(day, hour);
  //     }
  //   }
  // }
  void _scheduleNotifications(int days) {
    flutterLocalNotificationsPlugin.cancelAll();

    final List<int> reminderHours = [9, 12, 14, 15, 16, 17, 18, 19, 21, 22];
    final List<int> reminderMinutes = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
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
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      53,
      54,
      55,
      56,
      57,
      58,
      59,
      60,
    ]; // You can change this to [0, 30] or others for more

    for (int day = 0; day < days; day++) {
      for (int hour in reminderHours) {
        for (int minute in reminderMinutes) {
          _scheduleNotification(day, hour, minute);
        }
      }
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

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }
    // Getting the water intake value from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    int totalGlasses = prefs.getInt('water_glasses') ?? 0;
    final String message = "Drink water! Current intake: $totalGlasses glasses";
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminder',
          importance: Importance.high,
          priority: Priority.high,
          // actions: [
          //   AndroidNotificationAction(
          //     'ok_action', // action ID
          //     'OK', // label shown to user
          //   ),
          //   AndroidNotificationAction('cancel_action', 'Cancel'),
          // ],
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    int id = dayOffset * 10000 + hour * 100 + minute;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, //for only one day
      // hour + dayOffset * 24, //for only one day
      'Time to drink water!',
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      payload: scheduledTime.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    //_saveWaterIntakeNotification(message);
    _saveNotificationWhenTimeArrives(message, scheduledTime);
  }

  void _saveNotificationWhenTimeArrives(
    String reminder,
    DateTime scheduledTime,
  ) {
    Duration delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () async {
      final prefs = await SharedPreferences.getInstance();

      List<String> notificationsJson =
          prefs.getStringList('unreadNotifications') ?? [];

      String formattedTime =
          "${scheduledTime.hour % 12 == 0 ? 12 : scheduledTime.hour % 12}:${scheduledTime.minute.toString().padLeft(2, '0')} ${scheduledTime.hour >= 12 ? "PM" : "AM"}";
      String formattedDate = DateFormat('yyyy-MM-dd').format(scheduledTime);

      Map<String, String> notificationMap = {
        "reminder": reminder,
        "time": formattedTime,
        "date": formattedDate,
        "payload": scheduledTime.toString(),
      };

      notificationsJson.add(jsonEncode(notificationMap));
      await prefs.setStringList('unreadNotifications', notificationsJson);

      print("Saved notification: $notificationMap");

      if (mounted) setState(() {});
    });
  }

  // Future<void> _saveWaterIntakeNotification(String message) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> notifications =
  //       prefs.getStringList('unreadNotifications') ?? [];
  //   notifications.add(message);
  //   await prefs.setStringList('unreadNotifications', notifications);
  // }
  Future<void> _saveWaterIntakeNotification(String message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final value = prefs.get('unreadNotifications');

    List<String> notifications = [];
    if (value is List<String>) {
      notifications = value;
    }

    notifications.add(message);
    await prefs.setStringList('unreadNotifications', notifications);
  }

  void _addWater(int glasses) {
    setState(() {
      totalGlasses += glasses;
      if (totalGlasses > targetGlasses) {
        totalGlasses = targetGlasses;
      }
    });
    _saveWaterIntake();
  }

  void _removeWater(int glasses) {
    setState(() {
      totalGlasses -= glasses;
      if (totalGlasses < 0) {
        totalGlasses = 0;
      }
    });
    _saveWaterIntake();
  }

  void _resetWaterIntake() {
    setState(() {
      totalGlasses = 0;
    });
    _saveWaterIntake();
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
