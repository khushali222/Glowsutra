import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Serviece/helper.dart';

class NotificationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onClear;

  const NotificationScreen({
    Key? key,
    required this.notifications,
    required this.onClear,
  }) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ✅ FIXED: initialized with an empty list to avoid LateInitializationError
  List<Map<String, dynamic>> _unreadNotifications = [];//

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    final notifications = await NotificationHelper.getDeliveredNotifications();



    setState(() {
      _unreadNotifications = notifications;
      print("Notification data $notifications");
    });

    final prefs = await SharedPreferences.getInstance();
    var noti_data = await prefs.getString("unreadNotifications");
    print("noti ${noti_data}");
  //  await prefs.setString('unreadNotifications', jsonEncode(notifications));
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unreadNotifications', jsonEncode([]));

    setState(() {
      _unreadNotifications.clear();
    });

    widget.onClear(); // Notify Dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.deepPurple[100],
        // actions: [
        //   if (_unreadNotifications.isNotEmpty)
        //     IconButton(
        //       icon: Icon(Icons.delete_outline, color: Colors.black),
        //       onPressed: _clearNotifications,
        //     ),
        // ],
      ),
      body: _unreadNotifications.isEmpty
          ? Center(
        child: Text(
          "No new notifications!",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _unreadNotifications.length,
        itemBuilder: (context, index) {
          final notif = _unreadNotifications[index];
          final message = notif['message'] ?? '';
          final time = _formatTime(notif['scheduledTime']);
          final date = _formatDate(notif['scheduledTime']);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.bell,
                  size: 20,
                  color: Colors.black,
                ),
                title: Text(message),
                subtitle: Text("$time  $date"),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await NotificationHelper.removeDeliveredNotificationById(
                      notif['id'].toString(),
                    );
                    setState(() {
                      _unreadNotifications.removeAt(index);
                    });

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'unreadNotifications',
                      jsonEncode(_unreadNotifications),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse(timeStr);
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final suffix = time.hour >= 12 ? "PM" : "AM";
      return "$hour:$minute $suffix";
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String timeStr) {
    try {
      final date = DateTime.parse(timeStr);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }
}
