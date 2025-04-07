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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _toggleNotifications(bool value) {
    setState(() {
      notificationsEnabled = value;
    });

    if (notificationsEnabled && selectedReminder != "None") {
      _scheduleNotifications(_getDaysFromReminder(selectedReminder));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$selectedReminder Reminders Enabled!")),
      );
    } else {
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

  void _scheduleNotifications(int days) {
    flutterLocalNotificationsPlugin.cancelAll();
    final List<int> reminderHours = [9, 11, 13, 15, 16, 19, 21, 22];

    for (int day = 0; day < days; day++) {
      for (int hour in reminderHours) {
        _scheduleNotification(day, hour);
      }
    }
  }

  Future<void> _scheduleNotification(int dayOffset, int hour) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
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
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      hour + dayOffset * 24,
      'Time to drink water!',
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    _saveNotificationWhenTimeArrives("Time to drink water!", scheduledTime);
  }

  // Future<void> _saveWaterIntakeNotification(String message) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String> notifications =
  //       prefs.getStringList('unreadNotifications') ?? [];
  //   notifications.add(message);
  //   await prefs.setStringList('unreadNotifications', notifications);
  // }
  void _saveNotificationWhenTimeArrives(
    String reminder,
    DateTime scheduledTime,
  ) {
    Duration delay = scheduledTime.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () async {
      final prefs = await SharedPreferences.getInstance();
      List<String> notifications =
          prefs.getStringList('unreadNotifications') ?? [];

      String formattedTime =
          "${scheduledTime.hour % 12 == 0 ? 12 : scheduledTime.hour % 12}:${scheduledTime.minute.toString().padLeft(2, '0')} ${scheduledTime.hour >= 12 ? "PM" : "AM"}";
      String formattedDate = DateFormat('yyyy-MM-dd').format(scheduledTime);
      String finalMessage = "$reminder - $formattedTime - $formattedDate";

      if (!notifications.contains(finalMessage)) {
        notifications.add(finalMessage);
        await prefs.setStringList('unreadNotifications', notifications);
        if (mounted) setState(() {});
      }
    });
  }

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

              // Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedReminder,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedReminder = newValue!;
                      });
                      if (notificationsEnabled) _toggleNotifications(true);
                      _saveNotificationPreferences();
                    },
                    items:
                        ["None", "Daily", "Weekly", "Monthly"]
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
