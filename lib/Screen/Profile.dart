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
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'dart:io'; // For File image
//
// class Profile extends StatefulWidget {
//   const Profile({super.key});
//
//   @override
//   State<Profile> createState() => _ProfileState();
// }
//
// class _ProfileState extends State<Profile> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late User _user;
//   late String name, email, mobile, profilePhotoUrl;
//   bool _isLoading = true;
//   File? _profileImage;
//
//   @override
//   void initState() {
//     super.initState();
//     _user = _auth.currentUser!; // Get the current logged-in user
//     _loadUserDetails();
//   }
//
//   // Fetch user details from Firestore
//   Future<void> _loadUserDetails() async {
//     try {
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('User')
//           .doc(_user.uid)
//           .get();
//
//       if (userDoc.exists) {
//         setState(() {
//           name = userDoc['name'];
//           email = userDoc['email'];
//           mobile = userDoc['mobile'];
//           profilePhotoUrl = userDoc['profile_photo'];
//
//           // Load the profile image if a URL exists
//           if (profilePhotoUrl.isNotEmpty) {
//             _profileImage = File(profilePhotoUrl);
//           }
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching user details: $e");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text("User Profile"),
//         backgroundColor: Colors.deepPurple[100],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Column(
//           children: [
//             SizedBox(height: 10),
//
//             // Profile Picture
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 10),
//                 child: CircleAvatar(
//                   radius: 100,
//                   backgroundColor: Colors.grey[300], // Optional background color
//                   backgroundImage: _profileImage != null
//                       ? FileImage(_profileImage!)
//                       : (profilePhotoUrl.isNotEmpty
//                       ? NetworkImage(profilePhotoUrl)
//                       : null), // Show image from Firebase if available
//                   child: _profileImage == null && profilePhotoUrl.isEmpty
//                       ? Icon(Icons.person, size: 50, color: Colors.grey)
//                       : null,
//                 ),
//               ),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   _buildProfileDetail(Icons.person, "Name", name),
//                   Divider(),
//                   _buildProfileDetail(Icons.email, "Email", email),
//                   Divider(),
//                   _buildProfileDetail(Icons.phone, "Mobile Number", mobile),
//                   Divider(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfileDetail(IconData icon, String title, String value) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: 8,
//         horizontal: 16,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.deepPurple.shade300, size: 30),
//           const SizedBox(width: 15),
//           Expanded(
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
//                   overflow: TextOverflow.visible,
//                   softWrap: true,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'Authentication/LoginScreen/login.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  bool _isLoading = true;
  bool _isEditing = false;

  late String name, email, mobile, age, weight, profilePhotoUrl;
  final _formKey = GlobalKey<FormState>();
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('User')
              .doc(_user.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc['name'];
          email = userDoc['email'];
          mobile = userDoc['mobile'];
          age = userDoc['age'];
          weight = userDoc['weight'];
          profilePhotoUrl = userDoc['profile_photo'] ?? '';
        });
      }
    } catch (e) {
      print("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  Future<File?> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
      minWidth: 800,
      minHeight: 800,
    );

    if (result != null) {
      final compressedFile = File(result.path);
      print("Compressed size: ${await compressedFile.length() / 1024} KB");
      return compressedFile;
    }

    return null;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final originalFile = File(picked.path);
      final compressed = await compressImage(originalFile);

      if (compressed != null) {
        setState(() => _newImage = compressed);
      } else {
        // fallback if compression fails
        setState(() => _newImage = originalFile);
      }
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = 'doinw37vn';
    const uploadPreset = 'glowsutra_image_preset';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);
      return result['secure_url'];
    } else {
      Fluttertoast.showToast(msg: 'Image upload failed');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    String newPhotoUrl = profilePhotoUrl;

    if (_newImage != null) {
      final uploadedUrl = await _uploadToCloudinary(_newImage!);
      if (uploadedUrl != null) newPhotoUrl = uploadedUrl;
    }

    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(_user.uid)
          .update({
            'name': name,
            'mobile': mobile,
            'age': age ?? "",
            'weight': weight ?? "",
            'profile_photo': newPhotoUrl,
          });

      Fluttertoast.showToast(msg: 'Profile updated successfully');
      setState(() {
        _isEditing = false;
        profilePhotoUrl = newPhotoUrl;
        _newImage = null;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[100],
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: SpinKitCircle(color: Colors.black))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.deepPurple.shade100,
                          backgroundImage:
                              _newImage != null
                                  ? FileImage(_newImage!)
                                  : (profilePhotoUrl.isNotEmpty
                                          ? NetworkImage(profilePhotoUrl)
                                          : null)
                                      as ImageProvider?,
                          child:
                              (_newImage == null && profilePhotoUrl.isEmpty)
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Card UI
                      _profileCard(
                        icon: Icons.person,
                        label: "Name",
                        value: name,
                        onSaved: (val) => name = val,
                        editable: _isEditing,
                      ),
                      _profileCard(
                        icon: Icons.email,
                        label: "Email",
                        value: email,
                        editable: false,
                      ),
                      _profileCard(
                        icon: Icons.phone,
                        label: "Mobile",
                        value: mobile,
                        onSaved: (val) => mobile = val,
                        editable: _isEditing,
                      ),
                      _profileCard(
                        icon: Icons.cake,
                        label: "Age",
                        value: age,
                        onSaved: (val) => age = val,
                        editable: _isEditing,
                      ),
                      _profileCard(
                        icon: Icons.monitor_weight_rounded,
                        label: "Weight",
                        value: weight,
                        onSaved: (val) => weight = val,
                        editable: _isEditing,
                      ),
                      const SizedBox(height: 5),
                      // Logout
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          tileColor: Colors.deepPurple.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(Icons.logout, color: Colors.deepPurple),
                          title: const Text(
                            "Log out",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: _logout,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _profileCard({
    required IconData icon,
    required String label,
    required String value,
    bool editable = true,
    Function(String)? onSaved,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                _isEditing && editable && onSaved != null
                    ? TextFormField(
                      initialValue: value,
                      onSaved: (val) => onSaved(val ?? ''),
                      validator:
                          (val) =>
                              val == null || val.isEmpty ? "Required" : null,
                      decoration: InputDecoration(
                        labelText: label,
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple.shade300,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple.shade400,
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Fluttertoast.showToast(msg: 'Logged out successfully');
      // Navigate to login screen after logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to log out: $e');
    }
  }
}
