import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glow_sutra/Screen/Calander.dart';
import 'package:glow_sutra/Screen/Dashboard.dart';
import 'package:glow_sutra/Screen/Profile.dart';
import 'package:glow_sutra/Screen/Analyze.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // Track selected screen index

  // List of screens to navigate to
  final List<Widget> _screens = [
    Dashboard(), // Main Skin Analysis Screen
    SkinAnalyzerScreen(), // Main Skin Analysis Screen
    Calander(), // Main Skin Analysis Screen
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.black,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              label: "Scan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: "Note",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
        body: _screens[_currentIndex],
      ),
    );
  }
}
