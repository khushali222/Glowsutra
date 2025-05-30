import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Authentication/LoginScreen/login.dart';
import 'Water_intakescreen.dart';
import 'home.dart';
import 'onborading_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _fetchAndSaveDeviceId();
    // Initializing the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Duration for the animation
      vsync: this,
    );

    // Fade-in animation for the "Your skin care companion" text
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Scale animation for the "Your skin care companion" text
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation
    _controller.forward();
    resetIfNeeded();
    _checkAndDisableOldReminders();
    resetStepTracker();
    _navigate();
  }

  // Future<void> _initPermissions() async {
  //   print(" caling permission of notification nd both ");
  //   // Request Physical Activity permission (Android 10+)
  //   final activityStatus = await Permission.activityRecognition.status;
  //   if (!activityStatus.isGranted) {
  //     final result = await Permission.activityRecognition.request();
  //     if (!result.isGranted) {
  //       Fluttertoast.showToast(
  //         msg: "Activity Recognition permission denied. Step tracking will not work.",
  //       );
  //     }
  //   }
  //
  //   // Request Notification permission (Android 13+)
  //   if (Platform.isAndroid) {
  //     final notificationStatus = await Permission.notification.status;
  //     if (!notificationStatus.isGranted) {
  //       final result = await Permission.notification.request();
  //       if (!result.isGranted) {
  //         Fluttertoast.showToast(
  //           msg: "Notification permission denied. Reminders may not show.",
  //         );
  //       }
  //     }
  //   }
  // }

  Future<void> _initPermissions() async {
    print(
      "Calling permissions for activity, notification, and battery optimization",
    );

    // 1. Request Physical Activity permission (Android 10+)
    final activityStatus = await Permission.activityRecognition.status;
    if (!activityStatus.isGranted) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        Fluttertoast.showToast(
          msg:
              "Activity Recognition permission denied. Step tracking may not work.",
        );
      }
    }

    // 2. Request Notification permission (Android 13+)
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          Fluttertoast.showToast(
            msg: "Notification permission denied. Reminders may not show.",
          );
        }
      }
    }

    //bettry permission
    if (Platform.isAndroid) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        if (!result.isGranted) {
          _showBatteryDialog();
          print("deny calling");
          Fluttertoast.showToast(
            msg:
                "Battery optimization permission denied. Background tracking may not work reliably.",
          );
        }
      }
    }
  }

  void _showBatteryDialog() {
    if (!mounted || context == null) {
      Fluttertoast.showToast(
        msg: "Open settings manually to disable battery optimization.",
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Battery Optimization'),
          content: Text(
            'Please disable battery optimization for this app to ensure background features work properly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final intent = AndroidIntent(
                  action:
                      'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
                  data: 'package:com.glowsutra',
                );
                await intent.launch();
                Navigator.of(context).pop();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> resetIfNeeded() async {
    print("Calling reset");
    final prefs = await SharedPreferences.getInstance();
    var lastUpdatedString = prefs.getString('last_updated');
    final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
    // Try to fetch document from Firestore
    print(lastUpdatedString);
    print(deviceId);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // Handle the case where the user is not logged in
      print("No user is logged in.");
      return;
    }
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection("User")
            .doc("fireid")
            .collection("waterGlasess")
            .doc(userId)
            .get();

    if (snapshot.exists &&
        snapshot.data() != null &&
        snapshot.data()!['lastUpdated'] != null) {
      final data = snapshot.data()!;
      final Timestamp timestamp = data["lastUpdated"];

      // Convert to DateTime
      DateTime dateTime = timestamp.toDate();

      // Print or use the DateTime
      print(dateTime);
      lastUpdatedString = dateTime.toIso8601String();

      final now = DateTime.now();
      bool shouldReset = false;

      if (lastUpdatedString != null) {
        final lastUpdated = DateTime.tryParse(lastUpdatedString);

        if (lastUpdated != null) {
          final lastUpdatedDate = DateTime(
            lastUpdated.year,
            lastUpdated.month,
            lastUpdated.day,
          );
          final currentDate = DateTime(now.year, now.month, now.day);

          if (lastUpdatedDate != currentDate) {
            shouldReset = true;
          }
        } else {
          shouldReset = true;
        }
      } else {
        shouldReset = true;
      }

      if (shouldReset) {
        await prefs.setInt('water_glasses', 0);
        await prefs.setString('last_updated', now.toIso8601String());
        print("Resetting water glasses count because a new day has started.");
        final deviceId = prefs.getString('device_id') ?? "unknown_device_id";
        print("Device ID splash: $deviceId");
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          // Handle the case where the user is not logged in
          print("No user is logged in.");
          return;
        }
        try {
          await FirebaseFirestore.instance
              .collection("User")
              .doc("fireid") // Replace with actual user doc if needed
              .collection("waterGlasess")
              .doc(userId)
              .update({'glasscount': 0, 'lastUpdated': Timestamp.now()});
          print("Firebase glasscount reset to 0.");
          // await _resetStepTracker(prefs, userId);
        } catch (e) {
          print("Failed to update Firebase: $e");
        }
      } else {
        print("No reset needed (still within the same day).");
      }
    } else {
      print(
        "Firestore document or 'lastUpdated' is missing, skipping reset logic.",
      );
      return; // exit early if no data
    }
  }

  Future<void> resetStepTracker() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      print("No user is logged in.");
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection("User")
        .doc("fireid")
        .collection("stepCounter")
        .doc(userId);

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
      Timestamp? lastUpdatedTimestamp = snapshot.data()?['lastUpdated'];

      final now = DateTime.now();
      bool shouldReset = false;

      if (lastUpdatedTimestamp != null) {
        final lastUpdated = lastUpdatedTimestamp.toDate();

        final lastUpdatedDate = DateTime(lastUpdated.year, lastUpdated.month, lastUpdated.day);
        final currentDate = DateTime(now.year, now.month, now.day);

        if (lastUpdatedDate != currentDate) {
          shouldReset = true;
        }
      } else {
        // No lastUpdated found, reset just to be safe
        shouldReset = true;
      }

      if (shouldReset) {
        await prefs.setInt('step_count', 0);
        print("Step count reset locally.");

        await docRef.set({
          'steps': 0,
          'lastUpdated': Timestamp.fromDate(now),
        }, SetOptions(merge: true));
        print("Step count reset in Firebase because it's a new day.");
      } else {
        print("Step count reset skipped, still the same day.");
      }
    } catch (e) {
      print("Error resetting step tracker: $e");
    }
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

  Future<void> _checkAndDisableOldReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection("User")
            .doc("fireid")
            .collection("waterGlasess")
            .doc(userId)
            .get();

    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    bool notificationsEnabledFirestore = data['notificationsEnabled'] ?? false;
    Timestamp? enabledAtTimestamp = data['notificationsEnabledAt'];
    List<String> waterList =
        prefs.getStringList('saved_notification_ids') ?? [];

    if (notificationsEnabledFirestore && enabledAtTimestamp != null) {
      DateTime enabledAt = enabledAtTimestamp.toDate();
      DateTime now = DateTime.now();

      bool sameDay =
          enabledAt.year == now.year &&
          enabledAt.month == now.month &&
          enabledAt.day == now.day;

      if (!sameDay) {
        // It's a new day - disable everything

        // Cancel all scheduled notifications
        if (waterList.isNotEmpty) {
          for (String id in waterList) {
            await flutterLocalNotificationsPlugin.cancel(int.tryParse(id) ?? 0);
          }
          await prefs.remove('saved_notification_ids');
        }

        // Reset flags in SharedPreferences
        await prefs.setBool('notifications_enabled', false);
        await prefs.setBool('alreadyScheduled', false);

        // Update Firestore
        await FirebaseFirestore.instance
            .collection("User")
            .doc("fireid")
            .collection("waterGlasess")
            .doc(userId)
            .set({
              "notificationsEnabled": false,
              "notificationsEnabledAt": Timestamp.fromDate(now),
            }, SetOptions(merge: true));

        // Update UI state
        if (mounted) {
          setState(() {
            notificationsEnabledFirestore = false;
          });

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text("Daily reminders expired, please enable again."),
          //   ),
          // );
        }
      }
    }

    // _loadNotificationPreferences();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    await Future.delayed(
      Duration(seconds: 3),
    ); // Show splash screen for 3 seconds

    if (!onboardingComplete) {
      // Navigate to onboarding if not completed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    } else {
      if (user != null) {
        // Navigate to Home Screen if user is authenticated
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Navigate to Login Screen if user is not authenticated
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller when no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Static "GlowSutra" logo text
              Text(
                'GlowSutra',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins', // Elegant font style
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.deepPurple.withOpacity(0.7),
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 15.0,
                      color: Colors.deepPurple.withOpacity(0.6),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Animated "Your skin care companion" tagline text
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedOpacity(
                      opacity: _opacityAnimation.value,
                      duration: const Duration(seconds: 3),
                      child: Text(
                        'Your skin care companion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.7),
                          fontFamily: 'Poppins', // Elegant font style
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
