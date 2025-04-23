// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class NotificationScreen extends StatefulWidget {
//   final List<String> notifications;
//   final VoidCallback onClear;
//
//   const NotificationScreen({
//     Key? key,
//     required this.notifications,
//     required this.onClear,
//   }) : super(key: key);
//
//   @override
//   _NotificationScreenState createState() => _NotificationScreenState();
// }
//
// class _NotificationScreenState extends State<NotificationScreen> {
//   List<String> _unreadNotifications = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUnreadNotifications();
//   }
//
//   Future<void> _loadUnreadNotifications() async {
//     final prefs = await SharedPreferences.getInstance();
//     final storedList = prefs.getStringList('unreadNotifications') ?? [];
//
//     if (storedList.isEmpty) {
//       setState(() {
//         _unreadNotifications = [];
//       });
//       return;
//     }
//
//     final seen = <String>{};
//     final uniqueNotifications = <String>[];
//
//     for (var item in storedList) {
//       final parsed = jsonDecode(item);
//       final uniqueKey = jsonEncode(parsed); // Compare entire notification
//       if (!seen.contains(uniqueKey)) {
//         seen.add(uniqueKey);
//         uniqueNotifications.add(item);
//       }
//     }
//
//     await prefs.setStringList('unreadNotifications', uniqueNotifications);
//
//     setState(() {
//       _unreadNotifications = uniqueNotifications;
//     });
//
//     print("Filtered notifications: $_unreadNotifications");
//   }
//
//   // Future<void> _loadUnreadNotifications() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final storedList = prefs.getStringList('unreadNotifications') ?? [];
//   //
//   //   if (storedList.isEmpty) {
//   //     setState(() {
//   //       _unreadNotifications = [];
//   //     });
//   //     return;
//   //   }
//   //
//   //   final seen = <String>{};
//   //   final uniqueNotifications = <String>[];
//   //
//   //   for (var item in storedList) {
//   //     final parsed = jsonDecode(item);
//   //     final uniqueKey = '${parsed["time"]}_${parsed["date"]}';
//   //     if (!seen.contains(uniqueKey)) {
//   //       seen.add(uniqueKey);
//   //       uniqueNotifications.add(item);
//   //     }
//   //   }
//   //
//   //   await prefs.setStringList('unreadNotifications', uniqueNotifications);
//   //
//   //   setState(() {
//   //     _unreadNotifications = uniqueNotifications;
//   //   });
//   //
//   //   print("Filtered notifications: $_unreadNotifications");
//   // }
//
//   Future<void> _clearNotifications() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList('unreadNotifications', []);
//     setState(() {
//       _unreadNotifications.clear();
//     });
//
//     widget.onClear(); // Notify the Dashboard
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Notifications"),
//         backgroundColor: Colors.deepPurple[100],
//         // actions: [
//         //   if (_unreadNotifications.isNotEmpty)
//         //     IconButton(
//         //       icon: Icon(Icons.delete),
//         //       onPressed: _clearNotifications,
//         //     ),
//         // ],
//       ),
//       body:
//           _unreadNotifications.isEmpty
//               ? Center(
//                 child: Text(
//                   "No new notifications!",
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//               )
//               : ListView.builder(
//                 itemCount: _unreadNotifications.length,
//                 itemBuilder: (context, index) {
//                   final parts = jsonDecode(_unreadNotifications[index]);
//                   final message = parts["reminder"];
//                   final time = parts["time"];
//                   final date = parts["date"];
//                   return Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Card(
//                       elevation: 3,
//                       margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                       child: ListTile(
//                         leading: FaIcon(
//                           FontAwesomeIcons.bell,
//                           size: 20,
//                           color: Colors.black,
//                         ),
//                         title: Text(message),
//                         subtitle: Text(" $time  $date"),
//                         trailing: IconButton(
//                           icon: Icon(Icons.close, color: Colors.red),
//                           onPressed: () async {
//                             setState(() {
//                               _unreadNotifications.removeAt(index);
//                             });
//                             final prefs = await SharedPreferences.getInstance();
//                             await prefs.setStringList(
//                               'unreadNotifications',
//                               _unreadNotifications,
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback onClear;

  const NotificationScreen({
    Key? key,
    required this.onClear,
  }) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<String> _unreadNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> waterList = prefs.getStringList('water_notification_unreadNotifications') ?? [];
    List<String> calendarList = prefs.getStringList('calender_notification_unreadNotifications') ?? [];

    List<String> combinedList = [...waterList, ...calendarList];

    final seen = <String>{};
    final uniqueNotifications = <String>[];

    for (var item in combinedList) {
      try {
        final parsed = jsonDecode(item);
        final uniqueKey = jsonEncode(parsed); // Prevent duplicates
        if (!seen.contains(uniqueKey)) {
          seen.add(uniqueKey);
          uniqueNotifications.add(item);
        }
      } catch (e) {
        print("❌ Invalid JSON in notification: $item");
      }
    }

    setState(() {
      _unreadNotifications = uniqueNotifications;
    });

    print("🔔 Loaded ${_unreadNotifications.length} notifications");
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('water_notification_unreadNotifications', []);
    await prefs.setStringList('calender_notification_unreadNotifications', []);

    setState(() {
      _unreadNotifications.clear();
    });

    widget.onClear(); // Notify Dashboard or parent
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepPurple[100],
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearNotifications,
              tooltip: "Clear All",
            ),
        ],
      ),
      body: _unreadNotifications.isEmpty
          ? const Center(
        child: Text(
          "No new notifications!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _unreadNotifications.length,
        itemBuilder: (context, index) {
          final parts = jsonDecode(_unreadNotifications[index]);
          final message = parts["reminder"];
          final time = parts["time"];
          final date = parts["date"];
          final source = parts["source"] ?? "Unknown";

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.bell,
                  size: 20,
                  color: Colors.black,
                ),
                title: Text(message),
                subtitle: Text("$time  $date\n📌 Source: $source"),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    setState(() {
                      _unreadNotifications.removeAt(index);
                    });
                    // Save updated list to both keys (not ideal but safe fallback)
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList(
                        'water_notification_unreadNotifications', _unreadNotifications);
                    await prefs.setStringList(
                        'calender_notification_unreadNotifications', _unreadNotifications);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
