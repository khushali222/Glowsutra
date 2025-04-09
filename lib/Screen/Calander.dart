import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_date_timeline/easy_date_timeline.dart';

import '../Serviece/helper.dart';

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

  Future<void> _scheduleNotification(
    String reminder,
    DateTime scheduledTime, {
    bool isRepeating = false,
    String repeatType = "daily",
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

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

    final id =
        (reminder.hashCode ^ scheduledTime.millisecondsSinceEpoch) & 0x7FFFFFFF;

    await _notificationsPlugin.zonedSchedule(
      id,
      'Skincare Reminder',
      reminder,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          isRepeating
              ? (repeatType == "daily"
                  ? DateTimeComponents.time
                  : repeatType == "weekly"
                  ? DateTimeComponents.dayOfWeekAndTime
                  : DateTimeComponents.dayOfMonthAndTime)
              : null,
    );
    NotificationHelper.saveScheduledNotification(reminder, scheduledTime);
  }

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

      //if (!notifications.contains(finalMessage)) {
      notifications.add(finalMessage);
      await prefs.setStringList('unreadNotifications', notifications);
      print("check notification ${notifications}");
      if (mounted) setState(() {});
      // }
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
      // final reminderHours = [8, 12, 16, 20];
      final List<int> reminderHours = [8, 10, 12, 15, 16, 19, 20, 22];
      for (int day = 0; day < 7; day++) {
        for (int hour in reminderHours) {
          final reminderTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
          ).add(Duration(days: day));

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
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 15),
                Text(
                  "Schedule Notification",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children:
                    _presetReminders.keys.map((reminder) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reminder,
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _presetReminders[reminder],
                                    items:
                                        ["off", "daily", "weekly", "monthly"]
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(type),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (val) {
                                      if (val != null)
                                        _togglePresetReminder(reminder, val);
                                      print("calling");
                                    },
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            if (todaysReminders.isNotEmpty) ...[
              Row(
                children: [
                  SizedBox(width: 15),
                  Text(
                    "Reminders",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children:
                      todaysReminders.map((entry) {
                        return Card(
                          child: ListTile(
                            leading: FaIcon(
                              FontAwesomeIcons.stopwatch,
                              color: Colors.deepPurple,
                            ),
                            title: Text(entry.value),
                            trailing: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.trashCan,
                                color: Colors.red,
                              ),
                              onPressed:
                                  () => _removeReminder(entry.key, entry.value),
                            ),
                          ),
                        );
                      }).toList(),
                ),
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
