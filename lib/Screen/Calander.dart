import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_date_timeline/easy_date_timeline.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<String>> _reminders = {};
  FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<String> _unreadNotifications = [];

  Map<String, String> _presetReminders = {
    "Water Intake": "off",
    "Facewash": "off",
    "Moisturizer": "off",
    "Sunscreen": "off",
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _calendarFormat = CalendarFormat.month;
    _initializeNotifications();
    requestNotificationPermission();
    _loadReminders();
    _loadPresetSettings();
    _loadUnreadNotifications();
  }

  Future<void> requestNotificationPermission() async {
    final androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final result = await androidPlugin?.requestNotificationsPermission();
    if (result ?? false) {
      print("Notification Permission Granted!");
    } else {
      print("Notification Permission Denied!");
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _markNotificationAsRead(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    // Request notifications permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request exact alarm permission (for scheduling notifications at exact times)
    if (await Permission.scheduleExactAlarm.isDenied ||
        await Permission.scheduleExactAlarm.isPermanentlyDenied) {
      await openAppSettings(); // This opens the settings for the user to enable permissions manually
    }
  }

  Future<void> _scheduleNotification(
    String reminder,
    DateTime scheduledTime, {
    bool isRepeating = false,
    String repeatType = "daily",
  }) async {
    // Request permissions for notifications and exact alarms
    await _requestPermissions();

    // If the scheduled time is in the past, return early
    if (scheduledTime.isBefore(DateTime.now())) {
      print("Scheduled time is in the past: $scheduledTime");
      return;
    }

    // Initialize time zones (ensure this is done before scheduling notifications)
    tz.initializeTimeZones();

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
      channelDescription: 'Get reminders for your skincare routine!',
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Colors.deepPurple.shade100,
      enableLights: true,
      ledColor: Colors.purple,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(reminder),
    );

    final details = NotificationDetails(android: androidDetails);

    // Unique ID generation for each notification
    final id =
        (reminder.hashCode ^ scheduledTime.millisecondsSinceEpoch) & 0x7FFFFFFF;

    try {
      // Ensure exact alarm permission is granted (fallback to inexact if not)
      bool canScheduleExact = await Permission.scheduleExactAlarm.isGranted;

      await _notificationsPlugin.zonedSchedule(
        id,
        'Skincare Reminder',
        reminder,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode:
            canScheduleExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents:
            isRepeating
                ? (repeatType == "daily"
                    ? DateTimeComponents.time
                    : repeatType == "weekly"
                    ? DateTimeComponents.dayOfWeekAndTime
                    : DateTimeComponents.dayOfMonthAndTime)
                : null,
      );

      print("Scheduled notification successfully at $scheduledTime");
    } catch (e) {
      // Handle any errors while scheduling the notification
      print("Error scheduling notification: $e");

      await _notificationsPlugin.zonedSchedule(
        id,
        'Skincare Reminder',
        reminder,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents:
            isRepeating
                ? (repeatType == "daily"
                    ? DateTimeComponents.time
                    : repeatType == "weekly"
                    ? DateTimeComponents.dayOfWeekAndTime
                    : DateTimeComponents.dayOfMonthAndTime)
                : null,
      );
    }

    _saveNotificationWhenTimeArrives(reminder, scheduledTime);
  }

  // Future<void> _scheduleNotification(
  //   String reminder,
  //   DateTime scheduledTime, {
  //   bool isRepeating = false,
  //   String repeatType = "daily",
  // }) async {
  //   await _requestPermissions();
  //   if (scheduledTime.isBefore(DateTime.now())) return;
  //
  //   final androidDetails = AndroidNotificationDetails(
  //     'reminder_channel',
  //     'Reminders',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     channelDescription: 'Get reminders for your skincare routine!',
  //     icon: '@mipmap/ic_launcher',
  //     largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  //     color: Colors.deepPurple.shade100,
  //     enableLights: true,
  //     ledColor: Colors.purple,
  //     ledOnMs: 1000,
  //     ledOffMs: 500,
  //     enableVibration: true,
  //     styleInformation: BigTextStyleInformation(reminder),
  //   );
  //
  //   final details = NotificationDetails(android: androidDetails);
  //
  //   final id =
  //       (reminder.hashCode ^ scheduledTime.millisecondsSinceEpoch) & 0x7FFFFFFF;
  //
  //   await _notificationsPlugin.zonedSchedule(
  //     id,
  //     'Skincare Reminder',
  //     reminder,
  //     tz.TZDateTime.from(scheduledTime, tz.local),
  //     details,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     matchDateTimeComponents:
  //         isRepeating
  //             ? (repeatType == "daily"
  //                 ? DateTimeComponents.time
  //                 : repeatType == "weekly"
  //                 ? DateTimeComponents.dayOfWeekAndTime
  //                 : DateTimeComponents.dayOfMonthAndTime)
  //             : null,
  //   );
  //   _saveNotificationWhenTimeArrives(reminder, scheduledTime);
  // }

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

      print("✅ Saved notification: $notificationMap");

      if (mounted) setState(() {});
    });
  }

  Future<void> _togglePresetReminder(String reminder, String planType) async {
    setState(() {
      _presetReminders[reminder] = planType;
    });

    _savePresetSettings();
    _cancelScheduledNotifications(reminder);

    if (planType != "off") {
      final now = DateTime.now();

      // Updated: include minutes
      final List<Map<String, int>> reminderTimes = [
        {'hour': 8, 'minute': 0},
        {'hour': 10, 'minute': 30},
        {'hour': 14, 'minute': 59},
        {'hour': 15, 'minute': 58},
        {'hour': 16, 'minute': 0},
        {'hour': 19, 'minute': 45},
        {'hour': 20, 'minute': 0},
        {'hour': 22, 'minute': 0},
      ];

      for (var time in reminderTimes) {
        DateTime reminderTime = DateTime(
          now.year,
          now.month,
          now.day,
          time['hour']!,
          time['minute']!,
        );

        if (reminderTime.isAfter(now)) {
          _scheduleNotification(
            reminder,
            reminderTime,
            isRepeating: true,
            repeatType: planType,
          );
        }
      }
    }
  }

  Future<void> _cancelScheduledNotifications(String reminder) async {
    for (int i = 0; i < 24; i++) {
      await _notificationsPlugin.cancel(reminder.hashCode + i);
    }
  }

  Future<void> _savePresetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presetReminders', jsonEncode(_presetReminders));
  }

  Future<void> _loadPresetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPresets = prefs.getString('presetReminders');
    if (savedPresets != null) {
      setState(() {
        _presetReminders = Map<String, String>.from(jsonDecode(savedPresets));
      });
    }
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReminders = prefs.getString('reminders');
    if (savedReminders != null) {
      Map<String, dynamic> decoded = jsonDecode(savedReminders);
      setState(() {
        _reminders = decoded.map((key, value) {
          return MapEntry(DateTime.parse(key), List<String>.from(value));
        });
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> formatted = _reminders.map(
      (key, value) => MapEntry(key.toIso8601String(), value),
    );
    await prefs.setString('reminders', jsonEncode(formatted));
  }

  Future<void> _addReminder() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      TextEditingController controller = TextEditingController();
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Add Reminder"),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "Enter reminder"),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      setState(() {
                        _reminders[_selectedDate] ??= [];
                        _reminders[_selectedDate]!.add(controller.text);
                      });

                      _scheduleNotification(controller.text, scheduledDateTime);
                      _saveReminders();
                      Navigator.pop(context);
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get('unreadNotifications');

    if (value is List<String>) {
      _unreadNotifications = value;
    } else {
      _unreadNotifications = [];
      await prefs.remove('unreadNotifications');
    }

    setState(() {});
  }

  Future<void> _markNotificationAsRead(String? notification) async {
    if (notification != null) {
      _unreadNotifications.remove(notification);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('unreadNotifications', _unreadNotifications);
      setState(() {});
    }
  }

  List<MapEntry<DateTime, String>> _getTodaysReminders() {
    return _reminders.entries
        .where(
          (entry) =>
              entry.key.year == _selectedDate.year &&
              entry.key.month == _selectedDate.month &&
              entry.key.day == _selectedDate.day,
        )
        .expand(
          (entry) =>
              entry.value.map((reminder) => MapEntry(entry.key, reminder)),
        )
        .toList();
  }

  Future<void> _removeReminder(DateTime date, String reminder) async {
    setState(() {
      _reminders[date]?.remove(reminder);
      if (_reminders[date]?.isEmpty ?? true) _reminders.remove(date);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reminders',
      jsonEncode(
        _reminders.map((key, value) => MapEntry(key.toIso8601String(), value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todaysReminders = _getTodaysReminders();
    return Scaffold(
      appBar: AppBar(
        title: Text("Skincare Calendar"),
        backgroundColor: Colors.deepPurple[100],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            EasyDateTimeLine(
              initialDate: _selectedDate,
              onDateChange: (date) => setState(() => _selectedDate = date),
              activeColor: Colors.deepPurple[100],
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Divider(),
            ),
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14),
              child: Row(
                children: [
                  Text(
                    "Today's Reminders",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // SizedBox(height: 7),
            if (todaysReminders.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children:
                  todaysReminders.map((entry) {
                    DateTime reminderDate = entry.key;
                    String reminderText = entry.value;
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading:
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: FaIcon(
                            FontAwesomeIcons.solidBell,
                            size: 16,
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(reminderText),
                        trailing: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.trashCan,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _removeReminder(
                              reminderDate,
                              reminderText,
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
            if (todaysReminders.isEmpty) ...[
              SizedBox(height: 50),
              Text(
                "No reminders for today!",
                style: TextStyle(color: Colors.grey),
              ),
            ],
            SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          onPressed: _addReminder,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
