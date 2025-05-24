import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class StepCounterPage extends StatefulWidget {
  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> with RouteAware {
  final Health _health = Health();
  int _steps = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetch();
    _timer = Timer.periodic(Duration(seconds: 10), (_) => fetchSteps());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    fetchSteps();
  }

  Future<void> _requestPermissionsAndFetch() async {
    // Activity recognition
    if (await Permission.activityRecognition.isPermanentlyDenied) {
      _showSettingsDialog("Activity Recognition permission permanently denied. Please enable it in settings.");
      return;
    }

    if (await Permission.activityRecognition.isDenied) {
      final result = await Permission.activityRecognition.request();
      if (!result.isGranted) {
        _showSnackbar("Activity Recognition permission is required.");
        return;
      }
    }

    // Health Connect (Android 13+)
    if (Theme.of(context).platform == TargetPlatform.android) {
      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        await _health.installHealthConnect();
        _showSnackbar('Please install Google Health Connect app to proceed.');
        return;
      }
    }

    // Health permission
    final granted = await hasPermissions();
    if (!granted) {
      _showSnackbar("Permission to access health data was denied.");
      return;
    }

    fetchSteps();
  }

  Future<bool> hasPermissions() async {
    try {
      bool? granted = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );

      if (granted == true) return true;

      // Request if not already granted
      return await requestAuthorization();
    } catch (e) {
      print("hasPermissions error: $e");
      return false;
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        await Permission.activityRecognition.request();
        await Permission.location.request();
      }

      return await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
    } catch (e) {
      print("requestAuthorization error: $e");
      return false;
    }
  }

  Future<void> fetchSteps() async {
    final types = [HealthDataType.STEPS];
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: midnight,
        endTime: now,
      );

      final cleanData = _health.removeDuplicates(healthData);
      int totalSteps = 0;
      for (var point in cleanData) {
        if (point.type == HealthDataType.STEPS) {
          totalSteps += (point.value as int);
        }
      }

      setState(() {
        _steps = totalSteps;
      });

      print('Fetched steps: $totalSteps');
    } catch (e) {
      _showSnackbar("Error fetching step data: $e");
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Step Tracker")),
      body: Center(
        child: Text(
          "Steps today: $_steps",
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

