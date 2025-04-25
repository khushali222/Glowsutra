import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../model/notification_model.dart';

@pragma('vm:entry-point')
void handleBackgroundNotification(NotificationResponse response) async {
  try {
    final boxName = 'notifications';

    // Check if the box is already open before opening it
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    String screenKey = "default";
    String storageKey = '${screenKey}_unreadNotifications';
    List<String> notificationsJson = Hive.box(boxName).get(storageKey) ?? [];

    DateTime now = DateTime.now();
    String formattedTime =
        "${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "PM" : "AM"}";
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);

    Map<String, String> notificationMap = {
      "reminder": response.payload ?? 'Unknown Reminder',
      "time": formattedTime,
      "date": formattedDate,
      "payload": response.payload ?? '',
      "source": screenKey,
      "id": response.id?.toString() ?? '0',
    };

    bool? scheduleEnable = await Hive.box(
      boxName,
    ).get('alreadyScheduled', defaultValue: false);
    if (scheduleEnable == true) {
      notificationsJson.add(jsonEncode(notificationMap));
      await Hive.box(boxName).put(storageKey, notificationsJson);
      print(
        "🟢 Saved background notification to [$storageKey]: $notificationMap",
      );
    }
  } catch (e) {
    print("Error in background notification handler: $e");
  }
}

