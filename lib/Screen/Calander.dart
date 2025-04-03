import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  // Map<String, bool> _presetReminders = {
  //   "Water Intake": false,
  //   "Facewash": false,
  //   "Moisturizer": false,
  //   "Sunscreen": false,
  // };
  Map<String, String> _presetReminders = {
    "Water Intake": "off",
    "Facewash": "off",
    "Moisturizer": "off",
    "Sunscreen": "off",
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
        _presetReminders = Map<String, String>.from(jsonDecode(savedPresets));
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
    DateTime scheduledTime, {
    bool isRepeating = false,
    String repeatType = "daily",
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    if (isRepeating) {
      await _notificationsPlugin.zonedSchedule(
        reminder.hashCode + scheduledTime.hour,
        'Skincare Reminder',
        reminder,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            repeatType == "daily"
                ? DateTimeComponents.time
                : (repeatType == "weekly"
                    ? DateTimeComponents.dayOfWeekAndTime
                    : DateTimeComponents.dayOfMonthAndTime),
      );
    } else {
      await _notificationsPlugin.zonedSchedule(
        reminder.hashCode,
        'Custom Reminder',
        reminder,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
    _saveNotificationWhenTimeArrives(reminder, scheduledTime);
  }

  void _saveNotificationWhenTimeArrives(
    String reminder,
    DateTime scheduledTime,
  ) {
    Duration delay = scheduledTime.difference(DateTime.now());

    if (delay.isNegative) return; // Avoid adding past notifications

    Future.delayed(delay, () async {
      final prefs = await SharedPreferences.getInstance();
      List<String> notifications =
          prefs.getStringList('unreadNotifications') ?? [];

      // Format the time as HH:MM AM/PM
      String formattedTime =
          "${scheduledTime.hour % 12 == 0 ? 12 : scheduledTime.hour % 12}:${scheduledTime.minute.toString().padLeft(2, '0')} ${scheduledTime.hour >= 12 ? "PM" : "AM"}";

      // Save as "Reminder - Time"
      notifications.add("$reminder - $formattedTime");

      await prefs.setStringList('unreadNotifications', notifications);

      if (mounted) {
        setState(() {}); // Update UI when the notification is added
      }
    });
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

  Future<void> _togglePresetReminder(String reminder, String planType) async {
    setState(() {
      _presetReminders[reminder] = planType;
    });

    _cancelScheduledNotifications(reminder); // Cancel existing reminders

    if (planType != "off") {
      final now = DateTime.now();

      List<DateTime> reminderTimes = [
        DateTime(now.year, now.month, now.day, 8, 0),
        DateTime(now.year, now.month, now.day, 12, 0),
        DateTime(now.year, now.month, now.day, 16, 0),
        DateTime(now.year, now.month, now.day, 20, 0),
      ];

      bool scheduledToday = false; // Flag to check if we scheduled for today

      for (DateTime time in reminderTimes) {
        if (time.isAfter(now)) {
          // ✅ Schedule only if it's in the future
          _scheduleNotification(reminder, time);
          scheduledToday = true;
        }
      }

      if (!scheduledToday) {
        // ✅ If no reminders left today, schedule for tomorrow
        for (DateTime time in reminderTimes) {
          _scheduleNotification(reminder, time.add(Duration(days: 1)));
        }
      }
    }

    _saveReminders();
    _savePresetSettings();
  }

  List<MapEntry<DateTime, String>> _getTodaysReminders() {
    DateTime today = _selectedDate; // Use selected date instead of always today
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

  Future<void> _cancelScheduledNotifications(String reminder) async {
    await _notificationsPlugin.cancel(reminder.hashCode);
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
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Column(
            //     children:
            //         _presetReminders.keys.map((reminder) {
            //           return Card(
            //             elevation: 4,
            //             margin: EdgeInsets.symmetric(vertical: 6),
            //             child: ListTile(
            //               title: Text(reminder),
            //               trailing: Switch(
            //                 value: _presetReminders[reminder]!,
            //                 onChanged: (bool value) {
            //                   _togglePresetReminder(reminder, value);
            //                 },
            //               ),
            //             ),
            //           );
            //         }).toList(),
            //   ),
            // ),

            // ✅ List of reminders for the selected date
            SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 15),
                Text(
                  "Schedule Notification",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
              child: Column(
                children:
                    _presetReminders.keys.map((reminder) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Rounded corners
                        ),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  reminder,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // Smooth rounded dropdown
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _presetReminders[reminder],
                                    items:
                                        ["off", "daily", "weekly", "monthly"]
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(
                                                  type,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        _togglePresetReminder(
                                          reminder,
                                          newValue,
                                        );
                                      }
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
            SizedBox(height: 2),
            if (todaysReminders.isNotEmpty)
              Row(
                children: [
                  SizedBox(width: 15),
                  Text(
                    "Reminders",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            if (todaysReminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  children:
                      todaysReminders.map((entry) {
                        DateTime reminderDate = entry.key;
                        String reminderText = entry.value;

                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: FaIcon(
                              FontAwesomeIcons.stopwatch,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                            title: Text(reminderText),
                            trailing: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.trashCan,
                                size: 18,
                                color: Colors.red,
                              ),
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
