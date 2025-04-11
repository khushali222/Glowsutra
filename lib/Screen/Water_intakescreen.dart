// import 'dart:convert';
//
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
// import '../Serviece/helper.dart';
//
// class WaterIntakeScreen extends StatefulWidget {
//   @override
//   _WaterIntakeScreenState createState() => _WaterIntakeScreenState();
// }
//
// class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
//   int totalGlasses = 0;
//   final int targetGlasses = 8; // 1 glass = 250ml, 8 glasses = 2000ml
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   bool notificationsEnabled = false;
//   String selectedReminder = "None"; // Default: No reminders
//
//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//     _initNotifications();
//     _loadWaterIntake();
//     _loadNotificationPreferences();
//     // AwesomeNotifications().stream.listen((receivedNotification) async {
//     //   // Save the notification details when fired
//     //   if (receivedNotification.payload != null) {
//     //     String? notificationId = receivedNotification.payload!['id'];
//     //     String? totalGlasses = receivedNotification.payload!['totalGlasses'];
//     //
//     //     final prefs = await SharedPreferences.getInstance();
//     //     List<String> notifications =
//     //         prefs.getStringList('received_notifications') ?? [];
//     //
//     //     String notificationDetail =
//     //         "Notification ID: $notificationId - Drink water! Current intake: $totalGlasses glasses";
//     //
//     //     notifications.add(notificationDetail);
//     //     await prefs.setStringList('received_notifications', notifications);
//     //
//     //     print("Notification fired and saved: $notificationDetail");
//     //   }
//     // });
//     AwesomeNotifications().setListeners(
//       onActionReceivedMethod: (ReceivedAction receivedAction) async {
//         if (receivedAction.payload != null) {
//           String? notificationId = receivedAction.payload!['id'];
//           String? totalGlasses = receivedAction.payload!['totalGlasses'];
//
//           final prefs = await SharedPreferences.getInstance();
//           List<String> notifications =
//               prefs.getStringList('received_notifications') ?? [];
//
//           String notificationDetail =
//               "Notification ID: $notificationId - Drink water! Current intake: $totalGlasses glasses";
//
//           notifications.add(notificationDetail);
//           await prefs.setStringList('received_notifications', notifications);
//
//           print("Notification tapped and saved: $notificationDetail");
//         }
//       },
//     );
//   }
//
//   Future<void> _loadWaterIntake() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       totalGlasses = prefs.getInt('water_glasses') ?? 0;
//     });
//   }
//
//   Future<void> _saveWaterIntake() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('water_glasses', totalGlasses);
//   }
//
//   Future<void> _loadNotificationPreferences() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
//       selectedReminder = prefs.getString('reminder_type') ?? "None";
//     });
//   }
//
//   // Future<void> _saveNotificationPreferences() async {
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();
//   //   await prefs.setBool('unreadNotifications', notificationsEnabled);
//   //   await prefs.setString('reminder_type', selectedReminder);
//   // }
//   Future<void> _saveNotificationPreferences() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(
//       'notifications_enabled',
//       notificationsEnabled,
//     ); // ✅ use the right key!
//     await prefs.setString('reminder_type', selectedReminder);
//   }
//
//   Future<void> _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }
//
//   void _toggleNotifications(bool value) {
//     setState(() {
//       notificationsEnabled = value;
//     });
//
//     if (notificationsEnabled && selectedReminder != "None") {
//       _scheduleNotifications(_getDaysFromReminder(selectedReminder));
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("$selectedReminder Reminders Enabled!")),
//       );
//     } else {
//       flutterLocalNotificationsPlugin.cancelAll();
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Notifications Disabled!")));
//     }
//
//     _saveNotificationPreferences();
//   }
//
//   int _getDaysFromReminder(String reminderType) {
//     switch (reminderType) {
//       case "Daily":
//         return 1;
//       case "Weekly":
//         return 7;
//       case "Monthly":
//         return 30;
//       default:
//         return 0;
//     }
//   }
//
//   void _scheduleNotifications(int days) {
//     flutterLocalNotificationsPlugin.cancelAll();
//
//     final List<int> reminderHours = [9, 10, 13, 15, 17, 19, 21, 22];
//     final List<int> reminderMinutes = [9]; // <- Add more minutes if you want
//
//     for (int day = 0; day < days; day++) {
//       for (int hour in reminderHours) {
//         for (int minute in reminderMinutes) {
//           _scheduleNotification(day, hour, minute);
//         }
//       }
//     }
//   }
//
//   Future<void> _scheduleNotification(
//     int dayOffset,
//     int hour,
//     int minute,
//   ) async {
//     final now = DateTime.now();
//     DateTime scheduledTime = DateTime(
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     ).add(Duration(days: dayOffset));
//
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(Duration(days: 1));
//     }
//     // Getting the water intake value from SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     int totalGlasses = prefs.getInt('water_glasses') ?? 0;
//     final String message = "Drink water!";
//     //final String message = "Drink water! Current intake: $totalGlasses glasses";
//     NotificationContent notification = NotificationContent(
//       id: scheduledTime.hashCode,
//       channelKey: 'basic_channel',
//       title: 'Time to drink water!',
//       body: 'Drink water! Current intake: $totalGlasses glasses',
//       notificationLayout: NotificationLayout.Default,
//       payload: {
//         'id': scheduledTime.hashCode.toString(),
//         'totalGlasses': totalGlasses.toString(),
//       },
//     );
//
//     // Save the notification details to SharedPreferences immediately
//     await _saveScheduledNotificationDetails(scheduledTime, totalGlasses);
//
//     // Scheduling the notification
//     // Scheduling the notification
//     AwesomeNotifications().createNotification(
//       schedule: NotificationCalendar.fromDate(date: scheduledTime),
//       content: NotificationContent(
//         id: scheduledTime.hashCode, // unique ID for this notification
//         channelKey:
//             'basic_channel', // Notification channel (make sure it's registered)
//         title: 'Time to drink water!',
//         body:
//             'Drink water! Current intake: $totalGlasses glasses', // Message content
//         notificationLayout: NotificationLayout.Default,
//         payload: {
//           'id': scheduledTime.hashCode.toString(),
//           'totalGlasses': totalGlasses.toString(),
//         },
//       ),
//     );
//     print("calling 1");
//   }
//
//   Future<void> _saveScheduledNotificationDetails(
//     DateTime scheduledTime,
//     int totalGlasses,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> scheduledNotifications =
//         prefs.getStringList('scheduled_notifications') ?? [];
//
//     String formattedTime =
//         "${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}";
//     String formattedDate =
//         "${scheduledTime.year}-${scheduledTime.month}-${scheduledTime.day}";
//
//     String notificationDetail =
//         "$formattedDate $formattedTime - Drink water! Current intake: $totalGlasses glasses";
//
//     scheduledNotifications.add(notificationDetail);
//     await prefs.setStringList(
//       'scheduled_notifications',
//       scheduledNotifications,
//     );
//   }
//
//   Future<void> _saveWaterIntakeNotification(String message) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final value = prefs.get('unreadNotifications');
//
//     List<String> notifications = [];
//     if (value is List<String>) {
//       notifications = value;
//     }
//
//     notifications.add(message);
//     await prefs.setStringList('unreadNotifications', notifications);
//   }
//
//   void _addWater(int glasses) {
//     setState(() {
//       totalGlasses += glasses;
//       if (totalGlasses > targetGlasses) {
//         totalGlasses = targetGlasses;
//       }
//     });
//     _saveWaterIntake();
//   }
//
//   void _removeWater(int glasses) {
//     setState(() {
//       totalGlasses -= glasses;
//       if (totalGlasses < 0) {
//         totalGlasses = 0;
//       }
//     });
//     _saveWaterIntake();
//   }
//
//   void _resetWaterIntake() {
//     setState(() {
//       totalGlasses = 0;
//     });
//     _saveWaterIntake();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double progress = totalGlasses / targetGlasses;
//
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: Colors.deepPurple[100],
//         elevation: 0,
//         title: Text("Water Intake Tracker"),
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//           child: Column(
//             children: [
//               // Image Section
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Container(
//                   height: 250,
//                   // width: double.infinity,
//                   color: Colors.deepPurple[50],
//                   child: Image.network(
//                     "https://img.freepik.com/premium-vector/glass-with-water-template-glass-transparent-cup-with-blue-refreshing-natural-liquid_79145-1179.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740",
//                     // fit: BoxFit.fill,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               // Progress Info
//               Container(
//                 padding: EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.deepPurple[50],
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       "$totalGlasses / $targetGlasses Glasses",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepPurple[800],
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     LinearProgressIndicator(
//                       value: progress,
//                       minHeight: 10,
//                       color: Colors.deepPurple,
//                       backgroundColor: Colors.deepPurple.shade100,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 24),
//
//               // Inline Action Buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () => _addWater(1),
//                     icon: Icon(Icons.add),
//                     label: Text("Add"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.deepPurple[300],
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () => _removeWater(1),
//                     icon: Icon(Icons.remove),
//                     label: Text("Remove"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.deepPurple[100],
//                       foregroundColor: Colors.deepPurple[800],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                   OutlinedButton(
//                     onPressed: _resetWaterIntake,
//                     child: Text("Reset"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.deepPurple,
//                       side: BorderSide(color: Colors.deepPurple.shade300),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               SizedBox(height: 30),
//               Divider(color: Colors.deepPurple[100]),
//               SizedBox(height: 8),
//               // Reminder Section
//               Row(
//                 children: [
//                   Text(
//                     "Reminders",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.deepPurple[900],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 10),
//
//               // Reminder Toggle
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Enable Reminders",
//                     style: TextStyle(color: Colors.deepPurple[700]),
//                   ),
//                   Switch(
//                     value: notificationsEnabled,
//                     onChanged: _toggleNotifications,
//                     activeColor: Colors.deepPurple,
//                   ),
//                 ],
//               ),
//               SizedBox(height: 10),
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple[50],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: selectedReminder,
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             selectedReminder = newValue!;
//                           });
//                           if (notificationsEnabled) _toggleNotifications(true);
//                           _saveNotificationPreferences();
//                         },
//                         items:
//                             [
//                               "None",
//                               "Daily",
//                               "Weekly",
//                               "Monthly",
//                             ].map<DropdownMenuItem<String>>((String value) {
//                               return DropdownMenuItem<String>(
//                                 value: value,
//                                 child: Text(value),
//                               );
//                             }).toList(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//
//               // Dropdown
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
