// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Firestore
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../Dashboard.dart';
// import '../../home.dart';
// import '../ForgotScreen/forgotpassword.dart';
// import '../signupScreen/signup.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _auth = FirebaseAuth.instance;
//
//   bool _isLoading = false;
//   String? _emailError;
//   String? _passwordError;
//   bool _isPasswordVisible = false;
//
//   void _login() async {
//
//     String email = _emailController.text.trim();
//     String password = _passwordController.text.trim();
//
//     setState(() {
//       _emailError = null;
//       _passwordError = null;
//     });
//
//     if (email.isEmpty) {
//       setState(() => _emailError = 'Please enter your email or mobile number.');
//     }
//     if (password.isEmpty) {
//       setState(() => _passwordError = 'Please enter your password.');
//     }
//     if (_emailError != null || _passwordError != null) return;
//
//     setState(() => _isLoading = true);
//
//     String? emailToUse;
//     bool userExists = false;
//
//     try {
//       // Mobile login
//       if (RegExp(r'^[0-9]{10}$').hasMatch(email)) {
//         final snapshot =
//             await FirebaseFirestore.instance
//                 .collection('User')
//                 .where('mobile', isEqualTo: email)
//                 .limit(1)
//                 .get();
//
//         if (snapshot.docs.isEmpty) {
//           setState(() {
//             _emailError = 'Mobile number not registered.';
//             Fluttertoast.showToast(msg: 'Mobile number not registered.');
//             _isLoading = false;
//           });
//           return;
//         }
//
//         emailToUse = snapshot.docs.first['email'];
//         userExists = true;
//       } else {
//         // Email login
//         if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
//           setState(() {
//             _emailError = 'Please enter a valid email address.';
//             _isLoading = false;
//           });
//           return;
//         }
//
//         final snapshot =
//             await FirebaseFirestore.instance
//                 .collection('User')
//                 .where('email', isEqualTo: email)
//                 .limit(1)
//                 .get();
//
//         if (snapshot.docs.isEmpty) {
//           setState(() {
//             _emailError = 'Email not registered.';
//             Fluttertoast.showToast(msg: 'Email not registered.');
//             _isLoading = false;
//           });
//           return;
//         }
//
//         emailToUse = email;
//         userExists = true;
//       }
//
//       // Firebase Auth login
//       await _auth.signInWithEmailAndPassword(
//         email: emailToUse!,
//         password: password,
//       );
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('onboarding_complete', true);
//
//       Fluttertoast.showToast(msg: 'Login successful');
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomePage()),
//       );
//     } on FirebaseAuthException catch (e) {
//       print('FirebaseAuthException: code=${e.code}, message=${e.message}');
//       String errorMessage = 'Login failed.';
//
//       switch (e.code) {
//         case 'invalid-email':
//           errorMessage = 'The email address is badly formatted.';
//           setState(() => _emailError = errorMessage);
//           break;
//
//         case 'user-disabled':
//           errorMessage = 'This user account has been disabled.';
//           break;
//
//         case 'user-not-found':
//           errorMessage = 'No account found for this email.';
//           setState(() => _emailError = errorMessage);
//           break;
//
//         case 'wrong-password':
//           errorMessage = 'Incorrect password.';
//           setState(() => _passwordError = errorMessage);
//           break;
//
//         case 'invalid-credential':
//           if (userExists) {
//             errorMessage = 'Incorrect password.';
//             setState(() => _passwordError = errorMessage);
//           } else {
//             errorMessage = 'Invalid login credentials.';
//           }
//           break;
//
//         default:
//           errorMessage = e.message ?? 'Unexpected error occurred.';
//       }
//
//       Fluttertoast.showToast(msg: errorMessage);
//     } catch (e) {
//       print('Other error: $e');
//       Fluttertoast.showToast(msg: 'Something went wrong. Please try again.');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _navigateToSignup() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => SignupScreen()),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.deepPurple.shade50,
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SizedBox(height: 100),
//               Text(
//                 'Login to Your Account',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.deepPurple,
//                 ),
//               ),
//               SizedBox(height: 30),
//
//               // EMAIL OR MOBILE FIELD
//               TextField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email or Mobile',
//                   labelStyle: TextStyle(color: Colors.deepPurple),
//                   errorText: _emailError,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.deepPurple.shade200),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.deepPurple.shade400),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 18,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // PASSWORD FIELD
//               TextField(
//                 controller: _passwordController,
//                 obscureText: !_isPasswordVisible,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   labelStyle: TextStyle(color: Colors.deepPurple),
//                   errorText: _passwordError,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.deepPurple.shade200),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15),
//                     borderSide: BorderSide(color: Colors.deepPurple.shade400),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 18,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _isPasswordVisible
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: Colors.deepPurple,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _isPasswordVisible = !_isPasswordVisible;
//                       });
//                     },
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // LOGIN BUTTON
//               _isLoading
//                   ? Center(child: SpinKitCircle(size: 40, color: Colors.black))
//                   : ElevatedButton(
//                     onPressed: _login,
//                     child: Text('Login'),
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 5,
//                       textStyle: TextStyle(fontSize: 18),
//                     ),
//                   ),
//               SizedBox(height: 16),
//
//               // FORGOT PASSWORD
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ForgetPasswordScreen(),
//                     ),
//                   );
//                 },
//                 child: Text(
//                   'Forgot your password?',
//                   style: TextStyle(
//                     color: Colors.deepPurple,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//
//               // SIGN UP LINK
//               Padding(
//                 padding: const EdgeInsets.only(top: 16),
//                 child: TextButton(
//                   onPressed: _navigateToSignup,
//                   child: Text(
//                     'Don\'t have an account? Sign up',
//                     style: TextStyle(color: Colors.deepPurple),
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
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Firestore
import 'package:shared_preferences/shared_preferences.dart';

