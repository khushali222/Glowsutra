import 'package:flutter/material.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  bool _isPasswordVisible = false;

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email or mobile number.');
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password.');
    }
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    String? emailToUse;
    bool userExists = false;

    try {
      // Mobile login
      if (RegExp(r'^[0-9]{10}$').hasMatch(email)) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('User')
                .where('mobile', isEqualTo: email)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _emailError = 'Mobile number not registered.';
            Fluttertoast.showToast(msg: 'Mobile number not registered.');
            _isLoading = false;
          });
          return;
        }

        emailToUse = snapshot.docs.first['email'];
        userExists = true;
      } else {
        // Email login
        if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
          setState(() {
            _emailError = 'Please enter a valid email address.';
            _isLoading = false;
          });
          return;
        }

        final snapshot =
            await FirebaseFirestore.instance
                .collection('User')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _emailError = 'Email not registered.';
            Fluttertoast.showToast(msg: 'Email not registered.');
            _isLoading = false;
          });
          return;
        }

        emailToUse = email;
        userExists = true;
      }

      // Firebase Auth login
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
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      String errorMessage = 'Login failed.';

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          setState(() => _emailError = errorMessage);
          break;

        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;

        case 'user-not-found':
          errorMessage = 'No account found for this email.';
          setState(() => _emailError = errorMessage);
          break;

        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          setState(() => _passwordError = errorMessage);
          break;

        case 'invalid-credential':
          if (userExists) {
            errorMessage = 'Incorrect password.';
            setState(() => _passwordError = errorMessage);
          } else {
            errorMessage = 'Invalid login credentials.';
          }
          break;

        default:
          errorMessage = e.message ?? 'Unexpected error occurred.';
      }

      Fluttertoast.showToast(msg: errorMessage);
    } catch (e) {
      print('Other error: $e');
      Fluttertoast.showToast(msg: 'Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              Text(
                'Login to Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 30),

              // EMAIL OR MOBILE FIELD
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email or Mobile',
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  errorText: _emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple.shade400),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),

              // PASSWORD FIELD
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.deepPurple),
                  errorText: _passwordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.deepPurple.shade400),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // LOGIN BUTTON
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
              SizedBox(height: 16),

              // FORGOT PASSWORD
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgetPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // SIGN UP LINK
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: _navigateToSignup,
                  child: Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(color: Colors.deepPurple),
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
