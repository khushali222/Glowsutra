import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../Dashboard.dart';
import '../../home.dart'; // Import home screen

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

  // Function to validate email format
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Function to validate mobile number (you can add region-specific rules here)
  bool _isValidMobile(String mobile) {
    return RegExp(
      r'^[0-9]{10}$',
    ).hasMatch(mobile); // Assuming 10-digit mobile number
  }

  // Function to validate the form before signing up
  void _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        // Create a new user using Firebase Authentication
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        // Store additional user information in Firestore
        await FirebaseFirestore.instance
            .collection('User')
            .doc(userCredential.user?.uid)
            .set({
              'name': _nameController.text,
              'email': _emailController.text,
              'mobile': _mobileController.text,
              'password': _passwordController.text,
              'profile_photo':
                  '', // Optional: you can allow users to upload a photo
            });
        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(msg: 'Signup successful!');
        // Navigate to Dashboard if successful
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => HomePage()),
        // );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (Route<dynamic> route) =>
              false, // Removes all previous routes from the stack
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color deepPurpleShade100 = Color(0xFFD1C4E9);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: deepPurpleShade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name cannot be empty';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 2.0,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email cannot be empty';
                  } else if (!_isValidEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  fillColor: Colors.white,
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons
                              .visibility_off // Show "visibility_off" when password is visible
                          : Icons
                              .visibility, // Show "visibility" when password is hidden
                      color: Colors.deepPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible =
                            !_isPasswordVisible; // Toggle the visibility state
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 2.0,
                    ),
                  ),
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password cannot be empty';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Mobile Number
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: deepPurpleShade100,
                      width: 2.0,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    10,
                  ), // Limit input to 10 digits
                ],
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !_isValidMobile(value)) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Sign Up Button
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _signup,
                    child: Text('Sign Up'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io'; // For File
//
// import '../../Dashboard.dart'; // Import home screen
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
//
//   File? _image; // The picked image file
//   String? _imageUrl; // To store the uploaded image URL
//
//   // Function to validate email format
//   bool _isValidEmail(String email) {
//     return RegExp(
//       r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$',
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
//   // Function to pick an image from the gallery
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path); // Store the picked image
//       });
//     }
//   }
//
//   // Function to upload the image to Firebase Storage and get the URL
//   Future<String?> _uploadImage(File image) async {
//     try {
//       // Get a reference to Firebase Storage
//       final storageRef = FirebaseStorage.instance.ref().child(
//         'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
//       );
//
//       // Upload the image file
//       await storageRef.putFile(image);
//
//       // Get the download URL of the uploaded image
//       final downloadUrl = await storageRef.getDownloadURL();
//       return downloadUrl; // Return the image URL
//     } catch (e) {
//       print("Error uploading image: $e");
//       return null;
//     }
//   }
//
//   // Function to validate the form before signing up
//   void _signup() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       if (_image == null) {
//         // Show an error if no image is selected
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Please pick a profile image')),
//         );
//         return; // Exit the function if no image is selected
//       }
//
//       try {
//         // Create a new user using Firebase Authentication
//         UserCredential userCredential = await _auth
//             .createUserWithEmailAndPassword(
//           email: _emailController.text,
//           password: _passwordController.text,
//         );
//
//         String? imageUrl;
//         if (_image != null) {
//           // If an image is selected, upload it and get the URL
//           imageUrl = await _uploadImage(_image!);
//         }
//
//         // Store additional user information in Firestore
//         await FirebaseFirestore.instance
//             .collection('User')
//             .doc(userCredential.user?.uid)
//             .set({
//           'name': _nameController.text,
//           'email': _emailController.text,
//           'mobile': _mobileController.text,
//           'profile_photo': imageUrl ?? '', // Store the image URL or empty string
//         });
//
//         // Navigate to Dashboard if successful
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => Dashboard()),
//         );
//       } on FirebaseAuthException catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.message ?? 'An error occurred!')),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Sign Up')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               // Display selected image in CircleAvatar if an image is selected
//               _image != null
//                   ? CircleAvatar(
//                 radius: 100,
//                 backgroundImage: FileImage(_image!),
//               )
//                   : CircleAvatar(
//                 radius: 100,
//                 child: Icon(Icons.camera_alt, size: 40),
//               ),
//               SizedBox(height: 16),
//
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
//                     borderSide: BorderSide(color: Colors.grey, width: 1.0),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: Colors.blue, width: 2.0),
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
//                     borderSide: BorderSide(color: Colors.grey, width: 1.0),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: Colors.blue, width: 2.0),
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
//                 obscureText: true,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   prefixIcon: Icon(Icons.lock),
//                   fillColor: Colors.white,
//                   filled: true,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: Colors.grey, width: 1.0),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: Colors.blue, width: 2.0),
//                   ),
//                 ),
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
//                     borderSide: BorderSide(color: Colors.grey, width: 1.0),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: BorderSide(color: Colors.blue, width: 2.0),
//                   ),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 inputFormatters: [LengthLimitingTextInputFormatter(10)],
//                 validator: (value) {
//                   if (value != null &&
//                       value.isNotEmpty &&
//                       !_isValidMobile(value)) {
//                     return 'Please enter a valid mobile number';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//
//               // Image Picker Button
//               ElevatedButton(
//                 onPressed: _pickImage,
//                 child: Text('Pick Profile Image'),
//               ),
//               SizedBox(height: 24),
//
//               // Sign Up Button
//               ElevatedButton(
//                 onPressed: _signup,
//                 child: Text('Sign Up'),
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                   ),
//                   textStyle: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
