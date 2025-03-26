import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
    CalendarScreen(), // Main Skin Analysis Screen
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Ensures smooth effect with curved navbar
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent, // To blend smoothly
        color: Colors.deepPurple.shade100,
        buttonBackgroundColor: Colors.white,
        animationDuration: Duration(milliseconds: 300),
        index: _currentIndex,
        height: 60,
        items: [
          Icon(Icons.home, size: 30, color: Colors.black),
          Icon(Icons.qr_code_scanner_outlined, size: 30, color: Colors.black),
          Icon(Icons.calendar_month, size: 30, color: Colors.black),
          Icon(Icons.person, size: 30, color: Colors.black),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
    //   SafeArea(
    //   child: Scaffold(
    //     bottomNavigationBar: BottomNavigationBar(
    //       selectedItemColor: Colors.blueAccent,
    //       unselectedItemColor: Colors.black,
    //       currentIndex: _currentIndex,
    //       onTap: (index) {
    //         setState(() {
    //           _currentIndex = index;
    //         });
    //       },
    //       items: [
    //         BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    //         BottomNavigationBarItem(
    //           icon: Icon(Icons.qr_code_scanner_outlined),
    //           label: "Scan",
    //         ),
    //         BottomNavigationBarItem(
    //           icon: Icon(Icons.calendar_month),
    //           label: "Note",
    //         ),
    //         BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
    //       ],
    //     ),
    //     body: _screens[_currentIndex],
    //   ),
    // );
  }
}
