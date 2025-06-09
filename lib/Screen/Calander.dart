import 'dart:async';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/custom_appbar.dart';
import '../services/reminder_service.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  Map<DateTime, List<Map<String, dynamic>>> _reminders = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _reminderController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  final StreamController<void> _notificationStream = StreamController<void>.broadcast();
  final ReminderService _reminderService = ReminderService();

  // Get the current user's reminders document reference
  DocumentReference get _userRemindersRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('No user logged in');
    return _firestore
        .collection("User")
        .doc("fireid")
        .collection("reminders")
        .doc(userId);
  }

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      setState(() => _isLoading = true);
      final doc = await _userRemindersRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _reminders = (data['reminders'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              DateTime.parse(key),
              List<Map<String, dynamic>>.from(value),
            ),
          );
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReminders() async {
    try {
      final formatted = _reminders.map(
        (key, value) => MapEntry(key.toIso8601String(), value),
      );
      
      await _userRemindersRef.set({
        'reminders': formatted,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving reminders: $e');
    }
  }

  Future<void> _addReminder(DateTime date) async {
    if (_reminderController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter a reminder');
      return;
    }

    if (_timeController.text.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a time');
      return;
    }

    try {
      // Parse the selected time
      final timeOfDay = TimeOfDay(
        hour: int.parse(_timeController.text.split(':')[0]),
        minute: int.parse(_timeController.text.split(':')[1].split(' ')[0]),
      );

      // Create the scheduled date and time
      final scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      // Create the reminder data
      final reminderData = {
        'text': _reminderController.text,
        'time': scheduledDateTime.toIso8601String(),
      };

      // Update local state
      setState(() {
        if (_reminders[date] == null) {
          _reminders[date] = [];
        }
        _reminders[date]!.add(reminderData);
      });

      // Save to Firebase
      await _saveReminders();

      // Schedule notification
      await _scheduleNotification(scheduledDateTime, _reminderController.text);

      // Clear the controllers
      _reminderController.clear();
      _timeController.clear();

      // Close the dialog
      Navigator.pop(context);
    } catch (e) {
      print('Error adding reminder: $e');
      Fluttertoast.showToast(msg: 'Error adding reminder');
    }
  }

  Future<void> _removeReminder(DateTime date, Map<String, dynamic> reminder) async {
    try {
      // Cancel the notification
      final prefs = await SharedPreferences.getInstance();
      List<String> notificationsJson = prefs.getStringList('unreadNotifications') ?? [];
      List<String> updatedNotifications = [];
      List<int> idsToCancel = [];

      for (var jsonString in notificationsJson) {
        final decoded = jsonDecode(jsonString);
        if (decoded['reminder'] == reminder['text']) {
          idsToCancel.add(int.tryParse(decoded['id'] ?? '') ?? 0);
        } else {
          updatedNotifications.add(jsonString);
        }
      }

      for (var id in idsToCancel) {
        await _notificationsPlugin.cancel(id);
      }

      // Update local state
      setState(() {
        _reminders[date]?.removeWhere((item) => item['text'] == reminder['text']);
        if (_reminders[date]?.isEmpty ?? true) _reminders.remove(date);
      });

      // Save to Firebase
      await _saveReminders();
      
      // Update local storage for notifications
      await prefs.setStringList('unreadNotifications', updatedNotifications);
    } catch (e) {
      print('Error removing reminder: $e');
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
        _notificationStream.add(null);
      },
    );
  }

  Future<void> _scheduleNotification(DateTime scheduledTime, String reminderText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> notificationsJson = prefs.getStringList('unreadNotifications') ?? [];
      
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'Channel for reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        'Reminder',
        reminderText,
        TZDateTime.from(scheduledTime, local),
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Save notification to SharedPreferences
      notificationsJson.add(jsonEncode({
        'id': id.toString(),
        'reminder': reminderText,
        'date': DateFormat('yyyy-MM-dd').format(scheduledTime),
      }));

      await prefs.setStringList('unreadNotifications', notificationsJson);
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _notificationStream.stream,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: CustomAppBar(title: 'Calendar'),
          body: _isLoading
              ? Center(child: SpinKitCircle(color: Colors.black))
              : Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _showAddReminderDialog(selectedDay);
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.deepPurple.shade200,
                          shape: BoxShape.circle,
                        ),
                      ),
                      eventLoader: (day) {
                        return _reminders[day] ?? [];
                      },
                    ),
                    Expanded(
                      child: _selectedDay == null
                          ? Center(
                              child: Text(
                                'Select a day to view reminders',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : _buildRemindersList(_selectedDay!),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildRemindersList(DateTime date) {
    final reminders = _reminders[date] ?? [];

    if (reminders.isEmpty) {
      return Center(
        child: Text(
          'No reminders for this day',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        final scheduledDateTime = DateTime.parse(reminder['time']);
        final formattedDateTime = DateFormat('MMM d, yyyy hh:mm a')
            .format(scheduledDateTime);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.shade100.withOpacity(0.4),
                blurRadius: 4,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade200,
              child: FaIcon(
                FontAwesomeIcons.solidBell,
                size: 16,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              formattedDateTime,
              style: TextStyle(color: Colors.grey),
            ),
            title: Text(
              reminder['text'],
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () {
                _removeReminder(date, reminder);
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddReminderDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reminderController,
              decoration: InputDecoration(
                labelText: 'Reminder',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Time (HH:mm)',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  _timeController.text =
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reminderController.clear();
              _timeController.clear();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _addReminder(date),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reminderController.dispose();
    _timeController.dispose();
    _notificationStream.close();
    super.dispose();
  }
}
