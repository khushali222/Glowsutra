import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Skincaretips extends StatefulWidget {
  @override
  _SkincaretipsState createState() => _SkincaretipsState();
}

class _SkincaretipsState extends State<Skincaretips> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Skincare Tips"),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
              top: 10,
              bottom: 10,
            ),
            child: Container(
              // height: 200,
              // width: 400,
              child: Image(image: NetworkImage("https://img.freepik.com/free-photo/medium-shot-woman-practicing-selfcare_23-2150396201.jpg?ga=GA1.1.92241902.1743491671&semt=ais_hybrid&w=740")),
            ),
          ),
          Column(
            children: [
              Text(
                "Oily skin?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                "Use a lightweight, oil-free moisturizer and blot excess oil.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 20),
            ],
          ),
          Column(
            children: [
              Text(
                "Dry skin?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                "Hydrate with a rich moisturizer and drink plenty of water to keep your skin nourished",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 50),
            ],
          ),

        ],
      ),
    );
  }
}
