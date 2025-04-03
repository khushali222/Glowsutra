import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Analyze.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _resultAcne = "";
  String _resultType = "";
  String _resultTone = "";
  String _resultWrinkle = "";
  String _precautions = "";
  String _imagePath = "";
  File? _image;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _resultAcne = prefs.getString('acneStatus') ?? "";
      _resultType = prefs.getString('skinType') ?? "";
      _resultTone = prefs.getString('skinTone') ?? "";
      _resultWrinkle = prefs.getString('wrinkles') ?? "";
      _precautions = prefs.getString('precautions') ?? "";
      _imagePath = prefs.getString('imagePath') ?? "";

      if (_imagePath.isNotEmpty) {
        _image = File(_imagePath);
      }
      setState(() {
        _isLoading = false;
      });
      print("Acne Status: ${prefs.getString('acneStatus')}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Skincare Profile"),
        backgroundColor: Colors.deepPurple[100],
      ),

      body:
          _isLoading
              ? Center(child: SpinKitCircle(color: Colors.black))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    if (_resultAcne.isEmpty ||
                        _resultType.isEmpty ||
                        _resultTone.isEmpty ||
                        _resultWrinkle.isEmpty ||
                        _precautions.isEmpty)
                      Text("to set up an profile analyed your skin"),

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor:
                              Colors.grey[300], // Optional: Background color
                          backgroundImage:
                              _image != null
                                  ? FileImage(_image!)
                                  : null, // Use FileImage
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProfileDetail(
                            Icons.face,
                            "Acne Status",
                            _resultAcne,
                          ),
                          Divider(),
                          _buildProfileDetail(
                            Icons.water_drop,
                            "Skin Type",
                            _resultType,
                          ),
                          Divider(),
                          _buildProfileDetail(
                            Icons.palette,
                            "Skin Tone",
                            _resultTone,
                          ),
                          Divider(),
                          _buildProfileDetail(
                            Icons.blur_on,
                            "Wrinkle Condition",
                            _resultWrinkle,
                          ),
                          Divider(),
                          SizedBox(height: 20),
                          if (_resultAcne.isNotEmpty ||
                              _resultType.isNotEmpty ||
                              _resultTone.isNotEmpty ||
                              _resultWrinkle.isNotEmpty ||
                              _precautions.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              // crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => SkinAnalyzerScreen(),
                                      ),
                                    );
                                    _loadSavedData();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    height: 45,
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        "Edit Details",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // SizedBox(width: 10),
                                // ElevatedButton.icon(
                                //   onPressed:
                                //       _isLoading ? null : () => _pickImage(ImageSource.gallery),
                                //   icon: Icon(Icons.image),
                                //   label: Text("Gallery"),
                                // ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileDetail(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ), // Add padding for spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
        children: [
          Icon(icon, color: Colors.deepPurple.shade300, size: 30),
          const SizedBox(width: 15),
          Expanded(
            // Makes sure text doesn't overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade300,
                  ),
                  overflow: TextOverflow.visible, // Allows wrapping
                  softWrap: true, // Ensures text wraps properly
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
