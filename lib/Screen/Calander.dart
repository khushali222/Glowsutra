import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
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
    _loadReminders(); // ✅ Load reminders when screen opens
    _loadPresetSettings();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _scheduleNotification(
    String reminder,
    DateTime scheduledTime,
  ) async {
    final now = DateTime.now();

    // ✅ Ensure the notification is scheduled for a future time
    if (scheduledTime.isBefore(now)) {
      print("🚨 Error: Scheduled time must be in the future!");
      return; // ❌ Prevent scheduling notifications in the past
    }

    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      0, // Change the ID to 0 or any unique value
      'Skincare Reminder',
      reminder,
      tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      ), // ✅ Ensured it's in the future
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, List<String>> formattedReminders = _reminders.map(
      (key, value) => MapEntry(key.toIso8601String(), value),
    );
    await prefs.setString('reminders', jsonEncode(formattedReminders));
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

  Future<void> _savePresetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presetReminders', jsonEncode(_presetReminders));
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

  Future<void> _togglePresetReminder(String reminder, bool enabled) async {
    setState(() {
      _presetReminders[reminder] = enabled;
    });

    if (enabled) {
      final now = DateTime.now();
      DateTime scheduledTime = DateTime(now.year, now.month, now.day, 8, 0);

      // ✅ Move to the next day if 8:00 AM has already passed
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(Duration(days: 1));
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

  // Future<void> _togglePresetReminder(String reminder, bool enabled) async {
  //   setState(() {
  //     _presetReminders[reminder] = enabled;
  //   });
  //
  //   if (enabled) {
  //     final now = DateTime.now();
  //     final scheduledTime = DateTime(now.year, now.month, now.day, 14, 30); // 2:30 PM today
  //
  //     if (scheduledTime.isBefore(now)) {
  //       print("🚨 Error: Cannot schedule notification in the past!");
  //       return;
  //     }
  //
  //     _scheduleNotification(reminder, scheduledTime);
  //     setState(() {
  //       _reminders[_selectedDate] ??= [];
  //       _reminders[_selectedDate]!.add(reminder);
  //     });
  //   } else {
  //     setState(() {
  //       _reminders[_selectedDate]?.remove(reminder);
  //       if (_reminders[_selectedDate]?.isEmpty ?? true) {
  //         _reminders.remove(_selectedDate);
  //       }
  //     });
  //   }
  //
  //   _saveReminders();
  //   _savePresetSettings();
  // }
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

  // Future<void> _addReminder() async {
  //   final TimeOfDay? pickedTime = await showTimePicker(
  //     context: context,
  //     initialTime: TimeOfDay.now(),
  //   );
  //
  //   if (pickedTime != null) {
  //     final DateTime scheduledDateTime = DateTime(
  //       _selectedDate.year,
  //       _selectedDate.month,
  //       _selectedDate.day,
  //       pickedTime.hour,
  //       pickedTime.minute,
  //     );
  //
  //     TextEditingController reminderController = TextEditingController();
  //     showDialog(
  //       context: context,
  //       builder:
  //           (context) => AlertDialog(
  //             title: Text("Add Reminder"),
  //             content: TextField(
  //               controller: reminderController,
  //               decoration: InputDecoration(hintText: "Enter reminder"),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   if (reminderController.text.isNotEmpty) {
  //                     setState(() {
  //                       _reminders[_selectedDate] ??= [];
  //                       _reminders[_selectedDate]!.add(reminderController.text);
  //                     });
  //
  //                     _scheduleNotification(
  //                       reminderController.text,
  //                       scheduledDateTime,
  //                     );
  //                     _saveReminders();
  //                   }
  //                   Navigator.pop(context);
  //                 },
  //                 child: Text("Save"),
  //               ),
  //             ],
  //           ),
  //     );
  //   }
  // }
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

            // ✅ Preset Routine Cards
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
            // Expanded(
            //   child: ListView(
            //     children:
            //         (_reminders[_selectedDate] ?? []).map((reminder) {
            //           return ListTile(
            //             title: Text(reminder),
            //             trailing: IconButton(
            //               icon: Icon(Icons.delete),
            //               onPressed: () {
            //                 setState(() {
            //                   _reminders[_selectedDate]!.remove(reminder);
            //                   if (_reminders[_selectedDate]!.isEmpty) {
            //                     _reminders.remove(_selectedDate);
            //                   }
            //                   _saveReminders();
            //                 });
            //               },
            //             ),
            //           );
            //         }).toList(),
            //   ),
            // ),
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