import '../../Dashboard.dart';
import '../../home.dart';
import '../ForgotScreen/forgotpassword.dart';
import '../signupScreen/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  String? _emailError; // for backend validation
  String? _passwordError; // for backend validation
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  void _login() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    String input = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String? emailToUse;
    bool userExists = false;

    try {
      // Check if mobile
      if (RegExp(r'^[0-9]{10}$').hasMatch(input)) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('User')
                .where('mobile', isEqualTo: input)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _emailError = 'Mobile number not registered.';
            Fluttertoast.showToast(msg: _emailError!);
            _isLoading = false;
          });
          return;
        }

        emailToUse = snapshot.docs.first['email'];
        userExists = true;
      } else {
        // Assume email
        final snapshot =
            await FirebaseFirestore.instance
                .collection('User')
                .where('email', isEqualTo: input)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _emailError = 'Email not registered.';
            Fluttertoast.showToast(msg: _emailError!);
            _isLoading = false;
          });
          return;
        }

        emailToUse = input;
        userExists = true;
      }

      await _auth.signInWithEmailAndPassword(
        email: emailToUse!,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      Fluttertoast.showToast(msg: 'Login successful');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed.';

      switch (e.code) {
        case 'invalid-email':
          _emailError = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          _emailError = 'No account found for this email.';
          break;
        case 'wrong-password':
          _passwordError = 'Incorrect password.';
          break;
        case 'invalid-credential':
          if (userExists) {
            _passwordError = 'Incorrect password.';
          } else {
            errorMessage = 'Invalid login credentials.';
          }
          break;
        default:
          errorMessage = e.message ?? 'Unexpected error occurred.';
      }

      setState(() {}); // Trigger UI update for errorText
      Fluttertoast.showToast(
        msg: _emailError ?? _passwordError ?? errorMessage,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                const Text(
                  'Login to Your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    SizedBox(width: 5,),
                    Text("Email or Mobile",style: TextStyle(fontWeight: FontWeight.bold,color:Colors.black ),),
                  ],
                ),
                SizedBox(
                  height: 4,
                ),
                // Email or Mobile
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  InputDecoration(
                    hintText: 'Email or Mobile', // or 'Password'
                    errorText: _emailError, // or _passwordError
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey), // <- NO RED
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey), // <- NO RED ON FOCUS
                    ),

                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email or mobile number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(width: 5,),
                    Text("Password",style: TextStyle(fontWeight: FontWeight.bold,color:Colors.black ),),
                  ],
                ),
                SizedBox(
                  height: 4,
                ),
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration:
                  InputDecoration(
                    hintText: 'Password', // or 'Password'
                    errorText: _passwordError, // or _passwordError
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey), // <- NO RED
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey), // <- NO RED ON FOCUS
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Login Button
                _isLoading
                    ? const SpinKitCircle(color: Colors.deepPurple, size: 40)
                    : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Login'),
                    ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgetPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
                    );
                  },
                  child: const Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
