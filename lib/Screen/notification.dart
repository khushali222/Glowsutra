import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final List<String> notifications;
  final VoidCallback onClear;

  NotificationScreen({required this.notifications, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              onClear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body:
      notifications.isEmpty
          ? Center(child: Text("No unread notifications"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notifications[index]),
            onTap: () {
              onClear();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}