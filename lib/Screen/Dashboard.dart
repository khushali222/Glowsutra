import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Calander.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<DateTime, List<String>> _reminders = {};

  @override
  void initState() {
    super.initState();
    _loadReminders(); // Load reminders when dashboard starts
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
      drawer: Drawer(),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[100],

        title: Text("Dashboard"),
        actions: [
          Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.person)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                "Welcome to Glow Sutra!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Analyze your skin and get personalized recommendations.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      "Today's Reminders",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              if (todaysReminders.isNotEmpty)
                Column(
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
                                _removeReminder(reminderDate, reminderText);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                )
              else
                Text(
                  "No reminders for today!",
                  style: TextStyle(color: Colors.grey),
                ),
              SizedBox(height: 20),
              // 🔹 Reminder Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Colors.deepPurple),
                  title: Text("Upcoming Reminder"),
                  subtitle: Text("Water Intake - Today at 2:30 PM"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to Calendar/Schedule Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarScreen()),
                    );
                  },
                ),
              ),
              SizedBox(height: 15),

              // 🔹 Skincare Schedule Navigation
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.calendar_month, color: Colors.deepPurple),
                  title: Text("Go to Skincare Schedule"),
                  subtitle: Text("Set reminders for your skincare routine"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to Calendar Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CalendarScreen()),
                    );
                  },
                ),
              ),
              SizedBox(height: 15),

              // 🔹 Skincare Tips & Recommendations
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.spa, color: Colors.deepPurple),
                  title: Text("Skincare Tips"),
                  subtitle: Text("Get personalized skincare tips"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Navigate to Skincare Tips Page (if available)
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
