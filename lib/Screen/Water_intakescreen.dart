import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  Future<void> _saveNotificationPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unreadNotifications', notificationsEnabled);
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
    final List<int> reminderHours = [9, 11, 13, 15, 17, 19, 21, 22];

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
      'Stay hydrated and drink a glass of water.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Water Intake Tracker"),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: 400,
              child: Image.network(
                "https://img.freepik.com/free-psd/refreshing-glass-water-with-ice-cubes-transparent-background_84443-27986.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740",
              ),
            ),
            Text(
              "Water Intake: $totalGlasses / $targetGlasses glasses",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _addWater(1),
                  child: Text("+1 Glass"),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _removeWater(1),
                  icon: Icon(Icons.remove),
                  label: Text("Remove 1"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade100,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _resetWaterIntake, child: Text("Reset")),
            SizedBox(height: 30),
            Text("Reminders:", style: TextStyle(fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Enable Reminders"),
                Switch(
                  value: notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Select Reminder Type:", style: TextStyle(fontSize: 16)),
            DropdownButton<String>(
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
          ],
        ),
      ),
    );
  }
}
