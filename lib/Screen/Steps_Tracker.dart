import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({Key? key}) : super(key: key);

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  static const platform = MethodChannel("com.example.stepcounter/steps");

  int? _steps;
  int _baseSteps = 0;
  int _dailyGoal = 10000;
  String _status = "Unknown";
  bool _isLoading = true;

  bool _stepsInitialized = false;
  bool _isReady = false;

  Timer? _timer;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _initializeCounter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeCounter() async {
    await _startStepService();
    await Future.delayed(const Duration(seconds: 2)); // allow native init
    await _loadSavedData();
    await _getSteps(); // now safe to get steps
    _listenToForegroundStream();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _stepsInitialized = true;
        _isReady = true;
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _getSteps());
  }

  Future<void> _startStepService() async {
    try {
      await platform.invokeMethod("startService");
    } catch (e) {
      debugPrint("Failed to start service: $e");
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyGoal = prefs.getInt('dailyGoal') ?? 10000;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('stepDate');
    final savedBase = prefs.getInt('baseSteps') ?? -1;

    if (savedDate == today && savedBase != -1) {
      _baseSteps = savedBase;
    } else {
      final currentSteps = await platform.invokeMethod("getStepCount") ?? 0;
      _baseSteps = currentSteps;
      await prefs.setInt('baseSteps', _baseSteps);
      await prefs.setString('stepDate', today);
    }
    // Now fetch the current steps and set _steps
    final sensorSteps = await platform.invokeMethod("getStepCount") ?? 0;
    _steps = (sensorSteps - _baseSteps).clamp(0, 9999999);
    if (mounted) setState(() {});
  }

  Future<void> _getSteps() async {
    if (!_stepsInitialized || _baseSteps == 0) return;
    try {
      final int sensorSteps = await platform.invokeMethod("getStepCount") ?? 0;
      if (!mounted) return;
      final int calculatedSteps = (sensorSteps - _baseSteps).clamp(0, 9999999);
      setState(() {
        _steps = calculatedSteps;
      });
    } catch (e) {
      debugPrint("Failed to get steps: $e");
    }
  }

  void _listenToForegroundStream() {
    _stepSub = Pedometer.stepCountStream.listen((StepCount event) {
      if (!mounted || !_stepsInitialized || _baseSteps == 0) return;
      final int calculatedSteps = (event.steps - _baseSteps).clamp(0, 9999999);
      setState(() {
        _steps = calculatedSteps;
      });
    });
    _statusSub = Pedometer.pedestrianStatusStream.listen((status) {
      if (!mounted) return;
      setState(() {
        _status = status.status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_steps != null) ? (_steps! / _dailyGoal).clamp(0.0, 1.0) : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Step Counter"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading || !_stepsInitialized || !_isReady || _steps == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
            Text("Pedestrian Status: $_status",
                style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Text("Goal: $_dailyGoal steps",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}