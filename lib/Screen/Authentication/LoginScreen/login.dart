import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../Dashboard.dart';
import '../../home.dart';
import '../ForgotScreen/forgotpassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isPasswordVisible = false; // To toggle the password visibility

  // Function to validate and login the user
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email.';
      });
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password.';
      });
    }

    if (email.isNotEmpty &&
        !RegExp(
          r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
        ).hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
      });
    }

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      Fluttertoast.showToast(msg: 'Login successful');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred!';

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'user-disabled':
          errorMessage = 'This user has been disabled.';
          break;
        case 'user-not-found':
          errorMessage =
              'No user found with this email. Please check the email address or sign up.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please check your password.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password sign-in is not enabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials provided.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage =
              'Account exists with this email using a different sign-in method.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again.';
          break;
        case 'email-change-needs-verify':
          errorMessage = 'Please verify your new email address.';
          break;
        case 'unknown':
          errorMessage = 'An unknown error occurred.';
          break;
        case 'timeout':
          errorMessage = 'The request timed out. Please try again.';
          break;
      }

      Fluttertoast.showToast(msg: errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      backgroundColor: Colors.deepPurple.shade50, // Lighter purple background
      // appBar: AppBar(
      //   title: Text('Login'),
      //   backgroundColor: Colors.deepPurple.shade600, // Deep Purple app bar color
      //   elevation: 0,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // To avoid overflow on small screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
              ),
              // Main Text
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Login to Your Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              // Email TextField
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
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
              // Password TextField with eye icon
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
                          ? Icons.visibility_off // Show "visibility_off" when password is visible
                          : Icons.visibility,    // Show "visibility" when password is hidden
                      color: Colors.deepPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible; // Toggle the visibility state
                      });
                    },
                  ),

                ),
              ),
              SizedBox(height: 16),

              // Login Button with Elevated Design
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
                      elevation: 5, // Shadow effect
                      textStyle: TextStyle(fontSize: 18),
                    ),
                  ),
              SizedBox(height: 16),

              // Forgot Password Link
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

              // Navigate to Signup Screen
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
