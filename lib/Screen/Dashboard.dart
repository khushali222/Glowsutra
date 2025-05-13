import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widgets/custom_appbar.dart';
import 'Authentication/LoginScreen/login.dart';
import 'Calander.dart';
import 'Home_Remedies.dart';
import 'Profile.dart';
import 'Skincaretips.dart';
import 'Water_intakescreen.dart';

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
    _loadReminders();
    _loadWaterIntake();
    _loadUnreadNotifications();
    _fetchAndSaveDeviceId();
  }

  Future<void> _fetchAndSaveDeviceId() async {
    final deviceId = await getDeviceId(); // Get device ID
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'device_id',
      deviceId,
    ); // Save device ID in SharedPreferences
    print("Device ID saved in SharedPreferences: $deviceId");
  }

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_device_id";
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? "unknown_device_id";
    }
    return "unknown_device_id";
  }

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
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationsJson =
        prefs.getStringList('unreadNotifications') ?? [];

    List<String> updatedNotifications = [];
    List<int> idsToCancel = [];

    for (var jsonString in notificationsJson) {
      final decoded = jsonDecode(jsonString);
      if (decoded['reminder'] == reminder &&
          decoded['date'] == DateFormat('yyyy-MM-dd').format(date)) {
        idsToCancel.add(int.tryParse(decoded['id'] ?? '') ?? 0);
      } else {
        updatedNotifications.add(jsonString);
      }
    }

    // Cancel the notifications associated with this reminder
    for (var id in idsToCancel) {
      await _notificationsPlugin.cancel(id);
    }

    // Update the unread notifications list in SharedPreferences
    await prefs.setStringList('unreadNotifications', updatedNotifications);

    setState(() {
      _reminders[date]?.remove(reminder);
      if (_reminders[date]?.isEmpty ?? true) _reminders.remove(date);
    });

    // Save updated reminders in SharedPreferences
    await prefs.setString(
      'reminders',
      jsonEncode(
        _reminders.map((key, value) => MapEntry(key.toIso8601String(), value)),
      ),
    );

    // Now reload the reminders to reflect the updated data
    await _loadReminders();
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
  // Future<void> _loadWaterIntake() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     totalGlasses = prefs.getInt('water_glasses') ?? 0;
  //   });
  // }
  Future<void> _loadWaterIntake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
    //print("dashid $deviceId");
    try {
      // Fetch current glass count from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection("User")
              .doc("fireid")
              .collection("waterGlasess")
              .doc(deviceId)
              .get();

      int currentGlasses = 0;
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!['glasscount'] != null) {
        currentGlasses = snapshot.data()!['glasscount'] as int;
      }
      setState(() {
        totalGlasses = currentGlasses;
        // print(totalGlasses);
      });

      // Update in Firestore
    } catch (e) {
      print("Error updating water glasses: $e");
    }
  }

  double getPercentage() {
    return (totalGlasses / targetGlasses) * 100;
  }

  bool _isLoading = true;
  final StreamController<void> _notificationStream =
      StreamController<void>.broadcast();
  Future<void> _loadUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    // Load both water and calendar notifications from SharedPreferences
    final waterNotifications =
        prefs.getStringList('water_notification_unreadNotifications') ?? [];
    final calendarNotifications =
        prefs.getStringList('calender_notification_unreadNotifications') ?? [];

    // Combine both lists if needed (optional step depending on your needs)
    final allNotifications = [...waterNotifications, ...calendarNotifications];

    if (allNotifications.isEmpty) {
      setState(() {
        _unreadNotifications = [];
      });
      return;
    }

    final seen = <String>{};
    final uniqueNotifications = <String>[];

    // Loop through all notifications and keep only unique ones
    for (var item in allNotifications) {
      final parsed = jsonDecode(item);
      final uniqueKey = jsonEncode(parsed); // Compare entire notification
      if (!seen.contains(uniqueKey)) {
        seen.add(uniqueKey);
        uniqueNotifications.add(item);
      }
    }

    // Save unique notifications back to SharedPreferences
    await prefs.setStringList('unreadNotifications', uniqueNotifications);

    // Update the state
    setState(() {
      _unreadNotifications = uniqueNotifications;
    });

    // print("Filtered notifications: $_unreadNotifications");
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logout Function
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'Logged out successfully');
      // Navigate to login screen after logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to log out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<DateTime, String>> todaysReminders = _getTodaysReminders();
    return StreamBuilder<void>(
      stream: _notificationStream.stream,
      builder: (context, snapshot) {
        _loadWaterIntake();
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Dashboard',
            actions: [
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
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
                          // Carousel
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 180,
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
                          SizedBox(height: 10),
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
                          SizedBox(height: 15),

                          // Hydration Card
                          Padding(
                            padding: const EdgeInsets.only(left: 6, right: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple.shade50,
                                    Colors.deepPurple.shade100,
                                    Colors.deepPurple.shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pie Chart Section
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Hydration",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            height: 125,
                                            width: 125,
                                            child: PieChart(
                                              PieChartData(
                                                sectionsSpace: 0,
                                                centerSpaceRadius: 40,
                                                startDegreeOffset: -90,
                                                sections: [
                                                  PieChartSectionData(
                                                    value: getPercentage(),
                                                    color:
                                                        Colors
                                                            .deepPurple
                                                            .shade200,
                                                    radius: 20,
                                                    showTitle: false,
                                                  ),
                                                  PieChartSectionData(
                                                    value:
                                                        100 - getPercentage(),
                                                    color: Colors.blue.shade200,
                                                    radius: 16,
                                                    showTitle: false,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "${getPercentage().toInt()}%",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              Text(
                                                getPercentage() >= 75
                                                    ? "Hydrated"
                                                    : "Need Water",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _buildLegendColor(
                                            Colors.deepPurple.shade200,
                                            "Consumed",
                                          ),
                                          SizedBox(width: 8),
                                          _buildLegendColor(
                                            Colors.blue.shade200,
                                            "Remaining",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  SizedBox(width: 16),

                                  // Poster Section
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/images/waterdrink.jpg',
                                        fit: BoxFit.cover,
                                        height: 180,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Today's Reminder Header
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 6,
                              right: 6,
                              bottom: 8,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Today's Reminders",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reminder Cards
                          if (todaysReminders.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6, right: 6),
                              child: Column(
                                children:
                                    todaysReminders.map((entry) {
                                      DateTime reminderDate = entry.key;
                                      String reminderText = entry.value;
                                      return Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.white,
                                              // Colors.deepPurple.shade100,
                                              // Colors.deepPurple.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple.shade100
                                                  .withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: Offset(2, 4),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.deepPurple.shade200,
                                            child: FaIcon(
                                              FontAwesomeIcons.solidBell,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            reminderText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: FaIcon(
                                              FontAwesomeIcons.trashCan,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await _removeReminder(
                                                reminderDate,
                                                reminderText,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Text(
                                "No reminders for today!",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),

                          SizedBox(height: 8),
                          // Feature Cards Grid
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3 / 2,
                              children: [
                                _dashboardCard(
                                  title: "Water Intake",
                                  subtitle: "Hydration schedule",
                                  icon: Icons.water_drop,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => WaterIntakeScreen(),
                                      ),
                                    );
                                    print("calling dash 1");
                                    _loadWaterIntake();
                                    setState(() {});
                                  },
                                ),
                                _dashboardCard(
                                  title: "Skincare Tips",
                                  subtitle: "Personalized advice",
                                  icon: Icons.face_retouching_natural,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Skincaretips(),
                                      ),
                                    );
                                  },
                                ),
                                _dashboardCard(
                                  title: "Home Remedies",
                                  subtitle: "Natural skincare",
                                  icon: Icons.spa,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => homeRemedies(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.shade100.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Colors.deepPurple),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendColor(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  void dispose() {
    _notificationStream.close(); // Close the stream to prevent memory leaks
    super.dispose();
  }
}
