import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:easy_date_timeline/easy_date_timeline.dart';

import '../Serviece/notification_service.dart';

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

  Map<String, bool> _presetReminders = {
    "Water Intake": false,
    "Facewash": false,
    "Moisturizer": false,
    "Sunscreen": false,
  };

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    tz.initializeTimeZones();
    _initializeNotifications();
    WidgetsFlutterBinding.ensureInitialized();
    requestNotificationPermission();
    _loadReminders();
    _loadPresetSettings();
    _loadUnreadNotifications();
  }

  Future<void> requestNotificationPermission() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final result =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    if (result != null && result) {
      print("✅ Notification Permission Granted!");
    } else {
      print("🚨 Notification Permission Denied!");
    }
  }

  Future<void> _loadPresetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPresets = prefs.getString('presetReminders');
    if (savedPresets != null) {
      setState(() {
        _presetReminders = Map<String, bool>.from(jsonDecode(savedPresets));
      });
    }
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedReminders = prefs.getString('reminders');
    print("reminder${savedReminders}");
    if (savedReminders != null) {
      Map<String, dynamic> decodedReminders = jsonDecode(savedReminders);
      setState(() {
        _reminders = decodedReminders.map((key, value) {
          return MapEntry(DateTime.parse(key), List<String>.from(value));
        });
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _markNotificationAsRead(response.payload);
      },
    );
  }

  Future<void> _scheduleNotification(
    String reminder,
    DateTime scheduledTime,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      reminder.hashCode,
      'Skincare Reminder',
      reminder,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _saveUnreadNotification(reminder);
  }

  Future<void> _saveUnreadNotification(String notification) async {
    final prefs = await SharedPreferences.getInstance();
    _unreadNotifications.add(notification);
    await prefs.setStringList('unreadNotifications', _unreadNotifications);
    setState(() {});
  }

  Future<void> _loadUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _unreadNotifications = prefs.getStringList('unreadNotifications') ?? [];
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

  Future<void> _addReminder() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final DateTime scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      TextEditingController reminderController = TextEditingController();
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Add Reminder"),
              content: TextField(
                controller: reminderController,
                decoration: InputDecoration(hintText: "Enter reminder"),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (reminderController.text.isNotEmpty) {
                      setState(() {
                        _reminders[_selectedDate] ??= [];
                        _reminders[_selectedDate]!.add(reminderController.text);
                      });

                      _scheduleNotification(
                        reminderController.text,
                        scheduledDateTime,
                      );
                      _saveReminders(); // ✅ Save immediately to prevent data loss

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

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> formattedReminders = _reminders.map(
      (key, value) => MapEntry(key.toIso8601String(), value),
    );
    await prefs.setString('reminders', jsonEncode(formattedReminders));
  }

  Future<void> _togglePresetReminder(String reminder, bool enabled) async {
    setState(() {
      _presetReminders[reminder] = enabled;
    });

    if (enabled) {
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        14,
        30,
      ); // 2:30 PM today

      if (scheduledTime.isBefore(now)) {
        print("🚨 Error: Cannot schedule notification in the past!");
        return;
      }

      _scheduleNotification(reminder, scheduledTime);
      setState(() {
        _reminders[_selectedDate] ??= [];
        _reminders[_selectedDate]!.add(reminder);
      });
    } else {
      setState(() {
        _reminders[_selectedDate]?.remove(reminder);
        if (_reminders[_selectedDate]?.isEmpty ?? true) {
          _reminders.remove(_selectedDate);
        }
      });
    }

    _saveReminders();
    _savePresetSettings();
  }

  List<MapEntry<DateTime, String>> _getTodaysReminders() {
    DateTime today = DateTime.now();
    List<MapEntry<DateTime, String>> todayReminders = [];

    _reminders.forEach((date, reminders) {
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        todayReminders.addAll(
          reminders.map((reminder) => MapEntry(date, reminder)),
        );
      }
    });

    return todayReminders;
  }

  Future<void> _removeReminder(DateTime date, String reminder) async {
    setState(() {
      _reminders[date]?.remove(reminder);
      if (_reminders[date]?.isEmpty ?? true) {
        _reminders.remove(date);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> encodedReminders = _reminders.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });

    await prefs.setString('reminders', jsonEncode(encodedReminders));
  }

  Future<void> _savePresetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presetReminders', jsonEncode(_presetReminders));
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<DateTime, String>> todaysReminders = _getTodaysReminders();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Skincare Calendar"),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            EasyDateTimeLine(
              initialDate: _selectedDate,
              onDateChange: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
              activeColor: Colors.deepPurple[100],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children:
                    _presetReminders.keys.map((reminder) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(reminder),
                          trailing: Switch(
                            value: _presetReminders[reminder]!,
                            onChanged: (bool value) {
                              _togglePresetReminder(reminder, value);
                            },
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),

            // ✅ List of reminders for the selected date
            if (todaysReminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children:
                      todaysReminders.map((entry) {
                        DateTime reminderDate = entry.key;
                        String reminderText = entry.value;

                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(reminderText),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _removeReminder(reminderDate, reminderText);
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

            ElevatedButton(
              onPressed: () {
                DateTime scheduledTime = DateTime.now().add(
                  Duration(seconds: 10),
                );
                NotificationService().scheduleNotification(
                  title: "Reminder",
                  body: "Drink water!",
                  scheduledTime: scheduledTime,
                );
              },
              child: Text("Schedule Notification"),
            ),
            ElevatedButton(
              onPressed: () {
                NotificationService().showNotification(
                  title: "Reminder",
                  body: "It's time for your skincare routine!",
                );
              },
              child: Text("Show Notification"),
            ),
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
