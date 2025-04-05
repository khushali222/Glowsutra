import 'dart:async';
import 'dart:convert';

import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'Calander.dart';
import 'Profile.dart';
import 'Skincaretips.dart';
import 'Water_intakescreen.dart';
import 'notification.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<DateTime, List<String>> _reminders = {};
  List<String> _unreadNotifications = [];
  FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders(); // Load reminders when dashboard starts
    _loadWaterIntake();
  }

  // Future<void> _loadReminders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? savedReminders = prefs.getString('reminders');
  //
  //   if (savedReminders != null) {
  //     Map<String, dynamic> decodedReminders = jsonDecode(savedReminders);
  //     setState(() {
  //       _reminders = decodedReminders.map((key, value) {
  //         return MapEntry(DateTime.parse(key), List<String>.from(value));
  //       });
  //     });
  //   }
  //   _unreadNotifications = prefs.getStringList('unreadNotifications') ?? [];
  //   setState(() {
  //     _isLoading = false;
  //   });
  // }
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedReminders = prefs.getString('reminders');

    if (savedReminders != null) {
      Map<String, dynamic> decodedReminders = jsonDecode(savedReminders);
      setState(() {
        _reminders = decodedReminders.map((key, value) {
          return MapEntry(DateTime.parse(key), List<String>.from(value));
        });
      });
    }

    final dynamic rawData = prefs.get('unreadNotifications');
    if (rawData is List<String>) {
      _unreadNotifications = rawData;
    } else {
      _unreadNotifications = [];
    }
    _unreadNotifications = prefs.getStringList('unreadNotifications') ?? [];
    setState(() {
      _isLoading = false;
    });
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

  Future<void> _markNotificationAsRead(String? notification) async {
    if (notification != null) {
      setState(() {
        _unreadNotifications.remove(notification);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'unreadNotifications',
        _unreadNotifications,
      ); // Save updated list to storage
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
        _notificationStream.add(null);
      },
    );
  }

  int activeIndex = 0;
  final List<String> imageUrls = [
    'https://images.pexels.com/photos/31361995/pexels-photo-31361995/free-photo-of-artistic-makeup-with-floral-accents-in-park-setting.jpeg?auto=compress&cs=tinysrgb&w=600',
    'https://img.freepik.com/free-photo/medium-shot-woman-practicing-selfcare_23-2150229552.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740',
    'https://img.freepik.com/free-photo/medium-shot-woman-practicing-selfcare_23-2150396201.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740',
  ];

  int totalGlasses = 0;
  final int targetGlasses = 8;
  Future<void> _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      totalGlasses = prefs.getInt('water_glasses') ?? 0;
    });
  }

  double getPercentage() {
    return (totalGlasses / targetGlasses) * 100;
  }

  bool _isLoading = true;
  final StreamController<void> _notificationStream =
      StreamController<void>.broadcast();
  @override
  Widget build(BuildContext context) {
    List<MapEntry<DateTime, String>> todaysReminders = _getTodaysReminders();
    return StreamBuilder<void>(
      stream: _notificationStream.stream,
      builder: (context, snapshot) {
        _loadReminders(); // Reload reminders whenever a new notification is received
        return Scaffold(
          drawer: Drawer(),
          appBar: AppBar(
            backgroundColor: Colors.deepPurple[100],
            title: Text("Dashboard"),
            actions: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => NotificationScreen(
                            notifications: _unreadNotifications,
                            onClear: () async {
                              setState(() {
                                _unreadNotifications.clear();
                              });

                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setStringList(
                                'unreadNotifications',
                                [],
                              );
                            },
                          ),
                    ),
                  );
                  _loadReminders(); // Reload notifications after returning
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.bell,
                        size: 20,
                        color: Colors.black,
                      ),
                      // Icon(Icons.notifications, size: 28), // Notification Icon
                      if (_unreadNotifications.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Profile()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.person, size: 25, color: Colors.black),
                ),
              ),
            ],
          ),
          body:
              _isLoading
                  ? Center(child: SpinKitCircle(color: Colors.black))
                  : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Text(
                            "Welcome to Glow Sutra!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Analyze your skin and get personalized recommendations.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 20),
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 200,
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 3),
                              enlargeCenterPage: true,
                              enableInfiniteScroll: true,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  activeIndex = index;
                                });
                              },
                            ),
                            items:
                                imageUrls.map((url) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: 1000,
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSmoothIndicator(
                            activeIndex: activeIndex,
                            count: imageUrls.length,
                            effect: ExpandingDotsEffect(
                              dotHeight: 8,
                              dotWidth: 8,
                              activeDotColor: Colors.pink,
                              dotColor: Colors.grey.shade300,
                            ),
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  "Water Intake Progress",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 150,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: getPercentage(),
                                    title: "${getPercentage().toInt()}%",
                                    color: Colors.deepPurple.shade100,
                                    radius: 30,
                                    titleStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: 100 - getPercentage(),
                                    color: Colors.grey[300],
                                    radius: 25,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WaterIntakeScreen(),
                                ),
                              );
                              _loadWaterIntake(); // Refresh data after returning
                            },
                            child: Text("Go to Water Tracker"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  "Today's Reminders",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                            _removeReminder(
                                              reminderDate,
                                              reminderText,
                                            );
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
                          // 🔹 Skincare Schedule Navigation
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_month,
                                color: Colors.deepPurple,
                              ),
                              title: Text("Go to Skincare Schedule"),
                              subtitle: Text(
                                "Set reminders for your skincare routine",
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                // Navigate to Calendar Screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CalendarScreen(),
                                  ),
                                );
                                _loadReminders(); // Reload notifications after returning
                                setState(() {});
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
                              leading: FaIcon(
                                FontAwesomeIcons.bottleWater,
                                size: 20,
                                color: Colors.deepPurple,
                              ),
                              title: Text("Water Intake"),
                              subtitle: Text("Get Water Intake Schedule"),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CalendarScreen(),
                                  ),
                                );
                                _loadReminders(); // Reload notifications after returning
                                setState(() {});
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.spa,
                                color: Colors.deepPurple,
                              ),
                              title: Text("Skincare Tips"),
                              subtitle: Text("Get personalized skincare tips"),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Skincaretips(),
                                  ),
                                );
                              },
                            ),
                          ),
                          // ElevatedButton(
                          //   onPressed: () async {
                          //     await Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => WaterIntakeScreen(),
                          //       ),
                          //     );
                          //     _loadWaterIntake(); // Refresh data after returning
                          //   },
                          //   child: Text("Go to Water Tracker"),
                          // ),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationStream.close(); // Close the stream to prevent memory leaks
    super.dispose();
  }
}