class WaterIntakeScreen extends StatefulWidget {
  @override
  _WaterIntakeScreenState createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  int totalGlasses = 0;
  final int targetGlasses = 8; // 1 glass = 250ml, 8 glasses = 2000ml
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late Box<NotificationModel> notificationsBox;
  bool notificationsEnabled = false;
  String selectedReminder = "None"; // Default: No reminders
  final _notification = Hive.box("notificationBox");
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initNotifications();
    _loadWaterIntake();
    _loadNotificationPreferences();
    checkIfLaunchedFromNotification();
    _openNotificationsBox();
  }

  Future<void> _openNotificationsBox() async {
    const boxName = 'notifications';

    // Ensure box is only opened once and not multiple times
    if (!Hive.isBoxOpen(boxName)) {
      notificationsBox = await Hive.openBox<NotificationModel>(boxName);
    } else {
      notificationsBox = Hive.box<NotificationModel>(boxName);
    }
  }

  Future<void> checkIfLaunchedFromNotification() async {
    final NotificationAppLaunchDetails? details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      print(
        "App launched by notification with payload: ${details!.notificationResponse?.payload}",
      );
      onTapNotification(details.notificationResponse!.payload!);
    }
  }

  Future<void> _loadWaterIntake() async {
    final settingsBox = Hive.box('settings');
    setState(() {
      totalGlasses = settingsBox.get('water_glasses', defaultValue: 0);
    });
  }

  void writeDat() {
    _notification.put(1, "khushi");
    print(_notification.get(1));
  }

  Future<void> _saveWaterIntake() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('water_glasses', totalGlasses);
  }

  Future<void> _loadNotificationPreferences() async {
    final settingsBox = Hive.box('settings');
    setState(() {
      notificationsEnabled = settingsBox.get(
        'notifications_enabled',
        defaultValue: false,
      );
      selectedReminder = settingsBox.get('reminder_type', defaultValue: 'None');
    });
  }

  Future<void> _saveNotificationPreferences() async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('notifications_enabled', notificationsEnabled);
    await settingsBox.put('reminder_type', selectedReminder);
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("clliing 1");
        final String? actionId = response.actionId;
        print("data ${response.data}");
        print("payload ${response.payload}");
        print("responsetype ${response.notificationResponseType}");
        print("input ${response.input}");
        if (response.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          print("input ${response.notificationResponseType}");
          // onTapNotification(response.payload!);
          _saveNotificationToHive(response);
        }
        if (actionId == 'ok_action') {
          // 🔔 User tapped OK
          print("✅ User acknowledged water reminder.");
        } else if (actionId == 'cancel_action') {
          // ❌ User tapped Cancel
          print("❌ User dismissed water reminder.");
        } else {
          // 📱 User tapped the notification body
          print("📩 Notification tapped (not a button).");
        }
      },
      // onDidReceiveBackgroundNotificationResponse: handleBackgroundNotification,
    );
  }

  void onTapNotification(String payload) async {
    final box = await Hive.openBox('settings');
    List<String> notificationsJson = List<String>.from(
      box.get('water_notification_unreadNotifications', defaultValue: []),
    );

    for (int i = 0; i < notificationsJson.length; i++) {
      Map<String, dynamic> notificationMap = jsonDecode(notificationsJson[i]);

      if (notificationMap["payload"] == payload) {
        String id = notificationMap["id"];

        notificationsJson.removeAt(i);

        await box.put(
          'water_notification_unreadNotifications',
          notificationsJson,
        );

        await flutterLocalNotificationsPlugin.cancel(int.parse(id));

        print("Notification with ID $id has been removed and canceled.");
        break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleNotifications(bool value) async {
    final boxName = 'notifications';
    var notificationBox = Hive.box<NotificationModel>(boxName);
    var generalBox = await Hive.openBox('generalData');
    await generalBox.put('notificationsEnabled', value);
    List<String> waterList =
        (generalBox.get('saved_notification_ids', defaultValue: [])
                as List<dynamic>)
            .map((e) => e.toString())
            .toList();

    setState(() {
      notificationsEnabled = value;
    });

    if (notificationsEnabled && selectedReminder != "None") {
      bool alreadyScheduled = generalBox.get(
        'alreadyScheduled',
        defaultValue: false,
      );
      if (!alreadyScheduled) {
        for (String id in waterList) {
          await flutterLocalNotificationsPlugin.cancel(int.parse(id));
        }
        _scheduleNotifications(_getDaysFromReminder(selectedReminder));
        await generalBox.put('alreadyScheduled', true);
      }
    } else {
      await generalBox.put('alreadyScheduled', false);

      if (waterList.isNotEmpty) {
        for (String id in waterList) {
          await flutterLocalNotificationsPlugin.cancel(int.parse(id));
        }

        await generalBox.delete('saved_notification_ids');
      }

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

  void _scheduleNotifications(int days) async {
    final List<int> reminderHours = [
      10,
      11,
      12,
      14,
      15,
      16,
      17,
      18,
      19,
      21,
      22,
    ];
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
    ];

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
    final box = Hive.box('settings');
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

    int totalGlasses = box.get('water_glasses', defaultValue: 0);
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

    int id = dayOffset * 10000 + hour * 100 + minute;

    List<String> existingIds = List<String>.from(
      box.get('saved_notification_ids', defaultValue: []),
    );

    if (!existingIds.contains(id.toString())) {
      existingIds.add(id.toString());
      await box.put('saved_notification_ids', existingIds);
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Hydration Reminder',
      message,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _saveNotificationToHive(NotificationResponse response) async {
    try {
      final boxName = 'notifications';
      String screenKey = "default";
      String storageKey = '${screenKey}_unreadNotifications';
      List<String> notificationsJson = Hive.box(boxName).get(storageKey) ?? [];

      DateTime now = DateTime.now();
      String formattedTime =
          "${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "PM" : "AM"}";
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      Map<String, String> notificationMap = {
        "reminder": response.payload ?? 'Unknown Reminder',
        "time": formattedTime,
        "date": formattedDate,
        "payload": response.payload ?? '',
        "source": screenKey,
        "id": response.id?.toString() ?? '0',
      };

      notificationsJson.add(jsonEncode(notificationMap));
      await Hive.box(
        boxName,
      ).put(storageKey, notificationsJson); // Save it in the box

      print("Saved foreground notification to [$storageKey]: $notificationMap");
    } catch (e) {
      print("Error saving foreground notification: $e");
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
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   children: [
              //     ElevatedButton.icon(
              //       onPressed: () => _addWater(1),
              //       icon: Icon(Icons.add),
              //       label: Text("Add"),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.deepPurple[300],
              //         foregroundColor: Colors.white,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         padding: EdgeInsets.symmetric(
              //           horizontal: 20,
              //           vertical: 12,
              //         ),
              //       ),
              //     ),
              //     ElevatedButton.icon(
              //       onPressed: () => _removeWater(1),
              //       icon: Icon(Icons.remove),
              //       label: Text("Remove"),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.deepPurple[100],
              //         foregroundColor: Colors.deepPurple[800],
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         padding: EdgeInsets.symmetric(
              //           horizontal: 20,
              //           vertical: 12,
              //         ),
              //       ),
              //     ),
              //     OutlinedButton(
              //       onPressed: _resetWaterIntake,
              //       child: Text("Reset"),
              //       style: OutlinedButton.styleFrom(
              //         foregroundColor: Colors.deepPurple,
              //         side: BorderSide(color: Colors.deepPurple.shade300),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(10),
              //         ),
              //         padding: EdgeInsets.symmetric(
              //           horizontal: 20,
              //           vertical: 12,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(height: 30),
              Divider(color: Colors.deepPurple[100]),
              SizedBox(height: 8),
              // Reminder Section
              Row(
                children: [
                  GestureDetector(
                    onTap: writeDat,
                    child: Text(
                      "Reminders",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple[900],
                      ),
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
