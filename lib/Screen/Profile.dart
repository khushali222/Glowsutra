// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import 'Analyze.dart';
//
// class Profile extends StatefulWidget {
//   const Profile({super.key});
//
//   @override
//   State<Profile> createState() => _ProfileState();
// }
//
// class _ProfileState extends State<Profile> {
//   String _resultAcne = "";
//   String _resultType = "";
//   String _resultTone = "";
//   String _resultWrinkle = "";
//   String _precautions = "";
//   String _imagePath = "";
//   File? _image;
//   bool _isLoading = true;
//   @override
//   void initState() {
//     super.initState();
//     _loadSavedData();
//   }
//
//   Future<void> _loadSavedData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _resultAcne = prefs.getString('acneStatus') ?? "";
//       _resultType = prefs.getString('skinType') ?? "";
//       _resultTone = prefs.getString('skinTone') ?? "";
//       _resultWrinkle = prefs.getString('wrinkles') ?? "";
//       _precautions = prefs.getString('precautions') ?? "";
//       _imagePath = prefs.getString('imagePath') ?? "";
//
//       if (_imagePath.isNotEmpty) {
//         _image = File(_imagePath);
//       }
//       setState(() {
//         _isLoading = false;
//       });
//       print("Acne Status: ${prefs.getString('acneStatus')}");
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text("Skincare Profile"),
//         backgroundColor: Colors.deepPurple[100],
//       ),
//       body:
//           _isLoading
//               ? Center(child: SpinKitCircle(color: Colors.black))
//               : SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     SizedBox(height: 10),
//                     if (_resultAcne.isEmpty ||
//                         _resultType.isEmpty ||
//                         _resultTone.isEmpty ||
//                         _resultWrinkle.isEmpty ||
//                         _precautions.isEmpty)
//                       Text("to set up an profile analyed your skin"),
//
//                     Center(
//                       child: Padding(
//                         padding: const EdgeInsets.only(top: 10),
//                         child: CircleAvatar(
//                           radius: 100,
//                           backgroundColor:
//                               Colors.grey[300], // Optional: Background color
//                           backgroundImage:
//                               _image != null
//                                   ? FileImage(_image!)
//                                   : null, // Use FileImage
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         children: [
//                           _buildProfileDetail(
//                             Icons.face,
//                             "Acne Status",
//                             _resultAcne,
//                           ),
//                           Divider(),
//                           _buildProfileDetail(
//                             Icons.water_drop,
//                             "Skin Type",
//                             _resultType,
//                           ),
//                           Divider(),
//                           _buildProfileDetail(
//                             Icons.palette,
//                             "Skin Tone",
//                             _resultTone,
//                           ),
//                           Divider(),
//                           _buildProfileDetail(
//                             Icons.blur_on,
//                             "Wrinkle Condition",
//                             _resultWrinkle,
//                           ),
//                           Divider(),
//                           SizedBox(height: 20),
//                           if (_resultAcne.isNotEmpty ||
//                               _resultType.isNotEmpty ||
//                               _resultTone.isNotEmpty ||
//                               _resultWrinkle.isNotEmpty ||
//                               _precautions.isNotEmpty)
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               // crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 GestureDetector(
//                                   onTap: () async {
//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) => SkinAnalyzerScreen(),
//                                       ),
//                                     );
//                                     _loadSavedData();
//                                   },
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.deepPurple.shade100,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     height: 45,
//                                     width: 120,
//                                     child: Center(
//                                       child: Text(
//                                         "Edit Details",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           if (_resultAcne.isEmpty ||
//                               _resultType.isEmpty ||
//                               _resultTone.isEmpty ||
//                               _resultWrinkle.isEmpty ||
//                               _precautions.isEmpty)
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               // crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 GestureDetector(
//                                   onTap: () async {
//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) => SkinAnalyzerScreen(),
//                                       ),
//                                     );
//                                     _loadSavedData();
//                                   },
//                                   child: Container(
//                                     decoration: BoxDecoration(
//                                       color: Colors.deepPurple.shade100,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     height: 45,
//                                     width: 120,
//                                     child: Center(
//                                       child: Text(
//                                         "Analyze Skin",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 80),
//                   ],
//                 ),
//               ),
//     );
//   }
//
//   Widget _buildProfileDetail(IconData icon, String title, String value) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: 8,
//         horizontal: 16,
//       ), // Add padding for spacing
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start, // Align items at the top
//         children: [
//           Icon(icon, color: Colors.deepPurple.shade300, size: 30),
//           const SizedBox(width: 15),
//           Expanded(
//             // Makes sure text doesn't overflow
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepPurple.shade300,
//                   ),
//                   overflow: TextOverflow.visible, // Allows wrapping
//                   softWrap: true, // Ensures text wraps properly
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // For File image

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  late String name, email, mobile, profilePhotoUrl;
  bool _isLoading = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!; // Get the current logged-in user
    _loadUserDetails();
  }

  // Fetch user details from Firestore
  Future<void> _loadUserDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(_user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc['name'];
          email = userDoc['email'];
          mobile = userDoc['mobile'];
          profilePhotoUrl = userDoc['profile_photo'];

          // Load the profile image if a URL exists
          if (profilePhotoUrl.isNotEmpty) {
            _profileImage = File(profilePhotoUrl);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("User Profile"),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),

            // Profile Picture
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey[300], // Optional background color
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null), // Show image from Firebase if available
                  child: _profileImage == null && profilePhotoUrl.isEmpty
                      ? Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileDetail(Icons.person, "Name", name),
                  Divider(),
                  _buildProfileDetail(Icons.email, "Email", email),
                  Divider(),
                  _buildProfileDetail(Icons.phone, "Mobile Number", mobile),
                  Divider(),
                ],
              ),
            ),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple.shade300, size: 30),
          const SizedBox(width: 15),
          Expanded(
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
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
