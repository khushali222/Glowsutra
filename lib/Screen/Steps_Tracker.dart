// import 'package:flutter/material.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class StepCounterScreen extends StatefulWidget {
//   const StepCounterScreen({Key? key}) : super(key: key);
//
//   @override
//   State<StepCounterScreen> createState() => _StepCounterScreenState();
// }
//
// class _StepCounterScreenState extends State<StepCounterScreen>
//     with SingleTickerProviderStateMixin {
//   late Stream<StepCount> _stepCountStream;
//   late Stream<PedestrianStatus> _pedestrianStatusStream;
//
//   int _steps = 0;
//   int _baseSteps = 0;
//   String _status = '...';
//   int _dailyGoal = 10000;
//   DateTime? _lastResetTime;
//   bool _permissionGranted = false;
//
//   late AnimationController _animationController;
//   late Animation<int> _stepAnimation;
//   int _displayedSteps = 0;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadSavedData();
//     _initAnimation();
//     initPlatformState();
//   }
//
//   void _initAnimation() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _stepAnimation = IntTween(begin: 0, end: 0).animate(_animationController)
//       ..addListener(() {
//         setState(() {
//           _displayedSteps = _stepAnimation.value;
//         });
//       });
//   }
//
//   Future<void> _loadSavedData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final now = DateTime.now();
//
//     _dailyGoal = prefs.getInt('dailyGoal') ?? 10000;
//     _steps = prefs.getInt('steps') ?? 0;
//     _baseSteps = prefs.getInt('baseSteps') ?? 0;
//     _displayedSteps = _steps;
//
//     final resetStr = prefs.getString('lastResetTime');
//     if (resetStr != null) {
//       _lastResetTime = DateTime.tryParse(resetStr);
//       if (_lastResetTime != null &&
//           (_lastResetTime!.day != now.day ||
//               _lastResetTime!.month != now.month ||
//               _lastResetTime!.year != now.year)) {
//         // New day detected: reset steps
//         _steps = 0;
//         _displayedSteps = 0;
//         _baseSteps = 0;
//         _lastResetTime = now;
//         await prefs.setInt('steps', 0);
//         await prefs.setInt('baseSteps', 0);
//         await prefs.setString('lastResetTime', now.toIso8601String());
//       }
//     } else {
//       _lastResetTime = now;
//       await prefs.setString('lastResetTime', now.toIso8601String());
//     }
//
//     setState(() {});
//   }
//
//   Future<void> _saveSteps() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('steps', _steps);
//   }
//
//   Future<void> _saveBaseSteps(int base) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('baseSteps', base);
//   }
//
//   Future<void> _saveDailyGoal(int goal) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('dailyGoal', goal);
//   }
//
//   Future<void> _saveResetTime() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_lastResetTime != null) {
//       await prefs.setString('lastResetTime', _lastResetTime!.toIso8601String());
//     }
//   }
//
//   void onStepCount(StepCount event) {
//     if (!_permissionGranted || !mounted) return;
//
//     final int currentSensorSteps = event.steps;
//
//     if (_baseSteps == 0) {
//       // First reading – set base
//       _baseSteps = currentSensorSteps;
//       _saveBaseSteps(_baseSteps);
//       return;
//     }
//
//     final int calculatedSteps = currentSensorSteps - _baseSteps;
//
//     if (calculatedSteps < 0 || calculatedSteps > 20000) {
//       // Invalid jump or reboot - ignore
//       return;
//     }
//
//     if (calculatedSteps != _steps) {
//       _animateStepCount(_steps, calculatedSteps);
//       _steps = calculatedSteps;
//       _saveSteps();
//       setState(() {});
//     }
//   }
//
//   void _animateStepCount(int oldValue, int newValue) {
//     _stepAnimation = IntTween(begin: oldValue, end: newValue).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//     _animationController.forward(from: 0);
//   }
//
//   void onPedestrianStatusChanged(PedestrianStatus event) {
//     if (!mounted) return;
//     setState(() {
//       _status = event.status;
//     });
//   }
//
//   void onPedestrianStatusError(error) {
//     if (!mounted) return;
//     setState(() {
//       _status = 'Status not available';
//     });
//   }
//
//   void onStepCountError(error) {
//     if (!mounted) return;
//     setState(() {
//       _steps = 0;
//       _displayedSteps = 0;
//     });
//   }
//
//   Future<bool> _checkActivityRecognitionPermission() async {
//     bool granted = await Permission.activityRecognition.isGranted;
//
//     if (!granted) {
//       granted =
//           await Permission.activityRecognition.request() ==
//           PermissionStatus.granted;
//     }
//
//     return granted;
//   }
//
//   Future<void> initPlatformState() async {
//     bool granted = await _checkActivityRecognitionPermission();
//     setState(() {
//       _permissionGranted = granted;
//     });
//     if (!granted) return;
//
//     _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
//     _pedestrianStatusStream
//         .listen(onPedestrianStatusChanged)
//         .onError(onPedestrianStatusError);
//
//     _stepCountStream = Pedometer.stepCountStream;
//     _stepCountStream.listen(onStepCount).onError(onStepCountError);
//   }
//
//   String _getMotivationalQuote() {
//     if (_steps < _dailyGoal * 0.25) {
//       return "Let's get moving!";
//     } else if (_steps < _dailyGoal * 0.5) {
//       return "Good start, keep it up!";
//     } else if (_steps < _dailyGoal * 0.75) {
//       return "Awesome progress!";
//     } else if (_steps < _dailyGoal) {
//       return "Almost there, keep pushing!";
//     } else {
//       return "Goal achieved, great job!";
//     }
//   }
//
//   void _showSetGoalDialog() {
//     final controller = TextEditingController(text: _dailyGoal.toString());
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Set Daily Step Goal'),
//           content: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(hintText: 'Enter your step goal'),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final enteredGoal = int.tryParse(controller.text);
//                 if (enteredGoal != null && enteredGoal > 0) {
//                   setState(() => _dailyGoal = enteredGoal);
//                   _saveDailyGoal(enteredGoal);
//                 }
//                 Navigator.pop(context);
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _resetSteps() {
//     setState(() {
//       _steps = 0;
//       _displayedSteps = 0;
//       _lastResetTime = DateTime.now();
//       _baseSteps = 0;
//     });
//     _saveSteps();
//     _saveResetTime();
//     _saveBaseSteps(0);
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double progress = (_steps / _dailyGoal).clamp(0.0, 1.0);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Smart Pedometer'),
//         actions: [
//           IconButton(
//             tooltip: 'Set Daily Goal',
//             icon: const Icon(Icons.flag),
//             onPressed: _showSetGoalDialog,
//           ),
//           IconButton(
//             tooltip: 'Reset Steps',
//             icon: const Icon(Icons.refresh),
//             onPressed: _resetSteps,
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//         child: ListView(
//           children: [
//             Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 30,
//                   horizontal: 20,
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Steps Taken',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.teal[700],
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 500),
//                       transitionBuilder: (child, animation) {
//                         return ScaleTransition(scale: animation, child: child);
//                       },
//                       child: Text(
//                         '$_displayedSteps',
//                         key: ValueKey<int>(_displayedSteps),
//                         style: TextStyle(
//                           fontSize: 72,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.teal[900],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     LinearProgressIndicator(
//                       value: progress,
//                       minHeight: 15,
//                       backgroundColor: Colors.teal[100],
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Colors.teal.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Daily Goal: $_dailyGoal steps',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.black54,
//                       ),
//                     ),
//                     if (_lastResetTime != null) ...[
//                       const SizedBox(height: 10),
//                       Text(
//                         'Last reset: ${_lastResetTime!.toLocal().toString().split('.').first}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),
//             Card(
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               color: Colors.white,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 20,
//                   horizontal: 15,
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Pedestrian Status',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.teal[700],
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     Icon(
//                       _status == 'walking'
//                           ? Icons.directions_walk
//                           : _status == 'stopped'
//                           ? Icons.accessibility_new
//                           : Icons.error_outline,
//                       size: 80,
//                       color:
//                           _status == 'walking' || _status == 'stopped'
//                               ? Colors.teal
//                               : Colors.redAccent,
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       _status,
//                       style: TextStyle(
//                         fontSize: 22,
//                         color:
//                             _status == 'walking' || _status == 'stopped'
//                                 ? Colors.black87
//                                 : Colors.redAccent,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               color: Colors.teal[50],
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 25,
//                 ),
//                 child: Text(
//                   _getMotivationalQuote(),
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontStyle: FontStyle.italic,
//                     color: Colors.teal[900],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/services.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({Key? key}) : super(key: key);

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  static const platform = MethodChannel("com.example.stepcounter/steps");

  int _steps = 0;
  int _baseSteps = 0;
  int _dailyGoal = 10000;
  String _status = "Unknown";

  @override
  void initState() {
    super.initState();
    _startStepService(); // Start foreground service
    Timer.periodic(const Duration(seconds: 5), (timer) => _getSteps());
    _loadSavedData(); // Load base steps
    _fetchStepsFromNative(); // Initial step count fetch
    _listenToForegroundStream(); // Listen to pedometer
  }

  Future<void> _startStepService() async {
    try {
      await platform.invokeMethod("startService");
    } catch (e) {
      print("Failed to start step service: $e");
    }
  }

  Future<void> _getSteps() async {
    try {
      final int steps = await platform.invokeMethod("getStepCount");
      setState(() => _steps = steps - _baseSteps);
    } catch (e) {
      print("Failed to get steps: $e");
    }
  }

  // Future<void> _initPermissions() async {
  //   var activityStatus = await Permission.activityRecognition.status;
  //   if (!activityStatus.isGranted) {
  //     activityStatus = await Permission.activityRecognition.request();
  //     if (!activityStatus.isGranted) {
  //       Fluttertoast.showToast(msg: "Activity Recognition permission denied.");
  //       return;
  //     }
  //   }
  //
  //   // Notification permission for Android 13+
  //   if (await Permission.notification.isDenied || await Permission.notification.isRestricted) {
  //     var notificationStatus = await Permission.notification.request();
  //     if (!notificationStatus.isGranted) {
  //       Fluttertoast.showToast(msg: "Notification permission denied.");
  //     }
  //   }
  // }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('dailyGoal') ?? 10000;

    final savedDate = prefs.getString('stepDate');
    final savedBase = prefs.getInt('baseSteps') ?? 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate == today) {
      _baseSteps = savedBase;
    } else {
      // Reset base step count
      final currentSteps = await platform.invokeMethod("getStepCount");
      _baseSteps = currentSteps;
      await prefs.setInt('baseSteps', _baseSteps);
      await prefs.setString('stepDate', today);
    }
  }

  Future<void> _fetchStepsFromNative() async {
    try {
      final int result = await platform.invokeMethod("getStepCount");
      setState(() => _steps = result - _baseSteps);
    } on PlatformException catch (_) {
      setState(() => _steps = 0);
    }
  }

  void _listenToForegroundStream() {
    Pedometer.stepCountStream.listen((StepCount event) {
      setState(() {
        _steps = event.steps - _baseSteps;
      });
    });

    Pedometer.pedestrianStatusStream.listen((status) {
      setState(() {
        _status = status.status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps / _dailyGoal).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text(" Smart Step Counter"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Steps: $_steps", style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.teal),
            ),
            const SizedBox(height: 20),
            Text("Pedestrian Status: $_status", style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Text("Goal: $_dailyGoal steps", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

