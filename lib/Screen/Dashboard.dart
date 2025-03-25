import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,

        title: Text("Dashboard"),
        actions: [Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.person),
        )],
      ),
      body: SingleChildScrollView(child: Column()),
    );
  }
}
