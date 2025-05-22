// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// import '../../Dashboard.dart';
// import '../../home.dart'; // Import home screen
//
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }
//
// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _nameController = TextEditingController();
//   final _mobileController = TextEditingController();
//
//   final _auth = FirebaseAuth.instance;
//   bool _isLoading = false;
//   bool _isPasswordVisible = false;
//
//   // Function to validate email format
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//     ).hasMatch(email);
//   }
//
//   // Function to validate mobile number (you can add region-specific rules here)
//   bool _isValidMobile(String mobile) {
//     return RegExp(
//       r'^[0-9]{10}$',
//     ).hasMatch(mobile); // Assuming 10-digit mobile number
//   }
//
//   // Function to validate the form before signing up
//   void _signup() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isLoading = true;
//       });
//       try {
//         // Create a new user using Firebase Authentication
//         UserCredential userCredential = await _auth
//             .createUserWithEmailAndPassword(
//               email: _emailController.text,
//               password: _passwordController.text,
//             );
//
//         // Store additional user information in Firestore
//         await FirebaseFirestore.instance
//             .collection('User')
//             .doc(userCredential.user?.uid)
//             .set({
//               'name': _nameController.text,
//               'email': _emailController.text,
//               'mobile': _mobileController.text,
//               'password': _passwordController.text,
//               'profile_photo':
//                   '', // Optional: you can allow users to upload a photo
//             });
//         setState(() {
//           _isLoading = false;
//         });
//
//         Fluttertoast.showToast(msg: 'Signup successful!');
//         // Navigate to Dashboard if successful
//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(builder: (context) => HomePage()),
//         // );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => HomePage()),
//           (Route<dynamic> route) =>
//               false, // Removes all previous routes from the stack
//         );
//       } on FirebaseAuthException catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.message ?? 'An error occurred!')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Color deepPurpleShade100 = Color(0xFFD1C4E9);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sign Up'),
//         backgroundColor: deepPurpleShade100,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               // Full Name
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Full Name',
//                   prefixIcon: Icon(Icons.person),
//                   fillColor: Colors.white,
//                   filled: true,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 1.0,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 2.0,
//                     ),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Name cannot be empty';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Email
//               TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   prefixIcon: Icon(Icons.email),
//                   fillColor: Colors.white,
//                   filled: true,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 1.0,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 2.0,
//                     ),
//                   ),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Email cannot be empty';
//                   } else if (!_isValidEmail(value)) {
//                     return 'Please enter a valid email';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Password
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: !_isPasswordVisible,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: Icon(Icons.lock),
//                   fillColor: Colors.white,
//                   filled: true,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _isPasswordVisible
//                           ? Icons
//                               .visibility_off // Show "visibility_off" when password is visible
//                           : Icons
//                               .visibility, // Show "visibility" when password is hidden
//                       color: Colors.deepPurple,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _isPasswordVisible =
//                             !_isPasswordVisible; // Toggle the visibility state
//                       });
//                     },
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 1.0,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 2.0,
//                     ),
//                   ),
//                 ),
//
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Password cannot be empty';
//                   } else if (value.length < 6) {
//                     return 'Password must be at least 6 characters long';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Mobile Number
//               TextFormField(
//                 controller: _mobileController,
//                 decoration: InputDecoration(
//                   labelText: 'Mobile Number',
//                   prefixIcon: Icon(Icons.phone),
//                   fillColor: Colors.white,
//                   filled: true,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 1.0,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(
//                       color: deepPurpleShade100,
//                       width: 2.0,
//                     ),
//                   ),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 inputFormatters: [
//                   LengthLimitingTextInputFormatter(
//                     10,
//                   ), // Limit input to 10 digits
//                 ],
//                 validator: (value) {
//                   value = value?.trim(); // Remove whitespace
//                   if (value == null || value.isEmpty) {
//                     return 'Mobile number cannot be empty';
//                   } else if (!_isValidMobile(value)) {
//                     return 'Please enter a valid 10-digit mobile number';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 24),
//
//               // Sign Up Button
//               _isLoading
//                   ? Center(child: CircularProgressIndicator())
//                   : ElevatedButton(
//                     onPressed: _signup,
//                     child: Text('Sign Up'),
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                       textStyle: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../../home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  File? _selectedImage;

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
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      File originalFile = File(pickedFile.path);
      File? compressed = await compressImage(originalFile);
      setState(() {
        _selectedImage = compressed ?? originalFile;
      });
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

  void _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImage == null) {
        Fluttertoast.showToast(msg: 'Please select a profile image');
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Check if mobile number already exists in Firestore
        QuerySnapshot mobileQuery =
            await FirebaseFirestore.instance
                .collection('User')
                .where('mobile', isEqualTo: _mobileController.text.trim())
                .get();

        if (mobileQuery.docs.isNotEmpty) {
          Fluttertoast.showToast(msg: 'Mobile number already in use');
          setState(() => _isLoading = false);
          return;
        }

        // Attempt Firebase Authentication signup (checks email)
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // Only upload image after email and mobile are valid
        String? imageUrl = await _uploadToCloudinary(_selectedImage!);
        if (imageUrl == null) {
          Fluttertoast.showToast(msg: 'Image upload failed');
          setState(() => _isLoading = false);
          return;
        }

        // Store user data in Firestore
        await FirebaseFirestore.instance
            .collection('User')
            .doc(userCredential.user?.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'mobile': _mobileController.text.trim(),
              'profile_photo': imageUrl,
            });

        Fluttertoast.showToast(msg: 'Signup successful!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: '${e.message ?? "Unknown error"}');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Something went wrong: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey),
    );

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      border: borderStyle,
      enabledBorder: borderStyle,
      focusedBorder: borderStyle,
      errorBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedErrorBorder: borderStyle.copyWith(
        borderSide: BorderSide(color: Colors.grey),
      ),

      // Optional: prevent layout shift due to error text
      errorStyle: TextStyle(height: 0), // Hides error message but keeps spacing
    );
  }

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  @override
  Widget build(BuildContext context) {
    Color deepPurpleShade100 = Color(0xFFD1C4E9);
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: deepPurpleShade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : null,
                    child:
                        _selectedImage == null
                            ? Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey.shade700,
                            )
                            : null,
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Name
              Container(
                child: TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Full Name', Icons.person),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Name required'
                              : null,
                ),
              ),
              SizedBox(height: 16),
              // Email
              Container(
                child: TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email', Icons.email),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email required';
                    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    return pattern.hasMatch(value) ? null : 'Invalid email';
                  },
                ),
              ),
              SizedBox(height: 16),
              // Password
              Container(
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _inputDecoration('Password', Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        );
                      },
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                ),
              ),
              SizedBox(height: 16),
              // Mobile
              Container(
                child: TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Mobile Number', Icons.phone),
                  inputFormatters: [LengthLimitingTextInputFormatter(10)],
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Mobile required';
                    return RegExp(r'^[0-9]{10}$').hasMatch(value)
                        ? null
                        : 'Enter valid 10-digit number';
                  },
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? SpinKitCircle(color: Colors.black)
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepPurpleShade100,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
